from django.urls import path
from .views import ProgressAPIView, StudentAllProgressAPIView, ClassStudentsProgressAPIView

urlpatterns = [
    path('progress/', ProgressAPIView.as_view(), name='progress'),
    path('progress/student/<str:academic_id>/', StudentAllProgressAPIView.as_view(), name='student-progress'),
    path('classes/<str:class_id>/students/', ClassStudentsProgressAPIView.as_view(), name='class-students'),
]
