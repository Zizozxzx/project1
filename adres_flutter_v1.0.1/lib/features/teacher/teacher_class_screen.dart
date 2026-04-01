import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import 'teacher_student_report_screen.dart';

class TeacherClassScreen extends StatefulWidget {
  final String classId;
  final String className;

  const TeacherClassScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<TeacherClassScreen> createState() => _TeacherClassScreenState();
}

class _TeacherClassScreenState extends State<TeacherClassScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    final data = await ApiService.getClassStudents(widget.classId);
    if (mounted) setState(() {
      _students = data;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_filter == 'all') return _students;
    return _students.where((s) => s['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final active = _students.where((s) => s['status'] == 'active').length;
    final medium = _students.where((s) => s['status'] == 'medium').length;
    final needs = _students.where((s) => s['status'] == 'needs_attention').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // إحصائيات سريعة
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _StatChip(
                        label: 'نشط',
                        count: active,
                        color: Colors.green,
                        selected: _filter == 'active',
                        onTap: () => setState(() =>
                            _filter = _filter == 'active' ? 'all' : 'active'),
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'متوسط',
                        count: medium,
                        color: Colors.orange,
                        selected: _filter == 'medium',
                        onTap: () => setState(() =>
                            _filter = _filter == 'medium' ? 'all' : 'medium'),
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'يحتاج متابعة',
                        count: needs,
                        color: Colors.red,
                        selected: _filter == 'needs_attention',
                        onTap: () => setState(() =>
                            _filter = _filter == 'needs_attention'
                                ? 'all'
                                : 'needs_attention'),
                      ),
                    ],
                  ),
                ),

                // قائمة الطلاب
                Expanded(
                  child: _filteredStudents.isEmpty
                      ? const Center(child: Text('لا يوجد طلاب'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (_, i) {
                            final student = _filteredStudents[i];
                            return _StudentTile(
                              student: student,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeacherStudentReportScreen(
                                      student: student,
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

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onTap;

  const _StudentTile({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = student['status'] as String? ?? 'medium';
    final progress = (student['progress_percent'] as num?)?.toDouble() ?? 0.0;
    final pct = (progress * 100).round();

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'active':
        statusColor = Colors.green;
        statusText = 'نشط';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'needs_attention':
        statusColor = Colors.red;
        statusText = 'يحتاج متابعة';
        statusIcon = Icons.warning_amber_outlined;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'متوسط';
        statusIcon = Icons.timelapse;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(student['full_name'] as String? ?? 'طالب'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(student['last_activity'] as String? ?? ''),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              borderRadius: BorderRadius.circular(4),
              color: statusColor,
              backgroundColor: statusColor.withValues(alpha: 0.15),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$pct٪',
                style: TextStyle(
                    color: statusColor, fontWeight: FontWeight.bold)),
            Text(statusText,
                style: TextStyle(color: statusColor, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
