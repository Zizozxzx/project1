import 'package:flutter/material.dart';
import '../../core/services/parent_local_service.dart';
import '../../core/services/api_service.dart';
import '../../core/account_type_screen.dart';
import 'parent_dashboard_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  late Map<String, dynamic> _parent;
  List<Map<String, dynamic>> _children = [];
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _parent = ParentLocalService.getParent();
    _children = ParentLocalService.getChildren();
  }

  Future<void> _addChild() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة ابن جديد'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'الرقم الأكاديمي للطالب',
            hintText: 'مثال: 78246',
            prefixIcon: Icon(Icons.badge_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = controller.text.trim();
              Navigator.pop(context);
              if (id.isNotEmpty) await _fetchAndAddChild(id);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAndAddChild(String academicId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final child = await ApiService.addChildToParent(
        _parent['parentId'] ?? '', academicId);

    if (!mounted) return;
    Navigator.pop(context); // إغلاق مؤشر التحميل

    if (child != null) {
      ParentLocalService.addChild(child);
      setState(() => _children = ParentLocalService.getChildren());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة ${child['full_name']} بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرقم الأكاديمي غير موجود'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshChildren() async {
    setState(() => _refreshing = true);
    // محاولة تحديث البيانات من السيرفر
    for (final child in _children) {
      final id = child['academic_id'] as String? ?? '';
      if (id.isNotEmpty) {
        final updated = await ApiService.addChildToParent(
            _parent['parentId'] ?? '', id);
        if (updated != null) {
          ParentLocalService.addChild(updated);
        }
      }
    }
    if (mounted) {
      setState(() {
        _children = ParentLocalService.getChildren();
        _refreshing = false;
      });
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              ParentLocalService.clearParent();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AccountTypeScreen()),
                (route) => false,
              );
            },
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة ولي الأمر'),
        automaticallyImplyLeading: false,
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث الدرجات',
            onPressed: _refreshChildren,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // بطاقة ولي الأمر
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Colors.green.withValues(alpha: 0.1),
                      child: const Icon(Icons.family_restroom,
                          size: 30, color: Colors.green),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_parent['fullName'] ?? 'ولي الأمر',
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'عدد الأبناء: ${_children.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // عنوان الأبناء
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('أبنائي',
                    style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addChild,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة ابن'),
                ),
              ],
            ),
          ),

          // قائمة الأبناء
          Expanded(
            child: _children.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'لم تقم بإضافة أبناء بعد',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addChild,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة ابن'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _children.length,
                    itemBuilder: (_, i) {
                      final child = _children[i];
                      return _ChildCard(
                        child: child,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ParentDashboardScreen(
                                child: child,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final VoidCallback onTap;

  const _ChildCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.school,
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(child['full_name'] ?? 'طالب'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${child['grade_level'] ?? ''} • ${child['class_name'] ?? ''}'),
            Text('الرقم: ${child['academic_id'] ?? ''}',
                style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
