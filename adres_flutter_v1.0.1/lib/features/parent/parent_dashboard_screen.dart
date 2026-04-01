import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class ParentDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> child;

  const ParentDashboardScreen({super.key, required this.child});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  List<Map<String, dynamic>> _progressList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _loading = true);
    final id = widget.child['academic_id'] as String? ?? '';
    final data = await ApiService.getStudentAllProgress(id);
    if (mounted) setState(() {
      _progressList = data;
      _loading = false;
    });
  }

  double _getOverallProgress() {
    if (_progressList.isEmpty) return 0;
    double total = 0;
    for (final p in _progressList) {
      total += (p['progress_percent'] as double? ?? 0.0);
    }
    return total / _progressList.length;
  }

  @override
  Widget build(BuildContext context) {
    final overall = _getOverallProgress();
    final pct = (overall * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text('تقدم ${widget.child['full_name'] ?? 'الطالب'}'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _loadProgress,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بطاقة الطالب
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            child: Icon(Icons.person, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.child['full_name'] ?? 'طالب',
                                    style: Theme.of(context).textTheme.bodyLarge),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.child['grade_level'] ?? ''} • ${widget.child['class_name'] ?? ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'الرقم الأكاديمي: ${widget.child['academic_id'] ?? ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // التقدم الإجمالي
                  Text('التقدم الإجمالي',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: overall,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 8),
                          Text('$pct٪ من المنهج الكلي',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // تقدم المواد
                  Text('تقدم المواد الدراسية',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  if (_progressList.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('لا توجد بيانات تقدم بعد'),
                      ),
                    )
                  else
                    ..._progressList.map((p) => _SubjectProgressCard(
                          subjectName: p['subject'] as String? ?? 'مادة',
                          progress: p['progress_percent'] as double? ?? 0.0,
                          lastPage: p['last_page'] as int? ?? 0,
                          totalPages: p['total_pages'] as int? ?? 192,
                          totalMinutes: p['total_time_minutes'] as int? ?? 0,
                          lastActivity: p['last_activity'] as String? ?? '',
                        )),
                ],
              ),
            ),
    );
  }
}

class _SubjectProgressCard extends StatelessWidget {
  final String subjectName;
  final double progress;
  final int lastPage;
  final int totalPages;
  final int totalMinutes;
  final String lastActivity;

  const _SubjectProgressCard({
    required this.subjectName,
    required this.progress,
    required this.lastPage,
    required this.totalPages,
    required this.totalMinutes,
    required this.lastActivity,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(subjectName,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('$pct٪',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: progress >= 0.7
                            ? Colors.green
                            : progress >= 0.5
                                ? Colors.orange
                                : Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.book_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('صفحة $lastPage من $totalPages',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 16),
                const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  hours > 0
                      ? '$hours ساعة و$minutes دقيقة'
                      : '$minutes دقيقة',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (lastActivity.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('آخر نشاط: $lastActivity',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
