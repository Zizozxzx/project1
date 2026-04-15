import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/widgets.dart';

const _grades = [
  'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس',
  'السادس', 'السابع', 'الثامن', 'التاسع',
];

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<dynamic> _students = [];
  bool _loading = true;
  String? _selectedGrade = 'التاسع';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await AdminApi.getStudents();
    if (res['ok'] == true) {
      final data = res['data'];
      setState(() { _students = data is List ? data : []; });
    }
    setState(() => _loading = false);
  }

  List<dynamic> get _filtered {
    if (_selectedGrade == null) return _students;
    return _students.where((s) {
      final g = (s['grade_level'] ?? '').toString();
      return g == _selectedGrade || g.contains(_selectedGrade!);
    }).toList();
  }

  void _openForm([Map<String, dynamic>? student]) {
    final academicId = TextEditingController(text: student?['academic_id'] ?? '');
    final fullName   = TextEditingController(text: student?['full_name'] ?? '');
    final grade      = TextEditingController(text: student?['grade_level'] ?? _selectedGrade ?? '');
    final classId    = TextEditingController(text: student?['class_id'] ?? '');
    final className  = TextEditingController(text: student?['class_name'] ?? '');
    final password   = TextEditingController();
    final isEdit = student != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? 'تعديل الطالب' : 'إضافة طالب', style: kTitle),
              const SizedBox(height: 12),
              if (!isEdit) kField(academicId, 'الرقم الأكاديمي', type: TextInputType.number),
              kField(fullName, 'الاسم الكامل'),
              kField(grade, 'الصف الدراسي'),
              kField(classId, 'معرف الشعبة (مثال: class_9A)'),
              kField(className, 'اسم الشعبة (مثال: التاسع - أ)'),
              kField(password, isEdit ? 'كلمة المرور الجديدة (اتركها فارغة للإبقاء)' : 'كلمة المرور (اختياري)', obscure: true),
              const SizedBox(height: 8),
              kBtn(isEdit ? 'حفظ التعديل' : 'إضافة', () async {
                final body = <String, dynamic>{
                  if (!isEdit) 'academic_id': academicId.text.trim(),
                  'full_name': fullName.text.trim(),
                  'grade_level': grade.text.trim(),
                  'class_id': classId.text.trim(),
                  'class_name': className.text.trim(),
                  if (password.text.trim().isNotEmpty) 'password': password.text.trim(),
                };
                final res = isEdit
                    ? await AdminApi.updateStudent(student!['academic_id'], body)
                    : await AdminApi.createStudent(body);
                if (!mounted) return;
                Navigator.pop(context);
                if (res['ok'] == true) { showMsg(context, isEdit ? 'تعديل طالب: ${fullName.text.trim()}' : 'إضافة طالب: ${fullName.text.trim()}', type: isEdit ? 'تعديل' : 'إضافة'); _load(); }
                else showMsg(context, res['error'] ?? 'خطأ', error: true, type: 'خطأ');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> s) async {
    if (!await confirmDelete(context, s['full_name'])) return;
    final res = await AdminApi.deleteStudent(s['academic_id']);
    if (!mounted) return;
    if (res['ok'] == true) { showMsg(context, 'حذف طالب: ${s['full_name']}', type: 'حذف'); _load(); }
    else showMsg(context, res['error'] ?? 'خطأ', error: true, type: 'خطأ');
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلاب', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // ── فلتر الصفوف ──
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _grades.length,
              itemBuilder: (_, i) {
                final g = _grades[i];
                final selected = _selectedGrade == g;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(g, style: TextStyle(fontFamily: 'Cairo', color: selected ? Colors.white : kPrimary, fontSize: 12)),
                    selected: selected,
                    selectedColor: kPrimary,
                    backgroundColor: kPrimary.withOpacity(0.08),
                    onSelected: (_) => setState(() => _selectedGrade = selected ? null : g),
                  ),
                );
              },
            ),
          ),
          // ── قائمة الطلاب ──
          Expanded(
            child: _loading
                ? loadingWidget()
                : filtered.isEmpty
                    ? Center(child: Text(
                        _selectedGrade != null ? 'لا يوجد طلاب في صف $_selectedGrade' : 'لا يوجد طلاب',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final s = filtered[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: kPrimary, child: Text(s['full_name'][0], style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'))),
                              title: Text(s['full_name'], style: kTitle),
                              subtitle: Text('${s['academic_id']} | ${s['class_name'] ?? ''}', style: kBody),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, color: kPrimary), onPressed: () => _openForm(s)),
                                deleteBtn(() => _delete(s)),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
