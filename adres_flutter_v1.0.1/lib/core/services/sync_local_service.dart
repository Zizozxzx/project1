import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

/// خدمة المزامنة التلقائية مع السيرفر عند توفر الإنترنت
class SyncLocalService {
  static Box get _box => Hive.box('studentBox');

  static bool hasPendingSync() {
    for (final key in _box.keys) {
      final val = _box.get(key);
      if (val is Map && val['isSynced'] == false) return true;
    }
    return false;
  }

  static List<Map<String, dynamic>> getAllPendingSyncData() {
    final List<Map<String, dynamic>> result = [];
    for (final key in _box.keys) {
      final val = _box.get(key);
      if (val is Map && val['isSynced'] == false) {
        result.add(Map<String, dynamic>.from(val));
      }
    }
    return result;
  }

  static void markAllAsSynced() {
    for (final key in _box.keys) {
      final val = _box.get(key);
      if (val is Map && val['isSynced'] == false) {
        final updated = Map<dynamic, dynamic>.from(val);
        updated['isSynced'] = true;
        _box.put(key, updated);
      }
    }
  }

  /// مزامنة التقدم مع السيرفر
  static Future<bool> syncProgressToServer() async {
    final pending = getAllPendingSyncData();
    if (pending.isEmpty) return true;

    final studentData = {
      'studentId': _box.get('studentId', defaultValue: ''),
      'academicId': _box.get('academicId', defaultValue: ''),
    };

    int successCount = 0;
    for (final data in pending) {
      try {
        final response = await http.post(
          Uri.parse('${AppConfig.backendBaseUrl}/api/progress/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'academic_id': studentData['academicId'],
            'book': int.tryParse(data['bookId']?.toString() ?? '1') ?? 1,
            'last_page': data['lastPage'] ?? 1,
            'pages_read': data['pagesReadCount'] ?? 0,
            'total_time_minutes': data['totalTimeMinutes'] ?? 0,
            'interaction_score': data['interactionScore'] ?? 0,
            'progress_percent': data['progressPercent'] ?? 0.0,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          successCount++;
        }
      } catch (_) {
        // تجاهل الخطأ وإعادة المحاولة لاحقاً
      }
    }

    if (successCount > 0) markAllAsSynced();
    return successCount == pending.length;
  }
}
