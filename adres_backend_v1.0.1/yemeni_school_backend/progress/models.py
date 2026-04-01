from django.db import models
from students.models import Student
from curriculum.models import Book


class Progress(models.Model):
    """تقدم الطالب في كتاب معين"""
    student = models.ForeignKey(
        Student,
        on_delete=models.CASCADE,
        related_name='progress_records',
        verbose_name="الطالب",
        null=True,
        blank=True,
    )
    # للتوافق مع الكود القديم (academic_id مباشرة)
    academic_id = models.CharField(max_length=20, verbose_name="الرقم الأكاديمي", db_index=True)
    book = models.ForeignKey(
        Book,
        on_delete=models.CASCADE,
        related_name='progress_records',
        verbose_name="الكتاب",
    )
    last_page = models.PositiveIntegerField(default=1, verbose_name="آخر صفحة")
    pages_read = models.PositiveIntegerField(default=0, verbose_name="عدد الصفحات المفتوحة")
    total_time_minutes = models.PositiveIntegerField(default=0, verbose_name="إجمالي وقت القراءة (دقيقة)")
    interaction_score = models.PositiveIntegerField(default=0, verbose_name="نقاط التفاعل")
    progress_percent = models.FloatField(default=0.0, verbose_name="نسبة الإنجاز")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="آخر تحديث")

    class Meta:
        # ضمان سجل واحد لكل طالب/كتاب
        unique_together = ('academic_id', 'book')
        verbose_name = "تقدم الطالب"
        verbose_name_plural = "تقدم الطلاب"
        indexes = [
            models.Index(fields=['academic_id']),
        ]

    def __str__(self):
        return f"{self.academic_id} - {self.book.title} ({self.progress_percent:.0%})"

    def save(self, *args, **kwargs):
        # ربط الطالب تلقائياً من الـ academic_id
        if not self.student_id and self.academic_id:
            from students.models import Student as St
            try:
                self.student = St.objects.get(academic_id=self.academic_id)
            except St.DoesNotExist:
                pass
        super().save(*args, **kwargs)
