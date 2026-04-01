from django.contrib import admin
from .models import Student

@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ['academic_id', 'full_name', 'grade_level', 'class_name']
    search_fields = ['academic_id', 'full_name']
