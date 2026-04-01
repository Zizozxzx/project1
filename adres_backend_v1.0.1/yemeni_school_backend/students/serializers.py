from rest_framework import serializers
from .models import Student


class StudentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Student
        fields = ['id', 'academic_id', 'full_name', 'grade_level', 'class_id', 'class_name']
