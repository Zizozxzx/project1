import os
from django.conf import settings
from curriculum.models import PageSummary, PageSummaryPage


def import_pages():

    base = os.path.join(settings.BASE_DIR, "summaries")

    for summary_type in ["summary1", "summary2"]:

        type_path = os.path.join(base, summary_type)

        for page_folder in os.listdir(type_path):

            page_number = int(page_folder.replace("page_", ""))

            pages_path = os.path.join(type_path, page_folder)

            summary = PageSummary.objects.get(
                book_page__page_number=page_number,
                summary_type=int(summary_type[-1])
            )

            for file in sorted(os.listdir(pages_path)):

                order = int(file.replace(".html", ""))

                path = os.path.join(pages_path, file)

                with open(path, "r", encoding="utf8") as f:
                    html = f.read()

                PageSummaryPage.objects.create(
                    summary=summary,
                    page_order=order,
                    content_html=html
                )

    print("Import finished")