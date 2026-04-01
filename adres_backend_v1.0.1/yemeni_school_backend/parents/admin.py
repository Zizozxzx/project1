from django.contrib import admin
from .models import Parent

@admin.register(Parent)
class ParentAdmin(admin.ModelAdmin):
    list_display = ['parent_id', 'full_name']
    search_fields = ['parent_id', 'full_name']
    filter_horizontal = ['children']
