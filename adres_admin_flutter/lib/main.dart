import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/widgets.dart';
import 'core/log_service.dart';
import 'features/students/students_screen.dart';
import 'features/teachers/teachers_screen.dart';
import 'features/parents/parents_screen.dart';
import 'features/subjects/subjects_screen.dart';

const _kPassKey = 'admin_password';
const _kDefaultPass = '2004';

Future<String> _loadPassword() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kPassKey) ?? _kDefaultPass;
}

Future<void> _savePassword(String pass) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kPassKey, pass);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LogService.init();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ادرس - الإدارة',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
      ),
      home: const LoginScreen(),
      builder: (_, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    );
  }
}

// ─── شاشة تسجيل الدخول ───────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pass = TextEditingController();
  bool _obscure = true;

  Future<void> _login() async {
    final saved = await _loadPassword();
    if (_pass.text.trim() == saved) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      if (!mounted) return;
      showMsg(context, 'كلمة المرور غير صحيحة', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(child: Image.asset('assets/logo.jpg', width: 90, height: 90, fit: BoxFit.cover)),
              const SizedBox(height: 16),
              const Text('أدارة المدرسه', style: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: _pass,
                obscureText: _obscure,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  labelStyle: const TextStyle(fontFamily: 'Cairo'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 16),
              kBtn('دخول', () => _login()),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── الصفحة الرئيسية ─────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> _log = [];

  @override
  void initState() {
    super.initState();
    _log = LogService.getAll();
  }

  static void addLog(String type, String msg) {
    LogService.add(type, msg);
  }

  static const _items = [
    {'title': 'الطلاب',          'icon': Icons.school,         'color': Color(0xFF1E88E5)},
    {'title': 'المعلمون',        'icon': Icons.person,          'color': Color(0xFF43A047)},
    {'title': 'أولياء الأمور',   'icon': Icons.family_restroom, 'color': Color(0xFFFFA000)},
    {'title': 'المواد الدراسية', 'icon': Icons.menu_book,       'color': Color(0xFF8E24AA)},
  ];

  void _navigate(int index) {
    final screens = [
      const StudentsScreen(),
      const TeachersScreen(),
      const ParentsScreen(),
      const SubjectsScreen(),
    ];
    Navigator.push(context, MaterialPageRoute(builder: (_) => screens[index]))
        .then((_) => setState(() { _log = LogService.getAll(); }));
  }

  void _changePassword(BuildContext ctx) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirm = TextEditingController();
    Navigator.pop(ctx);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          kField(oldPass, 'كلمة المرور الحالية', obscure: true),
          kField(newPass, 'كلمة المرور الجديدة', obscure: true),
          kField(confirm, 'تأكيد كلمة المرور', obscure: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          TextButton(
            onPressed: () async {
              final saved = await _loadPassword();
              if (oldPass.text.trim() != saved) {
                if (!mounted) return;
                showMsg(context, 'كلمة المرور الحالية غير صحيحة', error: true);
                return;
              }
              if (newPass.text.trim().isEmpty) {
                showMsg(context, 'كلمة المرور الجديدة فارغة', error: true);
                return;
              }
              if (newPass.text.trim() != confirm.text.trim()) {
                showMsg(context, 'كلمة المرور غير متطابقة', error: true);
                return;
              }
              await _savePassword(newPass.text.trim());
              if (!mounted) return;
              Navigator.pop(context);
              showMsg(context, 'تم تغيير كلمة المرور بنجاح ✓');
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', color: kPrimary)),
          ),
        ],
      ),
    );
  }

  // أيقونة ولون حسب نوع العملية
  static IconData _typeIcon(String type) {
    switch (type) {
      case 'إضافة':  return Icons.add_circle_outline;
      case 'تعديل':  return Icons.edit_outlined;
      case 'حذف':    return Icons.delete_outline;
      default:       return Icons.info_outline;
    }
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'إضافة':  return Colors.green;
      case 'تعديل':  return kPrimary;
      case 'حذف':    return kDanger;
      default:       return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('أدارة المدرسه - ادرس', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        backgroundColor: kPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: kPrimary,
                child: Column(children: [
                  ClipOval(child: Image.asset('assets/logo.jpg', width: 64, height: 64, fit: BoxFit.cover)),
                  const SizedBox(height: 8),
                  const Text('أدارة المدرسه', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: kPrimary),
                title: const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo')),
                onTap: () => _changePassword(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: kDanger),
                title: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo', color: kDanger)),
                onTap: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر القسم', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2,
              ),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                return InkWell(
                  onTap: () => _navigate(i),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (item['color'] as Color).withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item['icon'] as IconData, size: 48, color: item['color'] as Color),
                        const SizedBox(height: 10),
                        Text(item['title'] as String, style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold, color: item['color'] as Color)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(children: [
              const Text('سجل العمليات', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_log.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() { LogService.clear(); _log = []; }),
                  child: const Text('مسح الكل', style: TextStyle(fontFamily: 'Cairo', color: kDanger, fontSize: 12)),
                ),
            ]),
            const SizedBox(height: 6),
            Expanded(
              child: _log.isEmpty
                  ? const Center(child: Text('لا توجد عمليات بعد', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _log.length,
                      itemBuilder: (_, i) {
                        final entry = _log[i];
                        final type  = entry['type'] ?? '';
                        final color = _typeColor(type);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: color.withOpacity(0.15),
                              child: Icon(_typeIcon(type), size: 16, color: color),
                            ),
                            title: Text(entry['msg'] ?? '', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                            trailing: Text(entry['time'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey[600])),
                            subtitle: Text(type, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
