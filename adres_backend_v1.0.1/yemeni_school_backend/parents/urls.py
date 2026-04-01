from django.urls import path
from .views import ParentListAPIView

urlpatterns = [
    path('parents/', ParentListAPIView.as_view(), name='parent-list'),
]
