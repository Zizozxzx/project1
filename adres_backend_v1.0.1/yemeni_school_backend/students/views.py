from rest_framework.generics import ListAPIView
from .models import Student
from .serializers import StudentSerializer


class StudentListAPIView(ListAPIView):
    serializer_class = StudentSerializer

    def get_queryset(self):
        qs = Student.objects.all()
        academic_id = self.request.query_params.get('academic_id')
        if academic_id:
            qs = qs.filter(academic_id=academic_id)
        return qs
