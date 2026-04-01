#!/usr/bin/env python
"""إدخال البيانات التجريبية المطابقة لبيانات Flutter"""
import os, sys, django

os.chdir(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.abspath('yemeni_school_backend'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from students.models import Student
from teachers.models import Teacher, TeacherClass
from parents.models import Parent

# ===== طلاب =====
students_data = [
    {'academic_id': '78246', 'full_name': 'أحمد محمد علي',       'grade_level': 'التاسع', 'class_id': 'class_9A', 'class_name': 'التاسع - أ'},
    {'academic_id': '78247', 'full_name': 'سارة علي الأمين',     'grade_level': 'التاسع', 'class_id': 'class_9A', 'class_name': 'التاسع - أ'},
    {'academic_id': '78248', 'full_name': 'محمد حسن الرازي',     'grade_level': 'التاسع', 'class_id': 'class_9A', 'class_name': 'التاسع - أ'},
    {'academic_id': '78249', 'full_name': 'فاطمة عمر الصلاحي',   'grade_level': 'التاسع', 'class_id': 'class_9A', 'class_name': 'التاسع - أ'},
    {'academic_id': '78250', 'full_name': 'خالد إبراهيم اليزيدي','grade_level': 'التاسع', 'class_id': 'class_9A', 'class_name': 'التاسع - أ'},
    {'academic_id': '78260', 'full_name': 'علي عبدالله المحمدي', 'grade_level': 'التاسع', 'class_id': 'class_9B', 'class_name': 'التاسع - ب'},
    {'academic_id': '78261', 'full_name': 'مريم إبراهيم الحكيمي','grade_level': 'التاسع', 'class_id': 'class_9B', 'class_name': 'التاسع - ب'},
    {'academic_id': '78262', 'full_name': 'حسين علي الخولاني',   'grade_level': 'التاسع', 'class_id': 'class_9B', 'class_name': 'التاسع - ب'},
]
for s in students_data:
    Student.objects.get_or_create(academic_id=s['academic_id'], defaults=s)
print(f"✅ Students: {Student.objects.count()}")

# ===== معلم =====
teacher, _ = Teacher.objects.get_or_create(
    teacher_id='78246',
    defaults={'full_name': 'أ. محمد عبدالله', 'subject': 'رياضيات', 'password': '123'}
)
TeacherClass.objects.get_or_create(teacher=teacher, class_id='class_9A', defaults={'class_name': 'التاسع - أ', 'students_count': 5})
TeacherClass.objects.get_or_create(teacher=teacher, class_id='class_9B', defaults={'class_name': 'التاسع - ب', 'students_count': 3})
print(f"✅ Teachers: {Teacher.objects.count()}")

# ===== ولي أمر =====
parent, _ = Parent.objects.get_or_create(
    parent_id='78246',
    defaults={'full_name': 'محمد علي الحسن'}
)
child = Student.objects.get(academic_id='78246')
parent.children.add(child)
print(f"✅ Parents: {Parent.objects.count()}")

print("\n🎉 البيانات التجريبية جاهزة!")
