import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// خدمة الاتصال بالـ Backend
class ApiService {
  static String get base => AppConfig.backendBaseUrl;

  // ========== مصادقة الطالب ==========
  static Future<Map<String, dynamic>?> loginStudent(String academicId) async {
    // حسابات تجريبية محلية
    if (academicId == '78246') {
      return {
        'id': '1',
        'academic_id': '78246',
        'full_name': 'أحمد محمد علي',
        'grade_level': 'التاسع',
        'class_id': 'class_9A',
        'class_name': 'التاسع - أ',
        'subjects': [
          {'id': '1', 'name': 'رياضيات', 'icon': 'calculate'},
          {'id': '2', 'name': 'علوم', 'icon': 'science'},
          {'id': '3', 'name': 'لغة عربية', 'icon': 'menu_book'},
          {'id': '4', 'name': 'قرآن', 'icon': 'book'},
          {'id': '5', 'name': 'إسلامية', 'icon': 'book'},
          {'id': '6', 'name': 'تاريخ', 'icon': 'history_edu'},
        ],
      };
    }

    try {
      final res = await http.get(
        Uri.parse('$base/api/students/?academic_id=$academicId'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) return Map<String, dynamic>.from(data[0]);
        if (data is Map) return Map<String, dynamic>.from(data);
      }
    } catch (_) {}
    return null;
  }

  // ========== مصادقة المعلم ==========
  static Future<Map<String, dynamic>?> loginTeacher(
      String teacherId, String password) async {
    // حساب تجريبي
    if (teacherId == '78246' && password == '123') {
      return {
        'id': 'teacher_1',
        'teacher_id': '78246',
        'full_name': 'أ. محمد عبدالله',
        'subject': 'رياضيات',
        'classes': [
          {
            'id': 'class_9A',
            'name': 'التاسع - أ',
            'students_count': 32,
            'active_rate': 0.75,
          },
          {
            'id': 'class_9B',
            'name': 'التاسع - ب',
            'students_count': 28,
            'active_rate': 0.60,
          },
        ],
      };
    }

    try {
      final res = await http.post(
        Uri.parse('$base/api/teachers/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'teacher_id': teacherId, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ========== مصادقة ولي الأمر ==========
  static Future<Map<String, dynamic>?> loginParent(String parentId) async {
    // حساب تجريبي
    if (parentId == '78246') {
      return {
        'id': 'parent_1',
        'parent_id': '78246',
        'full_name': 'محمد علي الحسن (ولي الأمر)',
        'children': [
          {
            'id': '1',
            'academic_id': '78246',
            'full_name': 'أحمد محمد علي',
            'grade_level': 'التاسع',
            'class_name': 'التاسع - أ',
          },
        ],
      };
    }

    try {
      final res = await http.get(
        Uri.parse('$base/api/parents/?parent_id=$parentId'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map) return Map<String, dynamic>.from(data);
      }
    } catch (_) {}
    return null;
  }

  // ========== إضافة طالب لولي الأمر ==========
  static Future<Map<String, dynamic>?> addChildToParent(
      String parentId, String childAcademicId) async {
    if (childAcademicId == '78246') {
      return {
        'id': '1',
        'academic_id': '78246',
        'full_name': 'أحمد محمد علي',
        'grade_level': 'التاسع',
        'class_name': 'التاسع - أ',
      };
    }

    try {
      final res = await http.get(
        Uri.parse('$base/api/students/?academic_id=$childAcademicId'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) return Map<String, dynamic>.from(data[0]);
      }
    } catch (_) {}
    return null;
  }

  // ========== تقدم الطالب ==========
  static Future<Map<String, dynamic>?> getStudentProgress(
      String academicId, String bookId) async {
    try {
      final res = await http.get(
        Uri.parse(
            '$base/api/progress/?academic_id=$academicId&book=$bookId'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ========== تقدم الطالب الكامل ==========
  static Future<List<Map<String, dynamic>>> getStudentAllProgress(
      String academicId) async {
    try {
      final res = await http.get(
        Uri.parse('$base/api/progress/student/$academicId/'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ========== طلاب الشعبة ==========
  static Future<List<Map<String, dynamic>>> getClassStudents(
      String classId) async {
    try {
      final res = await http.get(
        Uri.parse('$base/api/classes/$classId/students/'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ========== رفع التقدم ==========
  static Future<bool> syncProgress({
    required String academicId,
    required String bookId,
    required int lastPage,
    required int pagesRead,
    required int totalTimeMinutes,
    required int interactionScore,
    required double progressPercent,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$base/api/progress/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'academic_id': academicId,
          'book': int.tryParse(bookId) ?? 1,
          'last_page': lastPage,
          'pages_read': pagesRead,
          'total_time_minutes': totalTimeMinutes,
          'interaction_score': interactionScore,
          'progress_percent': progressPercent,
        }),
      ).timeout(const Duration(seconds: 10));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
