#!/usr/bin/env python
"""
سكريبت إعداد قاعدة البيانات - نفذه مرة واحدة بعد تثبيت المتطلبات
python setup_db.py
"""
import os
import sys
import django

os.chdir(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.abspath('yemeni_school_backend'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.core.management import call_command

print("⏳ Creating migrations...")
call_command('makemigrations', 'students', verbosity=1)
call_command('makemigrations', 'teachers', verbosity=1)
call_command('makemigrations', 'parents', verbosity=1)
call_command('makemigrations', 'progress', verbosity=1)

print("⏳ Applying migrations...")
call_command('migrate', verbosity=1)

print("✅ Database setup complete!")
print("\n📌 To start the server:")
print("   cd yemeni_school_backend")
print("   python manage.py runserver 0.0.0.0:8000")
