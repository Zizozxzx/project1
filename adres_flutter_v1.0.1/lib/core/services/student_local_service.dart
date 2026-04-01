import 'package:hive/hive.dart';

/// خدمة حفظ بيانات الطالب محلياً
class StudentLocalService {
  static Box get _box => Hive.box('studentBox');

  static void saveStudent({
    required String studentId,
    required String academicId,
    required String fullName,
    required String gradeLevel,
    required String classId,
    String? className,
  }) {
    _box.put('studentId', studentId);
    _box.put('academicId', academicId);
    _box.put('fullName', fullName);
    _box.put('gradeLevel', gradeLevel);
    _box.put('classId', classId);
    if (className != null) _box.put('className', className);
  }

  static bool hasStudent() => _box.containsKey('studentId');

  static Map<String, dynamic> getStudent() {
    return {
      'studentId': _box.get('studentId', defaultValue: ''),
      'academicId': _box.get('academicId', defaultValue: ''),
      'fullName': _box.get('fullName', defaultValue: 'طالب'),
      'gradeLevel': _box.get('gradeLevel', defaultValue: ''),
      'classId': _box.get('classId', defaultValue: ''),
      'className': _box.get('className', defaultValue: ''),
    };
  }

  static void clearStudent() {
    _box.deleteAll([
      'studentId', 'academicId', 'fullName',
      'gradeLevel', 'classId', 'className',
    ]);
  }
}
