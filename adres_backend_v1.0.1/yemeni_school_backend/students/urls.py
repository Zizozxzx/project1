from django.urls import path
from .views import StudentListAPIView

urlpatterns = [
    path('students/', StudentListAPIView.as_view(), name='student-list'),
]
