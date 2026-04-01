from django.db import models


class Teacher(models.Model):
    teacher_id = models.CharField(max_length=20, unique=True, verbose_name="الرقم الوظيفي")
    password = models.CharField(max_length=128, verbose_name="كلمة المرور")
    full_name = models.CharField(max_length=100, verbose_name="الاسم الكامل")
    subject = models.CharField(max_length=100, verbose_name="المادة")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.full_name} ({self.teacher_id})"

    class Meta:
        verbose_name = "معلم"
        verbose_name_plural = "المعلمون"


class TeacherClass(models.Model):
    """ربط المعلم بالشعب الدراسية"""
    teacher = models.ForeignKey(Teacher, on_delete=models.CASCADE, related_name='classes')
    class_id = models.CharField(max_length=50, verbose_name="معرف الشعبة")
    class_name = models.CharField(max_length=100, verbose_name="اسم الشعبة")
    students_count = models.PositiveIntegerField(default=0, verbose_name="عدد الطلاب")

    def __str__(self):
        return f"{self.teacher.full_name} - {self.class_name}"

    class Meta:
        verbose_name = "شعبة المعلم"
        verbose_name_plural = "شعب المعلمين"
        unique_together = ('teacher', 'class_id')
