from rest_framework import serializers



from .models import (
    Subject,
    Book,
    BookPage,
    PageSummary,
    PageSummaryPage,
)


class SubjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Subject
        fields = [
            'id',
            'name',
            'grade_level',
            'education_stage',
            'order',
        ]





class BookSerializer(serializers.ModelSerializer):
    class Meta:
        model = Book
        fields = [
            'id',
            'title',
            'term',
            'total_pages',
            'subject',
        ]



# class SummarySerializer(serializers.ModelSerializer):
#     class Meta:
#         model = Summary
#         fields = [
#             'id',
#             'title',
#             'summary_type',
#             'content',
#             'book',
#         ]



class BookPageSerializer(serializers.ModelSerializer):
    class Meta:
        model = BookPage
        fields = [
            'id',
            'page_number',
            'content_html',
        ]

class PageSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = PageSummary
        fields = [
            'id',
            'summary_type',
        ]



class PageSummaryPageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PageSummaryPage
        fields = [
            'id',
            'page_order',
            'content_html',
        ]
