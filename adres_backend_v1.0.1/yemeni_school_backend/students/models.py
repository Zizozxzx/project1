from django.db import models


class Student(models.Model):
    academic_id = models.CharField(max_length=20, unique=True, verbose_name="الرقم الأكاديمي")
    full_name = models.CharField(max_length=100, verbose_name="الاسم الكامل")
    grade_level = models.CharField(max_length=50, verbose_name="الصف الدراسي")
    class_id = models.CharField(max_length=50, blank=True, verbose_name="معرف الشعبة")
    class_name = models.CharField(max_length=100, blank=True, verbose_name="اسم الشعبة")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.full_name} ({self.academic_id})"

    class Meta:
        verbose_name = "طالب"
        verbose_name_plural = "الطلاب"
