import 'package:hive/hive.dart';

/// خدمة حفظ بيانات ولي الأمر محلياً
class ParentLocalService {
  static Box get _box => Hive.box('studentBox');

  static void saveParent({
    required String parentId,
    required String fullName,
  }) {
    _box.put('parentId', parentId);
    _box.put('parentFullName', fullName);
  }

  static bool hasParent() => _box.containsKey('parentId');

  static Map<String, dynamic> getParent() {
    return {
      'parentId': _box.get('parentId', defaultValue: ''),
      'fullName': _box.get('parentFullName', defaultValue: ''),
    };
  }

  /// حفظ الأبناء المضافين
  static void saveChildren(List<Map<String, dynamic>> children) {
    _box.put('parentChildren', children);
  }

  /// إضافة ابن جديد
  static void addChild(Map<String, dynamic> child) {
    final current = getChildren();
    // تجنب التكرار
    final exists = current.any((c) => c['academic_id'] == child['academic_id']);
    if (!exists) {
      current.add(child);
      _box.put('parentChildren', current);
    }
  }

  /// جلب قائمة الأبناء
  static List<Map<String, dynamic>> getChildren() {
    final raw = _box.get('parentChildren');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  static void clearParent() {
    _box.deleteAll(['parentId', 'parentFullName', 'parentChildren']);
  }
}
