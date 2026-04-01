from rest_framework.views import APIView
from rest_framework.generics import ListAPIView
from rest_framework.response import Response
from rest_framework import status
from .models import Progress
from .serializers import ProgressSerializer, ProgressCreateSerializer
from curriculum.models import Book


class ProgressAPIView(APIView):
    """
    GET  /api/progress/?academic_id=xxx&book=1   - جلب تقدم طالب في كتاب
    POST /api/progress/                           - حفظ/تحديث تقدم
    """

    def get(self, request):
        academic_id = request.query_params.get('academic_id')
        book_id = request.query_params.get('book')

        if not academic_id or not book_id:
            return Response({'error': 'academic_id and book are required'}, status=400)

        try:
            prog = Progress.objects.get(academic_id=academic_id, book_id=book_id)
            return Response(ProgressSerializer(prog).data)
        except Progress.DoesNotExist:
            return Response({'progress_percent': 0.0, 'last_page': 1}, status=200)

    def post(self, request):
        ser = ProgressCreateSerializer(data=request.data)
        if not ser.is_valid():
            return Response(ser.errors, status=status.HTTP_400_BAD_REQUEST)

        data = ser.validated_data
        academic_id = data['academic_id']
        book_id = data['book']

        try:
            book = Book.objects.get(id=book_id)
        except Book.DoesNotExist:
            return Response({'status': 'ignored', 'reason': 'book not found'}, status=200)

        prog, created = Progress.objects.get_or_create(
            academic_id=academic_id,
            book=book,
            defaults={
                'last_page': data['last_page'],
                'pages_read': data['pages_read'],
                'total_time_minutes': data['total_time_minutes'],
                'interaction_score': data['interaction_score'],
                'progress_percent': data['progress_percent'],
            }
        )

        if not created:
            # تحديث: نأخذ القيمة الأعلى لا نستبدل
            prog.last_page = max(prog.last_page, data['last_page'])
            prog.pages_read = max(prog.pages_read, data['pages_read'])
            prog.total_time_minutes += data['total_time_minutes']
            prog.interaction_score += data['interaction_score']
            prog.progress_percent = max(prog.progress_percent, data['progress_percent'])
            prog.save()

        return Response(ProgressSerializer(prog).data, status=200)


class StudentAllProgressAPIView(ListAPIView):
    """GET /api/progress/student/<academic_id>/ - كل تقدم طالب"""
    serializer_class = ProgressSerializer

    def get_queryset(self):
        academic_id = self.kwargs.get('academic_id')
        return Progress.objects.filter(academic_id=academic_id).select_related('book')

    def list(self, request, *args, **kwargs):
        qs = self.get_queryset()
        results = []
        for p in qs:
            results.append({
                'subject': p.book.subject.name if p.book.subject else '',
                'book_id': str(p.book.id),
                'last_page': p.last_page,
                'total_pages': p.book.total_pages,
                'progress_percent': p.progress_percent,
                'total_time_minutes': p.total_time_minutes,
                'last_activity': p.updated_at.strftime('%Y-%m-%d %H:%M') if p.updated_at else '',
            })
        return Response(results)


class ClassStudentsProgressAPIView(APIView):
    """GET /api/classes/<class_id>/students/ - طلاب الشعبة مع تقدمهم"""

    def get(self, request, class_id):
        from students.models import Student
        students = Student.objects.filter(class_id=class_id)
        results = []
        for student in students:
            # آخر تقدم للطالب
            latest = Progress.objects.filter(
                academic_id=student.academic_id
            ).order_by('-updated_at').first()

            progress_pct = latest.progress_percent if latest else 0.0
            total_time = latest.total_time_minutes if latest else 0

            # تحديد الحالة
            if progress_pct >= 0.6:
                student_status = 'active'
            elif progress_pct >= 0.3:
                student_status = 'medium'
            else:
                student_status = 'needs_attention'

            results.append({
                'id': str(student.id),
                'academic_id': student.academic_id,
                'full_name': student.full_name,
                'progress_percent': round(progress_pct, 2),
                'total_time_minutes': total_time,
                'status': student_status,
                'last_activity': latest.updated_at.strftime('%Y-%m-%d') if latest and latest.updated_at else 'لا يوجد',
            })
        return Response(results)
