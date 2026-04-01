from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Teacher
from .serializers import TeacherSerializer


class TeacherLoginAPIView(APIView):
    """POST /api/teachers/login/"""

    def post(self, request):
        teacher_id = request.data.get('teacher_id', '').strip()
        password = request.data.get('password', '').strip()

        if not teacher_id or not password:
            return Response(
                {'error': 'الرجاء إدخال الرقم الوظيفي وكلمة المرور'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            teacher = Teacher.objects.get(teacher_id=teacher_id)
            if not teacher.check_password(password):
                raise Teacher.DoesNotExist
            return Response(TeacherSerializer(teacher).data)
        except Teacher.DoesNotExist:
            return Response(
                {'error': 'بيانات الدخول غير صحيحة'},
                status=status.HTTP_401_UNAUTHORIZED,
            )
