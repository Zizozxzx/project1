import 'package:hive/hive.dart';

/// =====================================================
/// إعدادات الاتصال بالسيرفر
/// يتم حفظ الرابط في Hive ويمكن تغييره من الإعدادات
/// =====================================================
class AppConfig {
  static const String _serverKey = 'server_url';
  static const String _defaultUrl = 'http://192.168.43.134:8000';

  /// اسم التطبيق
  static const String appName = 'ادرس';

  /// رقم الإصدار
  static const String appVersion = '1.0.1';

  /// جلب رابط الـ Backend الحالي (من Hive أو الافتراضي)
  static String get backendBaseUrl {
    try {
      final box = Hive.box('appBox');
      final saved = box.get(_serverKey) as String?;
      if (saved != null && saved.trim().isNotEmpty) {
        return saved.trim();
      }
    } catch (_) {}
    return _defaultUrl;
  }

  /// حفظ رابط السيرفر الجديد
  static Future<void> setBackendBaseUrl(String url) async {
    final box = Hive.box('appBox');
    String clean = url.trim();
    // إزالة الشرطة المائلة من النهاية
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    await box.put(_serverKey, clean);
  }

  /// إعادة الرابط إلى الافتراضي
  static Future<void> resetToDefault() async {
    final box = Hive.box('appBox');
    await box.delete(_serverKey);
  }

  /// الحصول على الرابط المحفوظ (أو null إذا لم يكن محفوظاً)
  static String? getSavedUrl() {
    try {
      final box = Hive.box('appBox');
      return box.get(_serverKey) as String?;
    } catch (_) {
      return null;
    }
  }
}
