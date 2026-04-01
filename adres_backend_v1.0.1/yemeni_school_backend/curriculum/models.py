from django.db import models

# =========================
# Subject
# =========================

class Subject(models.Model):
    STAGE_CHOICES = (
        ('primary', 'ابتدائي'),
        ('middle', 'إعدادي'),
        ('secondary', 'ثانوي'),
    )

    name = models.CharField(max_length=100, verbose_name="اسم المادة")
    grade_level = models.CharField(max_length=50, verbose_name="الصف الدراسي")
    education_stage = models.CharField(
        max_length=20,
        choices=STAGE_CHOICES,
        verbose_name="المرحلة التعليمية"
    )
    order = models.PositiveIntegerField(default=0, verbose_name="ترتيب العرض")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="تاريخ الإنشاء")

    def __str__(self):
        return f"{self.name} - {self.grade_level}"


# =========================
# Book
# =========================

class Book(models.Model):
    TERM_CHOICES = (
        ('first', 'الفصل الدراسي الأول'),
        ('second', 'الفصل الدراسي الثاني'),
    )

    subject = models.ForeignKey(
        Subject,
        on_delete=models.CASCADE,
        related_name='books',
        verbose_name="المادة"
    )
    title = models.CharField(max_length=255, verbose_name="عنوان الكتاب")
    term = models.CharField(
        max_length=20,
        choices=TERM_CHOICES,
        verbose_name="الفصل الدراسي"
    )
    total_pages = models.PositiveIntegerField(verbose_name="عدد الصفحات")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="تاريخ الإنشاء")

    def __str__(self):
        return f"{self.title} ({self.get_term_display()})"


# =========================
# Old Summary (Deprecated)
# =========================
# ⚠️ هذا الموديل قديم – لن نستخدمه بعد الآن
# نُبقيه فقط حفاظًا على الـ migrations السابقة

class OldSummary(models.Model):
    SUMMARY_TYPE_CHOICES = (
        (1, 'الملخص الأول'),
        (2, 'الملخص الثاني'),
        (3, 'الملخص الثالث'),
    )

    book = models.ForeignKey(
        Book,
        on_delete=models.CASCADE,
        related_name='old_summaries',
        verbose_name="الكتاب"
    )
    title = models.CharField(max_length=255)
    summary_type = models.PositiveSmallIntegerField(choices=SUMMARY_TYPE_CHOICES)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title


# =========================
# BookPage
# =========================
# صفحة واحدة من الكتاب

class BookPage(models.Model):
    book = models.ForeignKey(
        Book,
        on_delete=models.CASCADE,
        related_name='pages'
    )
    page_number = models.PositiveIntegerField()
    content_html = models.TextField()

    class Meta:
        unique_together = ('book', 'page_number')
        ordering = ['page_number']

    def __str__(self):
        return f"{self.book.title} - Page {self.page_number}"


# =========================
# PageSummary
# =========================
# نوع الملخص (1 / 2 / 3) لصفحة كتاب واحدة

class PageSummary(models.Model):
    SUMMARY_TYPES = (
        (1, 'الملخص الأول'),
        (2, 'الملخص الثاني'),
        (3, 'الملخص الثالث'),
    )

    book_page = models.ForeignKey(
        BookPage,
        on_delete=models.CASCADE,
        related_name='summaries'
    )
    summary_type = models.PositiveSmallIntegerField(choices=SUMMARY_TYPES)

    class Meta:
        unique_together = ('book_page', 'summary_type')
        ordering = ['summary_type']
        indexes = [
        models.Index(fields=['book_page', 'summary_type']),
    ]

    def __str__(self):
        return f"{self.book_page} - Summary {self.summary_type}"


# =========================
# PageSummaryPage
# =========================
# صفحات الشرح داخل كل ملخص

class PageSummaryPage(models.Model):
    summary = models.ForeignKey(
        PageSummary,
        on_delete=models.CASCADE,
        related_name='pages'
    )
    page_order = models.PositiveIntegerField()
    content_html = models.TextField()

    class Meta:
        unique_together = ('summary', 'page_order')
        ordering = ['page_order']
        indexes = [
        models.Index(fields=['summary', 'page_order']),
    ]

    def __str__(self):
        return f"{self.summary} - Page {self.page_order}"

    
