from django.contrib import admin
from django.urls import path
from django.shortcuts import redirect, render
from django.contrib import messages

from .import_summary import fill_missing_pages

from .models import (
    Subject,
    Book,
    OldSummary,
    BookPage,
    PageSummary,
    PageSummaryPage,
)

# =========================
# Subject
# =========================
@admin.register(Subject)
class SubjectAdmin(admin.ModelAdmin):
    list_display = ('name', 'grade_level', 'education_stage', 'order')
    list_filter = ('education_stage', 'grade_level')
    search_fields = ('name',)
    ordering = ('order',)
    list_per_page = 20


# =========================
# Book
# =========================
@admin.register(Book)
class BookAdmin(admin.ModelAdmin):
    list_display = ('title', 'subject', 'term', 'total_pages')
    list_filter = ('subject', 'term')
    search_fields = ('title',)
    list_select_related = ('subject',)
    list_per_page = 20


# =========================
# Old Summary
# =========================
@admin.register(OldSummary)
class OldSummaryAdmin(admin.ModelAdmin):
    list_display = ('title', 'book', 'summary_type', 'created_at')
    list_filter = ('book', 'summary_type')
    search_fields = ('title',)


# =========================
# Book Page
# =========================
@admin.register(BookPage)
class BookPageAdmin(admin.ModelAdmin):
    list_display = ("book", "page_number")
    list_filter = ("book",)
    search_fields = ("page_number",)
    ordering = ("page_number",)
    list_select_related = ("book",)


# =========================
# Page Summary
# =========================
@admin.register(PageSummary)
class PageSummaryAdmin(admin.ModelAdmin):

    list_display = ("book_page", "get_summary_type_display", "get_pages_count")
    list_filter = ("summary_type", "book_page__book")
    search_fields = ("book_page__page_number",)

    def get_summary_type_display(self, obj):
        return obj.get_summary_type_display()
    get_summary_type_display.short_description = "نوع الملخص"
    get_summary_type_display.admin_order_field = "summary_type"

    def get_pages_count(self, obj):
        count = obj.pages.count()
        if count == 0:
            return "⚠️ لا توجد صفحات"
        return f"{count} صفحات"
    get_pages_count.short_description = "عدد صفحات الشرح"

    @staticmethod
    def get_page_ranges(page_numbers):
        if not page_numbers:
            return []
        page_numbers = sorted(list(page_numbers))
        ranges = []
        start = page_numbers[0]
        end = start
        for i in range(1, len(page_numbers)):
            if page_numbers[i] == end + 1:
                end = page_numbers[i]
            else:
                if start == end:
                    ranges.append(f"{start}")
                else:
                    ranges.append(f"{start} - {end}")
                start = page_numbers[i]
                end = start
        if start == end:
            ranges.append(f"{start}")
        else:
            ranges.append(f"{start} - {end}")
        return ranges

    # 🔥 مهم لعرض الزر
    change_list_template = "admin/curriculum/pagesummary/change_list.html"

    # =========================
    # Dashboard Stats & Actions
    # =========================
    def changelist_view(self, request, extra_context=None):
        from .models import BookPage, PageSummary
        
        if extra_context is None:
            extra_context = {}
            
        # Calc stats for all 3 types
        stats = {}
        for t_type in [1, 2, 3]:
            # 1. BookPages that DON'T have a PageSummary at all (Current missing)
            summarized_page_ids = PageSummary.objects.filter(summary_type=t_type).values_list('book_page_id', flat=True)
            missing_summaries = BookPage.objects.exclude(id__in=summarized_page_ids).count()
            
            # 2. PageSummaries that DON'T have any PageSummaryPage (New missing / empty content)
            empty_summaries = PageSummary.objects.filter(summary_type=t_type, pages__isnull=True).count()
            
            stats[t_type] = {
                'missing': missing_summaries,
                'empty': empty_summaries
            }
            
        extra_context['summary_stats'] = stats
        # For backward compatibility with existing templates if any
        extra_context['missing_count'] = stats.get(2, {}).get('missing', 0)
        
        return super().changelist_view(request, extra_context=extra_context)

    # =========================
    # URLs (أزرار العمليات)
    # =========================
    def get_urls(self):
        urls = super().get_urls()

        custom_urls = [
            # زر إنشاء صفحات فارغة
            path(
                "generate-pages/",
                self.admin_site.admin_view(self.generate_pages),
                name="generate_summary_pages",
            ),

            # 🔥 زر تعبئة الصفحات الناقصة الذكي
            path(
                "fill-missing/",
                self.admin_site.admin_view(self.fill_missing_view),
                name="fill_missing_view",
            ),

            # زر عرض الصفحات الناقصة
            path(
                "missing-list/",
                self.admin_site.admin_view(self.missing_list_view),
                name="missing_list_view",
            ),
        ]

        return custom_urls + urls

    def missing_list_view(self, request):
        from .models import BookPage, PageSummary, Book
        
        target_type = request.GET.get('type')
        if target_type:
            try:
                target_type = int(target_type)
                types_to_check = [target_type]
            except ValueError:
                types_to_check = [1, 2, 3]
        else:
            types_to_check = [1, 2, 3]

        data = []
        books = Book.objects.all().order_by('title')
        
        for book in books:
            book_data = {'book': book, 'types': {}}
            pages = BookPage.objects.filter(book=book).order_by('page_number')
            total_pages_count = pages.count()
            
            for t_type in types_to_check:
                summaries = PageSummary.objects.filter(
                    book_page__book=book, 
                    summary_type=t_type
                ).select_related('book_page')
                
                summarized_page_numbers = set(summaries.values_list('book_page__page_number', flat=True))
                all_page_numbers = set(pages.values_list('page_number', flat=True))
                
                # 1. Missing: No PageSummary record exists
                missing_pages = sorted(list(all_page_numbers - summarized_page_numbers))
                
                # 2. Empty: PageSummary record exists but has no PageSummaryPage children
                empty_pages = sorted([
                    s.book_page.page_number for s in summaries if not s.pages.exists()
                ])
                
                missing_count = len(missing_pages)
                empty_count = len(empty_pages)
                
                if missing_count == 0 and empty_count == 0:
                    status = 'complete'
                elif missing_count == total_pages_count:
                    status = 'not_started'
                elif empty_count > 0:
                    status = 'has_empty'
                else:
                    status = 'in_progress'

                if missing_count > 0 or empty_count > 0 or target_type:
                    book_data['types'][t_type] = {
                        'ranges': PageSummaryAdmin.get_page_ranges(missing_pages),
                        'count': missing_count,
                        'empty_ranges': PageSummaryAdmin.get_page_ranges(empty_pages),
                        'empty_count': empty_count,
                        'status': status
                    }
            
            if book_data['types']:
                data.append(book_data)
        
        title = "تفاصيل الصفحات الناقصة"
        if target_type and target_type in [1, 2, 3]:
            title += f" للملخص {target_type}"
        else:
            title += " لكل الملخصات"

        return render(request, "admin/missing_summaries_list.html", {
            "data": data,
            "title": title,
            "target_type": target_type
        })

    # =========================
    # Generate Empty Pages
    # =========================
    def generate_pages(self, request):
        summaries = PageSummary.objects.filter(summary_type=2)
        created = 0

        for summary in summaries:
            if not summary.pages.exists():
                PageSummaryPage.objects.create(
                    summary=summary,
                    page_order=1,
                    content_html="<h1>صفحة الملخص</h1>"
                )
                created += 1

        self.message_user(
            request,
            f"تم إنشاء {created} صفحة ملخص",
            messages.SUCCESS
        )
        return redirect("../")

    # =========================
    # 🔥 Smart Fill Missing View
    # =========================
    def fill_missing_view(self, request):
        if request.method == "POST":
            summary_type = int(request.POST.get("summary_type"))
            created = fill_missing_pages(summary_type)
            self.message_user(
                request,
                f"تم تعبئة الصفحات الناقصة للملخص {summary_type}: {created}",
                messages.SUCCESS
            )
            return redirect("../")
        return render(request, "admin/fill_missing.html")


# =========================
# Page Summary Pages
# =========================
@admin.register(PageSummaryPage)
class PageSummaryPageAdmin(admin.ModelAdmin):

    list_display = (
        "get_book",
        "get_page",
        "get_summary_type",
        "page_order",
        "get_total_pages_in_summary",
    )

    list_filter = (
        "summary__summary_type",
        "summary__book_page__book",
    )

    search_fields = (
        "summary__book_page__page_number",
    )

    ordering = (
        "summary__book_page__page_number",
        "page_order",
    )

    list_select_related = (
        "summary",
        "summary__book_page",
        "summary__book_page__book",
    )

    list_per_page = 30

    # 🔥 مهم لعرض الزر
    change_list_template = "admin/curriculum/pagesummarypage/change_list.html"

    # =========================
    # Dashboard Stats
    # =========================
    def changelist_view(self, request, extra_context=None):
        from .models import BookPage, PageSummary
        
        if extra_context is None:
            extra_context = {}
            
        stats = {}
        for t_type in [1, 2, 3]:
            # 1. BookPages that DON'T have a PageSummary at all
            summarized_page_ids = PageSummary.objects.filter(summary_type=t_type).values_list('book_page_id', flat=True)
            missing_summaries = BookPage.objects.exclude(id__in=summarized_page_ids).count()
            
            # 2. PageSummaries that DON'T have any PageSummaryPage
            empty_summaries = PageSummary.objects.filter(summary_type=t_type, pages__isnull=True).count()
            
            stats[t_type] = {
                'missing': missing_summaries,
                'empty': empty_summaries
            }
            
        extra_context['summary_stats'] = stats
        extra_context['missing_count'] = stats.get(2, {}).get('missing', 0)
        
        return super().changelist_view(request, extra_context=extra_context)

    # =========================
    # URLs (أزرار العمليات)
    # =========================
    def get_urls(self):
        urls = super().get_urls()

        custom_urls = [
            # زر إنشاء صفحات فارغة
            path(
                "generate-pages/",
                self.admin_site.admin_view(self.generate_pages),
                name="generate_summary_pages_alt",
            ),

            # 🔥 زر تعبئة الصفحات الناقصة الذكي
            path(
                "fill-missing/",
                self.admin_site.admin_view(self.fill_missing_view),
                name="fill_missing_view_alt",
            ),

            # زر عرض الصفحات الناقصة
            path(
                "missing-list/",
                self.admin_site.admin_view(self.missing_list_view),
                name="missing_list_view_alt",
            ),
        ]

        return custom_urls + urls

    def missing_list_view(self, request):
        # Delegate to PageSummaryAdmin logic
        return PageSummaryAdmin.missing_list_view(self, request)

    # =========================
    # Logic (Reused from PageSummaryAdmin)
    # =========================
    def generate_pages(self, request):
        # We can just redirect to the other admin's view or duplicate logic
        # Duplicating logic for simplicity in this file
        summaries = PageSummary.objects.filter(summary_type=2)
        created = 0
        for summary in summaries:
            if not summary.pages.exists():
                PageSummaryPage.objects.create(
                    summary=summary,
                    page_order=1,
                    content_html="<h1>صفحة الملخص</h1>"
                )
                created += 1

        self.message_user(request, f"تم إنشاء {created} صفحة ملخص", messages.SUCCESS)
        return redirect("../")

    def fill_missing_view(self, request):
        if request.method == "POST":
            summary_type = int(request.POST.get("summary_type"))
            created = fill_missing_pages(summary_type)
            self.message_user(request, f"تم تعبئة الصفحات الناقصة للملخص {summary_type}: {created}", messages.SUCCESS)
            return redirect("../")
        return render(request, "admin/fill_missing.html")

    # =========================
    # عرض بيانات محسنة
    # =========================
    def get_book(self, obj):
        return obj.summary.book_page.book.title
    get_book.short_description = "Book"

    def get_page(self, obj):
        return obj.summary.book_page.page_number
    get_page.short_description = "Page"

    def get_summary_type(self, obj):
        return obj.summary.get_summary_type_display()
    get_summary_type.short_description = "نوع الملخص"

    def get_total_pages_in_summary(self, obj):
        count = obj.summary.pages.count()
        return f"{count} صفحات"
    get_total_pages_in_summary.short_description = "إجمالي صفحات الملخص"
