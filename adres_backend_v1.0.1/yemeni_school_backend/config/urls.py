from django.contrib import admin
from django.urls import path, include
from .ai_views import ai_explain_view

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('curriculum.urls')),
    path('api/', include('progress.urls')),
    path('api/', include('students.urls')),
    path('api/', include('parents.urls')),
    path('api/', include('teachers.urls')),
    path('api/ai/explain/', ai_explain_view, name='ai-explain'),
    path('', include('curriculum.urls')),
]
