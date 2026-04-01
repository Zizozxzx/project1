import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/parent_local_service.dart';
import 'parent_home_screen.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _parentIdController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _parentIdController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final id = _parentIdController.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'الرجاء إدخال رقم ولي الأمر');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final parent = await ApiService.loginParent(id);

    if (!mounted) return;
    setState(() => _loading = false);

    if (parent != null) {
      ParentLocalService.saveParent(
        parentId: id,
        fullName: parent['full_name'] ?? 'ولي الأمر',
      );

      // حفظ الأبناء إذا كانوا موجودين
      final children = parent['children'];
      if (children is List) {
        for (final child in children) {
          ParentLocalService.addChild(Map<String, dynamic>.from(child as Map));
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParentHomeScreen()),
      );
    } else {
      setState(() =>
          _error = 'رقم ولي الأمر غير موجود.\nيرجى مراجعة المدرسة للتسجيل.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('دخول ولي الأمر'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  Text('مرحبًا بك 👋',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  Text(
                    'أدخل رقمك الخاص لمتابعة تقدم أبنائك الدراسي.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _parentIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'رقم ولي الأمر',
                      hintText: 'مثال: 78246',
                      prefixIcon: Icon(Icons.family_restroom),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Text('متابعة'),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
