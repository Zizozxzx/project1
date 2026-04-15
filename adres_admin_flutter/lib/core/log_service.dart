import 'package:hive_flutter/hive_flutter.dart';

/// خدمة السجل المحلي - يحفظ آخر 100 عملية في Hive
class LogService {
  static const _boxName = 'admin_log';
  static const _maxEntries = 100;

  static Box get _box => Hive.box(_boxName);

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static void add(String type, String msg) {
    final now = DateTime.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2,'0')}';
    final date = '${now.day}/${now.month}/${now.year}';
    final entries = getAll();
    entries.insert(0, {'time': time, 'date': date, 'type': type, 'msg': msg});
    if (entries.length > _maxEntries) entries.removeLast();
    _box.put('log', entries);
  }

  static List<Map<String, String>> getAll() {
    final raw = _box.get('log');
    if (raw == null) return [];
    return List<Map<String, String>>.from(
      (raw as List).map((e) => Map<String, String>.from(e as Map)),
    );
  }

  static void clear() => _box.put('log', []);
}
