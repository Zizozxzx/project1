import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/widgets.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});
  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  List<dynamic> _teachers = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await AdminApi.getTeachers();
    if (res['ok'] == true) {
      final data = res['data'];
      setState(() { _teachers = data is List ? data : []; });
    }
    setState(() => _loading = false);
  }

  void _openForm([Map<String, dynamic>? teacher]) {
    final teacherId = TextEditingController(text: teacher?['teacher_id'] ?? '');
    final fullName  = TextEditingController(text: teacher?['full_name'] ?? '');
    final subject   = TextEditingController(text: teacher?['subject'] ?? '');
    final password  = TextEditingController();
    final classCtrl = TextEditingController();
    final isEdit = teacher != null;

    // شعب المعلم الحالية (قابلة للتعديل)
    final List<String> classes = isEdit
        ? ((teacher['classes'] as List?) ?? [])
            .map((c) => c['class_name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList()
        : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'تعديل المعلم' : 'إضافة معلم', style: kTitle),
                const SizedBox(height: 12),
                if (!isEdit) kField(teacherId, 'الرقم الوظيفي'),
                kField(fullName, 'الاسم الكامل'),
                kField(subject, 'المادة'),
                kField(password, isEdit ? 'كلمة مرور جديدة (اتركها فارغة للإبقاء)' : 'كلمة المرور', obscure: true),
                const SizedBox(height: 8),
                // ─── قسم الشعب ───
                Text('الشعب الدراسية', style: kBody.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: TextField(
                    controller: classCtrl,
                    style: const TextStyle(fontFamily: 'Cairo'),
                    decoration: InputDecoration(
                      hintText: 'مثال: التاسع-أ',
                      hintStyle: const TextStyle(fontFamily: 'Cairo'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  )),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
                    onPressed: () {
                      final v = classCtrl.text.trim();
                      if (v.isNotEmpty && !classes.contains(v)) {
                        setS(() { classes.add(v); classCtrl.clear(); });
                      }
                    },
                    child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ]),
                if (classes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: classes.map((c) => Chip(
                      label: Text(c, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setS(() => classes.remove(c)),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                kBtn(isEdit ? 'حفظ التعديل' : 'إضافة', () async {
                  final body = <String, dynamic>{
                    if (!isEdit) 'teacher_id': teacherId.text.trim(),
                    'full_name': fullName.text.trim(),
                    'subject': subject.text.trim(),
                    if (password.text.trim().isNotEmpty) 'password': password.text.trim(),
                  };
                  final res = isEdit
                      ? await AdminApi.updateTeacher(teacher!['teacher_id'], body)
                      : await AdminApi.createTeacher(body);
                  if (!mounted) return;
                  if (res['ok'] == true) {
                    final tid = isEdit ? teacher!['teacher_id'] : teacherId.text.trim();
                    // إضافة الشعب الجديدة عبر add_class
                    final existingNames = isEdit
                        ? ((teacher!['classes'] as List?) ?? [])
                            .map((c) => c is Map ? c['class_name']?.toString() ?? '' : c.toString())
                            .toSet()
                        : <String>{};
                    for (final cls in classes) {
                      if (!existingNames.contains(cls)) {
                        final classId = 'class_${cls.replaceAll(' ', '_')}';
                        await AdminApi.addClassToTeacher(tid, {'class_id': classId, 'class_name': cls});
                      }
                    }
                    Navigator.pop(context);
                    showMsg(context, isEdit ? 'تعديل معلم: ${fullName.text.trim()}' : 'إضافة معلم: ${fullName.text.trim()}', type: isEdit ? 'تعديل' : 'إضافة');
                    _load();
                  } else {
                    Navigator.pop(context);
                    showMsg(context, res['error'] ?? 'خطأ', error: true, type: 'خطأ');
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> t) async {
    if (!await confirmDelete(context, t['full_name'])) return;
    final res = await AdminApi.deleteTeacher(t['teacher_id']);
    if (!mounted) return;
    if (res['ok'] == true) { showMsg(context, 'حذف معلم: ${t['full_name']}', type: 'حذف'); _load(); }
    else showMsg(context, res['error'] ?? 'خطأ', error: true, type: 'خطأ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المعلمون', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: kPrimary, foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? loadingWidget()
          : _teachers.isEmpty
              ? const Center(child: Text('لا يوجد معلمون', style: TextStyle(fontFamily: 'Cairo')))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _teachers.length,
                  itemBuilder: (_, i) {
                    final t = _teachers[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(backgroundColor: const Color(0xFF43A047), child: Text(t['full_name'][0], style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'))),
                        title: Text(t['full_name'], style: kTitle),
                        subtitle: Text('${t['teacher_id']} | ${t['subject'] ?? ''}', style: kBody),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: kPrimary), onPressed: () => _openForm(t)),
                          deleteBtn(() => _delete(t)),
                          const Icon(Icons.expand_more),
                        ]),
                        children: [
                          _TeacherStudentsSection(teacher: t, onRefresh: _load),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ─── قسم طلاب المعلم ─────────────────────────────────────────────────────────
class _TeacherStudentsSection extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final VoidCallback onRefresh;
  const _TeacherStudentsSection({required this.teacher, required this.onRefresh});

  void _addStudent(BuildContext context) {
    final academicId = TextEditingController();
    // استخراج أسماء الشعب بغض النظر عن الصيغة (String أو Map)
    final rawClasses = (teacher['classes'] as List?) ?? [];
    final classNames = rawClasses.map((c) {
      if (c is Map) return c['class_name']?.toString() ?? '';
      return c.toString();
    }).where((s) => s.isNotEmpty).toList();
    String? selectedClass = classNames.isNotEmpty ? classNames[0] : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('إضافة طالب للمعلم', style: TextStyle(fontFamily: 'Cairo')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            kField(academicId, 'الرقم الأكاديمي للطالب', type: TextInputType.number),
            if (classNames.isEmpty)
              const Text('لا توجد شعب مسجلة لهذا المعلم', style: TextStyle(fontFamily: 'Cairo', color: kDanger))
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: DropdownButtonFormField<String>(
                  value: selectedClass,
                  decoration: InputDecoration(
                    labelText: 'الشعبة',
                    labelStyle: const TextStyle(fontFamily: 'Cairo'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: classNames.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(fontFamily: 'Cairo')),
                  )).toList(),
                  onChanged: (v) => setS(() => selectedClass = v),
                ),
              ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
            if (classNames.isNotEmpty)
              TextButton(
                onPressed: () async {
                  final res = await AdminApi.addStudentToTeacher(
                    teacher['teacher_id'], academicId.text.trim(), selectedClass ?? '');
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (res['ok'] == true) { showMsg(context, 'إضافة طالب للمعلم: ${teacher['full_name']}', type: 'إضافة'); onRefresh(); }
                  else showMsg(context, res['error'] ?? 'خطأ', error: true, type: 'خطأ');
                },
                child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo', color: kPrimary)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = (teacher['students'] as List?) ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('الطلاب (${students.length})', style: kBody.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addStudent(context),
              icon: const Icon(Icons.person_add, size: 16, color: kPrimary),
              label: const Text('إضافة طالب', style: TextStyle(fontFamily: 'Cairo', color: kPrimary, fontSize: 12)),
            ),
          ]),
          ...students.map((s) => ListTile(
            dense: true,
            title: Text(s['full_name'] ?? '', style: kBody),
            subtitle: Text('${s['academic_id']} | ${s['class_name'] ?? ''}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: kDanger, size: 20),
              onPressed: () async {
                final res = await AdminApi.removeStudentFromTeacher(teacher['teacher_id'], s['academic_id']);
                if (!context.mounted) return;
                if (res['ok'] == true) { showMsg(context, 'حذف طالب من المعلم: ${teacher['full_name']}', type: 'حذف'); onRefresh(); }
                else showMsg(context, res['error'] ?? 'خطأ', error: true, type: 'خطأ');
              },
            ),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
