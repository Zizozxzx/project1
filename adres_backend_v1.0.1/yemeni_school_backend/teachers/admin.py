from django.contrib import admin
from .models import Teacher, TeacherClass

class TeacherClassInline(admin.TabularInline):
    model = TeacherClass
    extra = 1

@admin.register(Teacher)
class TeacherAdmin(admin.ModelAdmin):
    list_display = ['teacher_id', 'full_name', 'subject']
    search_fields = ['teacher_id', 'full_name']
    inlines = [TeacherClassInline]
