import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminApi {
  static String baseUrl = 'http://192.168.43.134:8000';

  static Map<String, String> get _h => {'Content-Type': 'application/json'};

  // ─── مساعد ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> _req(
    String method, String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    http.Response res;
    try {
      switch (method) {
        case 'GET':    res = await http.get(uri, headers: _h).timeout(const Duration(seconds: 10)); break;
        case 'POST':   res = await http.post(uri, headers: _h, body: jsonEncode(body)).timeout(const Duration(seconds: 10)); break;
        case 'PUT':    res = await http.put(uri, headers: _h, body: jsonEncode(body)).timeout(const Duration(seconds: 10)); break;
        case 'DELETE': res = await http.delete(uri, headers: _h).timeout(const Duration(seconds: 10)); break;
        default: return {'error': 'method غير معروف'};
      }
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'ok': true, 'data': decoded};
      }
      return {'ok': false, 'error': decoded['error'] ?? decoded.toString()};
    } catch (e) {
      return {'ok': false, 'error': 'تعذر الاتصال بالسيرفر'};
    }
  }

  // ─── الطلاب ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> getStudents() => _req('GET', '/api/students/');
  static Future<Map<String, dynamic>> createStudent(Map<String, dynamic> data) => _req('POST', '/api/students/', data);
  static Future<Map<String, dynamic>> updateStudent(String academicId, Map<String, dynamic> data) => _req('PUT', '/api/students/$academicId/', data);
  static Future<Map<String, dynamic>> deleteStudent(String academicId) => _req('DELETE', '/api/students/$academicId/');

  // ─── المعلمون ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getTeachers() => _req('GET', '/api/teachers/');
  static Future<Map<String, dynamic>> createTeacher(Map<String, dynamic> data) => _req('POST', '/api/teachers/', data);
  static Future<Map<String, dynamic>> updateTeacher(String teacherId, Map<String, dynamic> data) => _req('PUT', '/api/teachers/$teacherId/detail/', data);
  static Future<Map<String, dynamic>> deleteTeacher(String teacherId) => _req('DELETE', '/api/teachers/$teacherId/detail/');
  static Future<Map<String, dynamic>> addStudentToTeacher(String teacherId, String academicId, String className) =>
      _req('POST', '/api/teachers/$teacherId/add_student/', {'academic_id': academicId, 'class_name': className});
  static Future<Map<String, dynamic>> removeStudentFromTeacher(String teacherId, String academicId) =>
      _req('DELETE', '/api/teachers/$teacherId/remove_student/$academicId/');
  static Future<Map<String, dynamic>> addClassToTeacher(String teacherId, Map<String, dynamic> data) =>
      _req('POST', '/api/teachers/$teacherId/add_class/', data);
  static Future<Map<String, dynamic>> removeClassFromTeacher(String teacherId, String classId) =>
      _req('DELETE', '/api/teachers/$teacherId/remove_class/$classId/');

  // ─── أولياء الأمور ────────────────────────────────────────
  static Future<Map<String, dynamic>> getParents() => _req('GET', '/api/parents/');
  static Future<Map<String, dynamic>> createParent(Map<String, dynamic> data) => _req('POST', '/api/parents/', data);
  static Future<Map<String, dynamic>> updateParent(String parentId, Map<String, dynamic> data) => _req('PUT', '/api/parents/$parentId/detail/', data);
  static Future<Map<String, dynamic>> deleteParent(String parentId) => _req('DELETE', '/api/parents/$parentId/detail/');
  static Future<Map<String, dynamic>> addChildToParent(String parentId, String academicId) =>
      _req('POST', '/api/parents/$parentId/add_child/', {'academic_id': academicId});
  static Future<Map<String, dynamic>> removeChildFromParent(String parentId, String academicId) =>
      _req('DELETE', '/api/parents/$parentId/remove_child/$academicId/');

  // ─── المواد ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> getSubjects() => _req('GET', '/api/subjects/');
  static Future<Map<String, dynamic>> createSubject(Map<String, dynamic> data) => _req('POST', '/api/subjects/', data);
  static Future<Map<String, dynamic>> updateSubject(int id, Map<String, dynamic> data) => _req('PUT', '/api/subjects/$id/', data);
  static Future<Map<String, dynamic>> deleteSubject(int id) => _req('DELETE', '/api/subjects/$id/');
}
