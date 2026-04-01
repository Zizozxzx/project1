import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class AIService {
  // محتوى الصفحة الحالية (يُحدَّث من BookScreen)
  static String currentPageContent = '';

  static String _extractText(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Future<String> _ask({
    required String text,
    required String subject,
    required String grade,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.backendBaseUrl}/api/ai/explain/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text, 'subject': subject, 'grade': grade}),
          )
          .timeout(const Duration(seconds: 35));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['result'] as String;
      } else {
        if (kDebugMode) debugPrint('AI error: ${res.body}');
        return 'حدث خطأ في الاتصال بالذكاء الاصطناعي (${res.statusCode})';
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AI Error: $e');
      return 'تعذر الاتصال بالذكاء الاصطناعي. تحقق من الإنترنت وأعد المحاولة.';
    }
  }

  /// شرح نص محدد من الكتاب
  static Future<String> explainText(
    String selectedText, {
    String subject = 'الرياضيات',
    String grade = 'التاسع',
  }) async {
    final pageContext = currentPageContent.isNotEmpty
        ? 'سياق الصفحة:\n${_extractText(currentPageContent).substring(0, _extractText(currentPageContent).length.clamp(0, 1000))}\n\nالنص المحدد:\n$selectedText'
        : selectedText;
    return _ask(text: pageContext, subject: subject, grade: grade);
  }

  /// شرح الصفحة الكاملة
  static Future<String> explainFullPage(
    String pageHtml, {
    String subject = 'الرياضيات',
    String grade = 'التاسع',
  }) async {
    final text = _extractText(pageHtml);
    final truncated = text.length > 3000 ? text.substring(0, 3000) : text;
    return _ask(text: truncated, subject: subject, grade: grade);
  }
}
