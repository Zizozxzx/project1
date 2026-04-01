import 'package:flutter/material.dart';
import '../../core/account_type_screen.dart';
import 'teacher_class_screen.dart';

class TeacherDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> teacher;

  const TeacherDashboardScreen({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    final classes = teacher['classes'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الأستاذ'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
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
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AccountTypeScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text('خروج'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة الأستاذ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Colors.orange.withValues(alpha: 0.1),
                      child: const Icon(Icons.school,
                          size: 30, color: Colors.orange),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(teacher['full_name'] ?? 'أستاذ',
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'معلم ${teacher['subject'] ?? ''} • اليمن',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'الرقم الوظيفي: ${teacher['teacher_id'] ?? ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text('الصفوف الدراسية',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),

            if (classes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد صفوف مسجلة'),
                ),
              )
            else
              ...classes.map((cls) {
                final c = cls as Map;
                return _ClassCard(
                  classData: Map<String, dynamic>.from(c),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherClassScreen(
                          classId: c['id']?.toString() ?? '',
                          className: c['name']?.toString() ?? 'الصف',
                        ),
                      ),
                    );
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  final VoidCallback onTap;

  const _ClassCard({required this.classData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeRate = (classData['active_rate'] as num?)?.toDouble() ?? 0.0;
    final pct = (activeRate * 100).round();
    final count = classData['students_count'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.class_, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(classData['name'] ?? 'الصف',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text('$pct٪',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: activeRate >= 0.7
                              ? Colors.green
                              : Colors.orange)),
                ],
              ),
              const SizedBox(height: 8),
              Text('عدد الطلاب: $count',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: activeRate,
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 4),
              Text('نسبة النشاط: $pct٪',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
