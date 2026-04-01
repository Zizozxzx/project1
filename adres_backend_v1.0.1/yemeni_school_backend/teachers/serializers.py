from rest_framework import serializers
from .models import Teacher, TeacherClass


class TeacherClassSerializer(serializers.ModelSerializer):
    active_rate = serializers.SerializerMethodField()

    class Meta:
        model = TeacherClass
        fields = ['id', 'class_id', 'class_name', 'students_count', 'active_rate']

    def get_active_rate(self, obj):
        # حساب نسبة النشاط من جدول التقدم
        try:
            from progress.models import Progress
            from students.models import Student
            students = Student.objects.filter(class_id=obj.class_id)
            if not students.exists():
                return 0.0
            active = Progress.objects.filter(
                student__class_id=obj.class_id
            ).values('student').distinct().count()
            return round(active / students.count(), 2)
        except Exception:
            return 0.0


class TeacherSerializer(serializers.ModelSerializer):
    classes = TeacherClassSerializer(many=True, read_only=True)

    class Meta:
        model = Teacher
        fields = ['id', 'teacher_id', 'full_name', 'subject', 'classes']
