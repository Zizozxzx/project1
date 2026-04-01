from django.contrib import admin
from .models import Progress

@admin.register(Progress)
class ProgressAdmin(admin.ModelAdmin):
    list_display = ['academic_id', 'book', 'last_page', 'progress_percent', 'total_time_minutes', 'updated_at']
    list_filter = ['book']
    search_fields = ['academic_id']
    ordering = ['-updated_at']
