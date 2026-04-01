from django.urls import path
from .views import TeacherLoginAPIView

urlpatterns = [
    path('teachers/login/', TeacherLoginAPIView.as_view(), name='teacher-login'),
]
