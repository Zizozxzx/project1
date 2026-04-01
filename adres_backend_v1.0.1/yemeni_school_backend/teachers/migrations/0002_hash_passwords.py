from django.db import migrations
from django.contrib.auth.hashers import make_password, is_password_usable


def hash_existing_passwords(apps, schema_editor):
    """Hash any plain-text passwords that exist in the database."""
    Teacher = apps.get_model('teachers', 'Teacher')
    for teacher in Teacher.objects.all():
        if teacher.password and not is_password_usable(teacher.password):
            teacher.password = make_password(teacher.password)
            teacher.save(update_fields=['password'])


class Migration(migrations.Migration):

    dependencies = [
        ('teachers', '0001_initial'),
    ]

    operations = [
        migrations.RunPython(hash_existing_passwords, migrations.RunPython.noop),
    ]
