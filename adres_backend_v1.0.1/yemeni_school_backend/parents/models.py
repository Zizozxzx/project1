from django.db import models
from students.models import Student


class Parent(models.Model):
    parent_id = models.CharField(max_length=20, unique=True, verbose_name="رقم ولي الأمر")
    full_name = models.CharField(max_length=100, verbose_name="الاسم الكامل")
    children = models.ManyToManyField(Student, blank=True, related_name='parents', verbose_name="الأبناء")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.full_name} ({self.parent_id})"

    class Meta:
        verbose_name = "ولي الأمر"
        verbose_name_plural = "أولياء الأمور"
