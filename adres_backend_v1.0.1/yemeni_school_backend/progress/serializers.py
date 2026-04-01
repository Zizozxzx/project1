from rest_framework import serializers
from .models import Progress


class ProgressSerializer(serializers.ModelSerializer):
    class Meta:
        model = Progress
        fields = [
            'id', 'academic_id', 'book', 'last_page',
            'pages_read', 'total_time_minutes',
            'interaction_score', 'progress_percent', 'updated_at',
        ]
        read_only_fields = ['id', 'updated_at']


class ProgressCreateSerializer(serializers.Serializer):
    """لاستقبال البيانات من Flutter"""
    academic_id = serializers.CharField()
    book = serializers.IntegerField()
    last_page = serializers.IntegerField(default=1)
    pages_read = serializers.IntegerField(default=0)
    total_time_minutes = serializers.IntegerField(default=0)
    interaction_score = serializers.IntegerField(default=0)
    progress_percent = serializers.FloatField(default=0.0)
