from rest_framework import serializers
from .models import Parent
from students.serializers import StudentSerializer


class ParentSerializer(serializers.ModelSerializer):
    children = StudentSerializer(many=True, read_only=True)

    class Meta:
        model = Parent
        fields = ['id', 'parent_id', 'full_name', 'children']
