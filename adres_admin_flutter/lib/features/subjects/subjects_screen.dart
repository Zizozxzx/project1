import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/widgets.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});
  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<dynamic> _subjects = [];
  bool _loading = true;

  static const _stages = ['primary', 'middle', 'secondary'];
  static const _stagesAr = ['ابتدائي', 'متوسط', 'ثانوي'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await AdminApi.getSubjects();
    if (res['ok'] == true) {
      final data = res['data'];
      setState(() { _subjects = data is List ? data : []; });
    }
    setState(() => _loading = false);
  }

  void _openForm([Map<String, dynamic>? subject]) {
    final name       = TextEditingController(text: subject?['name'] ?? '');
    final grade      = TextEditingController(text: subject?['grade_level'] ?? '');
    final order      = TextEditingController(text: subject?['order']?.toString() ?? '1');
    String stage     = subject?['education_stage'] ?? 'middle';
    final isEdit = subject != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEdit ? 'تعديل المادة' : 'إضافة مادة', style: kTitle),
                const SizedBox(height: 12),
                kField(name, 'اسم المادة'),
                kField(grade, 'الصف الدراسي'),
                kField(order, 'الترتيب', type: TextInputType.number),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: DropdownButtonFormField<String>(
                    value: stage,
                    decoration: InputDecoration(
                      labelText: 'المرحلة التعليمية',
                      labelStyle: const TextStyle(fontFamily: 'Cairo'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: List.generate(_stages.length, (i) => DropdownMenuItem(
                      value: _stages[i],
                      child: Text(_stagesAr[i], style: const TextStyle(fontFamily: 'Cairo')),
                    )),
                    onChanged: (v) => setS(() => stage = v!),
                  ),
                ),
                const SizedBox(height: 8),
                kBtn(isEdit ? 'حفظ التعديل' : 'إضافة', () async {
                  final body = {
                    'name': name.text.trim(),
                    'grade_level': grade.text.trim(),
                    'education_stage': stage,
                    'order': int.tryParse(order.text.trim()) ?? 1,
                  };
                  final res = isEdit
                      ? await AdminApi.updateSubject(subject!['id'], body)
                      : await AdminApi.createSubject(body);
                  if (!mounted) return;
                  Navigator.pop(context);
                  if (res['ok'] == true) { showMsg(context, isEdit ? 'تعديل مادة: ${name.text.trim()}' : 'إضافة مادة: ${name.text.trim()}', type: isEdit ? 'تعديل' : 'إضافة'); _load(); }
                  else showMsg(context, res['error'] ?? 'خطأ', error: true, type: 'خطأ');
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> s) async {
    if (!await confirmDelete(context, s['name'])) return;
    final res = await AdminApi.deleteSubject(s['id']);
    if (!mounted) return;
    if (res['ok'] == true) { showMsg(context, 'حذف مادة: ${s['name']}', type: 'حذف'); _load(); }
    else showMsg(context, res['error'] ?? 'خطأ', error: true, type: 'خطأ');
  }

  String _stageAr(String s) {
    final i = _stages.indexOf(s);
    return i >= 0 ? _stagesAr[i] : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المواد الدراسية', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: kPrimary, foregroundColor: Colors.white,
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
          : _subjects.isEmpty
              ? const Center(child: Text('لا توجد مواد', style: TextStyle(fontFamily: 'Cairo')))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _subjects.length,
                  itemBuilder: (_, i) {
                    final s = _subjects[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: const Color(0xFF8E24AA), child: Text('${s['order']}', style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'))),
                        title: Text(s['name'], style: kTitle),
                        subtitle: Text('${s['grade_level']} | ${_stageAr(s['education_stage'] ?? '')}', style: kBody),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: kPrimary), onPressed: () => _openForm(s)),
                          deleteBtn(() => _delete(s)),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}
