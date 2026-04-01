import 'package:hive/hive.dart';

/// خدمة حفظ التقدم الدراسي محلياً - نظام تقدم حقيقي
/// يعتمد على: الوقت الفعلي + عدد النقرات/التفاعلات + الصفحات المفتوحة بالفعل
class ProgressLocalService {
  static Box get _box => Hive.box('studentBox');
  static String _key(String bookId) => 'progress_$bookId';

  /// الحد الأدنى من الثواني لاعتبار الصفحة مقروءة
  static const int _minSecondsPerPage = 10;

  /// ==========================================
  /// التقدم الحقيقي = f(وقت + نقرات + صفحات)
  /// ==========================================
  /// الصيغة:
  ///   timeScore    = min(totalTimeSeconds / (totalPages * minSecondsPerPage), 1.0)
  ///   pagesScore   = uniquePagesOpened / totalPages
  ///   clickScore   = min(totalClicks / (totalPages * 5), 1.0)  [5 نقرات معتدلة/صفحة]
  ///   finalPercent = (timeScore * 0.4 + pagesScore * 0.4 + clickScore * 0.2)
  static double _computeProgress({
    required int totalTimeSeconds,
    required int uniquePagesCount,
    required int totalClicks,
    required int totalPages,
  }) {
    if (totalPages <= 0) return 0.0;

    // درجة الوقت (40%)
    final double timeScore = (totalTimeSeconds /
            (totalPages * _minSecondsPerPage.toDouble()))
        .clamp(0.0, 1.0);

    // درجة الصفحات المفتوحة (40%)
    final double pagesScore =
        (uniquePagesCount / totalPages).clamp(0.0, 1.0);

    // درجة التفاعل (20%)
    final double clickScore =
        (totalClicks / (totalPages * 5.0)).clamp(0.0, 1.0);

    return (timeScore * 0.4 + pagesScore * 0.4 + clickScore * 0.2)
        .clamp(0.0, 1.0);
  }

  /// إضافة ثواني قراءة حقيقية للصفحة الحالية
  static void addReadingTime({
    required String bookId,
    required int seconds,
    int? totalPages,
  }) {
    if (seconds <= 0) return;
    final data = getProgress(bookId);
    final int prev = (data['totalTimeSeconds'] as int? ?? 0);
    data['totalTimeSeconds'] = prev + seconds;
    data['totalPages'] = totalPages ?? (data['totalPages'] as int? ?? 192);
    _recalcAndSave(bookId, data);
  }

  /// تسجيل تفاعل (نقرة، سحب، ضغطة) في الصفحة
  static void addInteraction({
    required String bookId,
    int count = 1,
  }) {
    final data = getProgress(bookId);
    final int prev = (data['totalClicks'] as int? ?? 0);
    data['totalClicks'] = prev + count;
    _recalcAndSave(bookId, data);
  }

  /// تسجيل صفحة تم فتحها + تحديث آخر صفحة
  static void recordPageOpened({
    required String bookId,
    required int page,
    int? totalPages,
  }) {
    final data = getProgress(bookId);

    // قائمة الصفحات المفتوحة الفريدة
    final List<int> opened =
        List<int>.from(data['openedPages'] as List? ?? []);
    if (!opened.contains(page)) {
      opened.add(page);
    }
    data['openedPages'] = opened;
    data['lastPage'] = page;
    data['totalPages'] = totalPages ?? (data['totalPages'] as int? ?? 192);
    _recalcAndSave(bookId, data);
  }

  /// الدالة القديمة للتوافق مع الكود السابق
  static void updateProgress({
    required String bookId,
    int addedMinutes = 0,
    int addedPages = 0,
    int addedInteraction = 0,
    int? lastPage,
    int? totalPages,
  }) {
    // تحويل الدقائق إلى ثواني
    addReadingTime(
      bookId: bookId,
      seconds: addedMinutes * 60,
      totalPages: totalPages,
    );
    if (addedInteraction > 0) {
      addInteraction(bookId: bookId, count: addedInteraction);
    }
    if (lastPage != null) {
      recordPageOpened(
          bookId: bookId, page: lastPage, totalPages: totalPages);
    }
  }

  /// إعادة حساب التقدم وحفظه
  static void _recalcAndSave(String bookId, Map<String, dynamic> data) {
    final int totalPages = data['totalPages'] as int? ?? 192;
    final int totalTimeSeconds = data['totalTimeSeconds'] as int? ?? 0;
    final int totalClicks = data['totalClicks'] as int? ?? 0;
    final List<int> openedPages =
        List<int>.from(data['openedPages'] as List? ?? []);

    data['progressPercent'] = _computeProgress(
      totalTimeSeconds: totalTimeSeconds,
      uniquePagesCount: openedPages.length,
      totalClicks: totalClicks,
      totalPages: totalPages,
    );
    data['pagesReadCount'] = openedPages.length;
    data['totalTimeMinutes'] = totalTimeSeconds ~/ 60;
    data['lastActivityAt'] = DateTime.now().toIso8601String();
    data['isSynced'] = false;

    _box.put(_key(bookId), data);
  }

  /// جلب التقدم (مع قيم افتراضية)
  static Map<String, dynamic> getProgress(String bookId) {
    final raw = _box.get(_key(bookId));
    if (raw == null) {
      return {
        'bookId': bookId,
        'totalTimeSeconds': 0,
        'totalTimeMinutes': 0,
        'totalClicks': 0,
        'pagesReadCount': 0,
        'openedPages': <int>[],
        'lastPage': 1,
        'totalPages': 192,
        'progressPercent': 0.0,
        'lastActivityAt': null,
        'isSynced': true,
      };
    }

    final d = Map<String, dynamic>.from(raw as Map);
    // توافق مع البيانات القديمة: تحويل الدقائق إلى ثواني
    if (!d.containsKey('totalTimeSeconds') &&
        d.containsKey('totalTimeMinutes')) {
      d['totalTimeSeconds'] =
          ((d['totalTimeMinutes'] as int? ?? 0) * 60);
    }
    d.putIfAbsent('totalTimeSeconds', () => 0);
    d.putIfAbsent('totalClicks', () => 0);
    d.putIfAbsent('openedPages', () => <int>[]);
    return d;
  }

  static void markSynced(String bookId) {
    final data = getProgress(bookId);
    data['isSynced'] = true;
    _box.put(_key(bookId), data);
  }

  static List<Map<String, dynamic>> getUnsyncedProgress() {
    final results = <Map<String, dynamic>>[];
    for (final key in _box.keys) {
      if (key.toString().startsWith('progress_')) {
        final raw = _box.get(key);
        if (raw is Map) {
          final data = Map<String, dynamic>.from(raw);
          if (data['isSynced'] == false) {
            results.add(data);
          }
        }
      }
    }
    return results;
  }

  static void clearProgress(String bookId) {
    _box.delete(_key(bookId));
  }

  /// الحصول على آخر كتاب تم القراءة فيه
  static Map<String, dynamic>? getLastReadBook() {
    Map<String, dynamic>? last;
    DateTime? lastTime;

    for (final key in _box.keys) {
      if (key.toString().startsWith('progress_')) {
        final raw = _box.get(key);
        if (raw is Map) {
          final data = Map<String, dynamic>.from(raw);
          final timeStr = data['lastActivityAt'] as String?;
          if (timeStr != null) {
            final t = DateTime.tryParse(timeStr);
            if (t != null &&
                (lastTime == null || t.isAfter(lastTime))) {
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
