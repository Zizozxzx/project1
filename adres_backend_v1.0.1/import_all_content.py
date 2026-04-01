#!/usr/bin/env python
"""استيراد كل محتوى الكتاب والملخصات إلى قاعدة البيانات"""
import os, sys, django

os.chdir(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.abspath('yemeni_school_backend'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from curriculum.models import Subject, Book, BookPage, PageSummary, PageSummaryPage

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'yemeni_school_backend', 'summaries')

# ===== 1. Subject & Book =====
subject, _ = Subject.objects.get_or_create(
    name='رياضيات',
    defaults={'grade_level': 'التاسع', 'education_stage': 'middle', 'order': 1}
)
book, _ = Book.objects.get_or_create(
    subject=subject,
    term='first',
    defaults={'title': 'رياضيات - الصف التاسع - الفصل الأول', 'total_pages': 192}
)
print(f"✅ Book: {book}")

# ===== 2. BookPages من مجلد 'book  html' =====
book_folder = os.path.join(BASE, 'book  html')
pages_created = 0
for fname in os.listdir(book_folder):
    if not fname.lower().endswith('.html'):
        continue
    try:
        page_num = int(fname.replace('.html', '').replace('.HTML', ''))
    except ValueError:
        continue
    path = os.path.join(book_folder, fname)
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        html = f.read()
    _, created = BookPage.objects.get_or_create(
        book=book, page_number=page_num,
        defaults={'content_html': html}
    )
    if created:
        pages_created += 1

print(f"✅ BookPages created: {pages_created} | total: {BookPage.objects.filter(book=book).count()}")

# ===== 3. Summaries (type 1 و 2) =====
def import_summaries(summary_type):
    folder = os.path.join(BASE, f'summary{summary_type}')
    if not os.path.exists(folder):
        print(f"⚠️ مجلد summary{summary_type} غير موجود")
        return

    # بناء خريطة: رقم الصفحة -> قائمة (ترتيب, html)
    file_map = {}
    for fname in sorted(os.listdir(folder)):
        if not fname.lower().endswith('.html'):
            continue
        name = os.path.splitext(fname)[0]
        # استخراج أرقام الصفحات من اسم الملف (مثل 13-14-15 أو 137_3)
        # نأخذ فقط الأرقام الأساسية (قبل _)
        base_name = name.split('_')[0]
        try:
            page_nums = [int(x) for x in base_name.split('-') if x.strip().isdigit()]
        except:
            continue
        if not page_nums:
            continue
        path = os.path.join(folder, fname)
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            html = f.read()
        for p in page_nums:
            file_map.setdefault(p, []).append(html)

    created_s = created_p = 0
    for book_page in BookPage.objects.filter(book=book):
        pnum = book_page.page_number
        if pnum not in file_map:
            continue
        summary, s_created = PageSummary.objects.get_or_create(
            book_page=book_page, summary_type=summary_type
        )
        if s_created:
            created_s += 1
        if summary.pages.exists():
            continue
        for order, html in enumerate(file_map[pnum], start=1):
            PageSummaryPage.objects.get_or_create(
                summary=summary, page_order=order,
                defaults={'content_html': html}
            )
            created_p += 1

    print(f"✅ Summary{summary_type}: summaries={created_s}, pages={created_p}")

import_summaries(1)
import_summaries(2)

print("\n🎉 اكتمل الاستيراد!")
print(f"   BookPages: {BookPage.objects.filter(book=book).count()}")
print(f"   PageSummaries type1: {PageSummary.objects.filter(summary_type=1).count()}")
print(f"   PageSummaries type2: {PageSummary.objects.filter(summary_type=2).count()}")
