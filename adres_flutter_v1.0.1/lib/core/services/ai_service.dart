import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AIService {
  static const String _apiKey = 'YOUR_GROQ_API_KEY_HERE';
  static const String _model = 'llama-3.3-70b-versatile';
  static const String _url = 'https://api.groq.com/openai/v1/chat/completions';

  // محتوى الصفحة الحالية (يُحدَّث من BookScreen)
  static String currentPageContent = '';

  static Future<String> _ask(String systemPrompt, String userMessage) async {
    try {
      final res = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        if (kDebugMode) debugPrint('Groq error: ${res.body}');
        return 'حدث خطأ في الاتصال بالذكاء الاصطناعي (${res.statusCode})';
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AI Error: $e');
      return 'تعذر الاتصال بالذكاء الاصطناعي. تحقق من الإنترنت وأعد المحاولة.';
    }
  }

  static String _extractText(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// شرح نص محدد من الكتاب
  static Future<String> explainText(String selectedText) async {
    final pageContext = currentPageContent.isNotEmpty
        ? 'محتوى الصفحة الحالية:\n${_extractText(currentPageContent).substring(0, _extractText(currentPageContent).length.clamp(0, 2000))}'
        : '';

    final system = '''أنت معلم رياضيات متخصص لطلاب الصف التاسع في اليمن.
${pageContext.isNotEmpty ? 'لديك سياق الصفحة التالية من الكتاب المدرسي:\n$pageContext' : ''}
أجب بالعربية الفصحى البسيطة، بشكل منظم ومختصر.''';

    final user = '''الطالب حدد النص التالي من الكتاب ويريد شرحه:
"$selectedText"

اشرح هذا النص بطريقة مبسطة مع أمثلة عملية إن أمكن، واذكر النقاط المهمة.''';

    return _ask(system, user);
  }

  /// شرح الصفحة الكاملة
  static Future<String> explainFullPage(String pageHtml) async {
    final text = _extractText(pageHtml);
    final truncated = text.length > 3000 ? text.substring(0, 3000) : text;

    const system = '''أنت معلم رياضيات متخصص لطلاب الصف التاسع في اليمن.
أجب بالعربية الفصحى البسيطة، بشكل منظم ومختصر.''';

    final user = '''محتوى الصفحة من كتاب الرياضيات:
"$truncated"

قدم:
1. ملخصاً مختصراً للمحتوى
2. المفاهيم الأساسية
3. نقاط يجب على الطالب حفظها''';

    return _ask(system, user);
  }
}
