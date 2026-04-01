from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('curriculum.urls')),
    path('api/', include('progress.urls')),
    path('api/', include('students.urls')),
    path('api/', include('parents.urls')),
    path('api/', include('teachers.urls')),
    # صفحات الكتب بدون /api/ prefix (للتوافق مع Flutter)
    path('', include('curriculum.urls')),
]
