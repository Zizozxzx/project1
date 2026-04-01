import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config/app_config.dart';

/// شاشة إعدادات السيرفر - تغيير الـ IP أو الرابط من داخل التطبيق
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _controller = TextEditingController();
  bool _testing = false;
  bool _saving = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller.text = AppConfig.backendBaseUrl;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() {
        _testResult = 'الرجاء إدخال رابط السيرفر';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      String testUrl = url;
      if (testUrl.endsWith('/')) testUrl = testUrl.substring(0, testUrl.length - 1);

      final res = await http
          .get(Uri.parse('$testUrl/api/subjects/'))
          .timeout(const Duration(seconds: 8));

      if (mounted) {
        setState(() {
          _testing = false;
          if (res.statusCode == 200) {
            _testResult = '✅ الاتصال ناجح! السيرفر يستجيب بشكل صحيح.';
            _testSuccess = true;
          } else {
            _testResult = '⚠️ السيرفر استجاب لكن بكود ${res.statusCode}. تأكد من صحة الرابط.';
            _testSuccess = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testing = false;
          _testResult = '❌ فشل الاتصال. تأكد من:\n• أن السيرفر يعمل\n• أن الجهاز متصل بنفس الشبكة\n• صحة عنوان IP والمنفذ';
          _testSuccess = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رابط السيرفر')),
      );
      return;
    }

    setState(() => _saving = true);
    await AppConfig.setBackendBaseUrl(url);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حفظ الإعدادات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _resetToDefault() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إعادة الضبط'),
        content: const Text('هل تريد إعادة الرابط إلى القيمة الافتراضية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppConfig.resetToDefault();
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _controller.text = AppConfig.backendBaseUrl;
                  _testResult = null;
                });
              }
            },
            child: const Text('إعادة الضبط'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات السيرفر'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'إعادة الضبط',
            onPressed: _resetToDefault,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة الشرح
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'كيفية الاتصال بالسيرفر',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• للشبكة المحلية (Wi-Fi): أدخل IP جهاز السيرفر\n'
                      '  مثال: http://192.168.1.100:8000\n\n'
                      '• للإنترنت: أدخل رابط الدومين\n'
                      '  مثال: https://adres.example.com\n\n'
                      '• تأكد أن جهازك والسيرفر على نفس الشبكة',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'رابط السيرفر',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // حقل الإدخال
              TextField(
                controller: _controller,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: 'http://192.168.x.x:8000',
                  hintTextDirection: TextDirection.ltr,
                  prefixIcon: const Icon(Icons.dns),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _controller.clear(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // أمثلة سريعة
              Wrap(
                spacing: 8,
                children: [
                  _QuickChip(
                    label: 'localhost:8000',
                    onTap: () => _controller.text = 'http://10.0.2.2:8000',
                  ),
                  _QuickChip(
                    label: '192.168.1.x',
                    onTap: () => _controller.text = 'http://192.168.1.',
                  ),
                  _QuickChip(
                    label: '192.168.0.x',
                    onTap: () => _controller.text = 'http://192.168.0.',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // نتيجة الاختبار
              if (_testResult != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _testSuccess
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _testSuccess
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      color: _testSuccess
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),

              // أزرار
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testing ? null : _testConnection,
                      icon: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_find),
                      label: Text(_testing ? 'جاري الاختبار...' : 'اختبار الاتصال'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveSettings,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'جاري الحفظ...' : 'حفظ'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // الإعداد الحالي
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الإعداد الحالي:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConfig.backendBaseUrl,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.blueGrey,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
