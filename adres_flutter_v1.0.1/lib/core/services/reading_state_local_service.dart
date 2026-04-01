import 'package:hive/hive.dart';

/// خدمة حفظ حالة القراءة محلياً
class ReadingStateLocalService {
  static Box get _box => Hive.box('studentBox');

  static String _key(String bookId) => 'reading_$bookId';

  static void updateReadingState({
    required String bookId,
    required int lastPage,
    List<int>? openedPages,
    String? subjectName,
    String? termName,
  }) {
    final data = getReadingState(bookId);
    final List<int> pages = openedPages ?? List<int>.from(data['openedPages'] as List? ?? []);

    final updated = {
      'bookId': bookId,
      'lastPage': lastPage,
      'openedPages': pages,
      'lastOpenedAt': DateTime.now().toIso8601String(),
      'subjectName': subjectName ?? data['subjectName'] ?? '',
      'termName': termName ?? data['termName'] ?? '',
    };

    _box.put(_key(bookId), updated);
  }

  static void addOpenedPage({required String bookId, required int page}) {
    final data = getReadingState(bookId);
    final List<int> pages = List<int>.from(data['openedPages'] as List? ?? []);
    if (!pages.contains(page)) pages.add(page);
    updateReadingState(bookId: bookId, lastPage: page, openedPages: pages);
  }

  static Map<String, dynamic> getReadingState(String bookId) {
    final raw = _box.get(_key(bookId));
    if (raw == null) {
      return {
        'bookId': bookId,
        'lastPage': 1,
        'openedPages': <int>[],
        'lastOpenedAt': null,
        'subjectName': '',
        'termName': '',
      };
    }
    return Map<String, dynamic>.from(raw as Map);
  }

  static void clearReadingState(String bookId) {
    _box.delete(_key(bookId));
  }

  /// جلب آخر حالة قراءة
  static Map<String, dynamic>? getLastReading() {
    Map<String, dynamic>? last;
    DateTime? lastTime;

    for (final key in _box.keys) {
      if (key.toString().startsWith('reading_')) {
        final raw = _box.get(key);
        if (raw is Map) {
          final data = Map<String, dynamic>.from(raw);
          final timeStr = data['lastOpenedAt'] as String?;
          if (timeStr != null) {
            final t = DateTime.tryParse(timeStr);
            if (t != null && (lastTime == null || t.isAfter(lastTime))) {
              lastTime = t;
              last = data;
            }
          }
        }
      }
    }
    return last;
  }
}
