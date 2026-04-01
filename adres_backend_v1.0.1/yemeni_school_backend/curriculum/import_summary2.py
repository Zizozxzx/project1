import os
import django
import sys

# إعداد بيئة دجانغو
sys.path.append(r"D:\projecte web\yemeni_school_backend")
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from curriculum.models import PageSummary, PageSummaryPage

def replace_summaries_110_190():
    from django.conf import settings
    from curriculum.models import PageSummary, PageSummaryPage
    
    folder = os.path.join(settings.BASE_DIR, "summaries", "summary2")
    START_P = 110
    END_P = 190

    print(f"--- جاري استبدال الملخصات من صفحة {START_P} إلى {END_P} ---")

    # 1. حذف الصفحات القديمة لهذا النطاق تماماً لتجنب التكرار أو التداخل
    affected_summaries = PageSummary.objects.filter(
        book_page__page_number__range=(START_P, END_P),
        summary_type=2
    )
    
    deleted_count = PageSummaryPage.objects.filter(summary__in=affected_summaries).delete()[0]
    print(f"🗑️ تم حذف {deleted_count} صفحة قديمة.")

    # 2. إعادة الاستيراد
    files = sorted(os.listdir(folder))
    page_orders = {}

    for file in files:
        if not file.endswith(".html") and not file.endswith(".HTML"): continue
        
        name = file.replace(".html", "").replace(".HTML", "")
        path = os.path.join(folder, file)

        # استخراج الصفحات
        pages = []
        try:
            if "-" in name:
                parts = name.split("-")
                start_p = int(parts[0])
                end_p = int(parts[-1])
                pages = list(range(start_p, end_p + 1))
            else:
                pages = [int(re.findall(r'\d+', name)[0])]
        except (ValueError, IndexError):
            continue

        # التحقق إذا كانت الصفحة ضمن النطاق المطلوب
        relevant_pages = [p for p in pages if START_P <= p <= END_P]
        if not relevant_pages: continue

        with open(path, "r", encoding="utf-8") as f:
            html_content = f.read()

        for page in relevant_pages:
            try:
                summary = PageSummary.objects.get(
                    book_page__page_number=page, 
                    summary_type=2
                )

                order = page_orders.get(page, 0) + 1
                page_orders[page] = order

                PageSummaryPage.objects.create(
                    summary=summary,
                    page_order=order,
                    content_html=html_content
                )
                print(f"✅ تم استبدال: ص {page} (من ملف: {file})")

            except PageSummary.DoesNotExist:
                print(f"❌ مفقود في DB: ص {page}")
            except Exception as e:
                print(f"⚠️ خطأ في ص {page}: {e}")

    print("--- تم استبدال جميع الصفحات بنجاح ---")

if __name__ == "__main__":
    import re
    replace_summaries_110_190()