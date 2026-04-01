from django.http import HttpResponse, Http404
from rest_framework.generics import ListAPIView, RetrieveAPIView
from rest_framework.exceptions import NotFound

from .models import Subject, Book, BookPage, PageSummary, PageSummaryPage
from .serializers import (
    SubjectSerializer, BookSerializer, BookPageSerializer,
    PageSummarySerializer, PageSummaryPageSerializer,
)


class SubjectListAPIView(ListAPIView):
    queryset = Subject.objects.all().order_by('order')
    serializer_class = SubjectSerializer


class BookListAPIView(ListAPIView):
    serializer_class = BookSerializer

    def get_queryset(self):
        qs = Book.objects.all()
        subject_id = self.request.query_params.get('subject')
        term = self.request.query_params.get('term')
        if subject_id:
            qs = qs.filter(subject_id=subject_id)
        if term:
            qs = qs.filter(term=term)
        return qs


class BookPageAPIView(RetrieveAPIView):
    serializer_class = BookPageSerializer

    def get_object(self):
        book_id = self.request.query_params.get('book')
        page_number = self.request.query_params.get('page')
        if not book_id or not page_number:
            raise NotFound("book and page parameters are required")
        try:
            return BookPage.objects.get(book_id=book_id, page_number=page_number)
        except BookPage.DoesNotExist:
            raise NotFound("Page not found")


class PageSummaryListAPIView(ListAPIView):
    serializer_class = PageSummarySerializer

    def get_queryset(self):
        book_page_id = self.request.query_params.get('page')
        if not book_page_id:
            return PageSummary.objects.none()
        return PageSummary.objects.filter(book_page_id=book_page_id)


class PageSummaryPageAPIView(RetrieveAPIView):
    serializer_class = PageSummaryPageSerializer

    def get_object(self):
        summary_id = self.request.query_params.get('summary')
        page_order = self.request.query_params.get('page')
        if not summary_id or not page_order:
            raise NotFound("summary and page parameters are required")
        try:
            return PageSummaryPage.objects.get(summary_id=summary_id, page_order=page_order)
        except PageSummaryPage.DoesNotExist:
            raise NotFound("Summary page not found")


def book_page_html_view(request, page_number):
    book_id = request.GET.get('book')
    qs = BookPage.objects.filter(page_number=page_number)
    if book_id:
        qs = qs.filter(book_id=book_id)
    page = qs.first()
    if not page:
        raise Http404("Page not found")

    html = page.content_html
    viewport_meta = '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=yes">'
    if '<head>' in html:
        html = html.replace('<head>', f'<head>{viewport_meta}')
    else:
        html = viewport_meta + html
    return HttpResponse(html)


def summary_page_html_view(request):
    book_id = request.GET.get("book")
    page_number = request.GET.get("page")
    summary_type = request.GET.get("type")
    summary_page = request.GET.get("summary_page", 1)

    if not all([book_id, page_number, summary_type]):
        raise Http404("Missing parameters")

    try:
        page_number = int(page_number)
        summary_type = int(summary_type)
        summary_page = int(summary_page)

        book_page = BookPage.objects.filter(
            book_id=book_id, page_number=page_number
        ).first()
        if not book_page:
            raise Http404("Book page not found")

        summary = PageSummary.objects.filter(
            book_page=book_page, summary_type=summary_type
        ).first()
        if not summary:
            raise Http404("Summary not found")

        page = PageSummaryPage.objects.filter(
            summary=summary, page_order=summary_page
        ).first()
        if not page:
            raise Http404("Summary page not found")

        total_pages = PageSummaryPage.objects.filter(summary=summary).count()
    except (ValueError, TypeError) as e:
        raise Http404(f"Invalid parameters: {e}")

    has_next = summary_page < total_pages
    has_prev = summary_page > 1

    navigation = f"""<script>
        window.hasNext = {str(has_next).lower()};
        window.hasPrev = {str(has_prev).lower()};
        window.totalPages = {total_pages};
    </script>"""

    return HttpResponse(navigation + page.content_html)
