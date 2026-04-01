from rest_framework.generics import ListAPIView
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Parent
from .serializers import ParentSerializer
from students.models import Student


class ParentListAPIView(ListAPIView):
    """GET /api/parents/?parent_id=xxx"""
    serializer_class = ParentSerializer

    def get_queryset(self):
        qs = Parent.objects.all()
        parent_id = self.request.query_params.get('parent_id')
        if parent_id:
            qs = qs.filter(parent_id=parent_id)
        return qs
