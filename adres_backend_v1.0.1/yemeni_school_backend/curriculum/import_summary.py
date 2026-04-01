import os
from django.conf import settings
from curriculum.models import BookPage, PageSummary, PageSummaryPage


def fill_missing_pages(summary_type=2):

    folder = os.path.join(
        settings.BASE_DIR,
        "summaries",
        f"summary{summary_type}"
    )

    files = os.listdir(folder)

    # 🔥 خريطة الملفات
    file_map = {}

    for file in files:
        if not file.endswith(".html"):
            continue

        name = file.replace(".html", "")

        pages = [int(x) for x in name.split("-") if x.strip()]

        for p in pages:
            file_map.setdefault(p, []).append(file)

    created = 0
    skipped = 0

    # 🔥 المرور على كل صفحات الكتاب
    for book_page in BookPage.objects.all():

        page_number = book_page.page_number

        try:
            summary = PageSummary.objects.get(
                book_page=book_page,
                summary_type=summary_type
            )
        except PageSummary.DoesNotExist:
            print(f"❌ Missing summary object → Page {page_number}")
            continue

        # 🔥 هل عنده صفحات ملخص؟
        if summary.pages.exists():
            print(f"⛔ Already has summary → Page {page_number}")
            skipped += 1
            continue

        # 🔥 هل يوجد ملف له؟
        if page_number not in file_map:
            print(f"⚠️ No file found → Page {page_number}")
            continue

        # 🔥 إضافة الصفحات
        for index, file in enumerate(file_map[page_number], start=1):

            path = os.path.join(folder, file)

            with open(path, "r", encoding="utf-8") as f:
                html = f.read()

            PageSummaryPage.objects.create(
                summary=summary,
                page_order=index,
                content_html=html
            )

            print(f"✅ Created → Page {page_number} Order {index}")
            created += 1

    print("\n🔥 DONE")
    print(f"Created: {created}")
    print(f"Skipped: {skipped}")