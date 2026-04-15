#!/bin/bash
# سكريبت تشغيل تطبيق الإدارة بدون إنترنت

export PUB_HOSTED_URL=""
export FLUTTER_STORAGE_BASE_URL=""
export DART_PUB_MAX_RETRIES=0

cd "$(dirname "$0")"

echo "▶ جاري تثبيت المكتبات من الـ cache..."
flutter pub get --offline

echo "▶ جاري تشغيل التطبيق..."
flutter run --no-pub "$@"
