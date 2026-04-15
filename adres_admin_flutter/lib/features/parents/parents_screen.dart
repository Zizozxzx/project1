import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/widgets.dart';

class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});
  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  List<dynamic> _parents = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await AdminApi.getParents();
    if (res['ok'] == true) {
      final data = res['data'];
      setState(() { _parents = data is List ? data : []; });
    }
    setState(() => _loading = false);
  }

  void _openForm([Map<String, dynamic>? parent]) {
    final parentId = TextEditingController(text: parent?['parent_id'] ?? '');
    final fullName  = TextEditingController(text: parent?['full_name'] ?? '');
    final isEdit = parent != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEdit ? 'تعديل ولي الأمر' : 'إضافة ولي أمر', style: kTitle),
            const SizedBox(height: 12),
            if (!isEdit) kField(parentId, 'رقم ولي الأمر'),
            kField(fullName, 'الاسم الكامل'),
            const SizedBox(height: 8),
            kBtn(isEdit ? 'حفظ التعديل' : 'إضافة', () async {
              final body = <String, dynamic>{
                if (!isEdit) 'parent_id': parentId.text.trim(),
                'full_name': fullName.text.trim(),
              };
              final res = isEdit
                  ? await AdminApi.updateParent(parent!['parent_id'], body)
                  : await AdminApi.createParent(body);
              if (!mounted) return;
              Navigator.pop(context);
              if (res['ok'] == true) { showMsg(context, isEdit ? 'تعديل ولي أمر: ${fullName.text.trim()}' : 'إضافة ولي أمر: ${fullName.text.trim()}', type: isEdit ? 'تعديل' : 'إضافة'); _load(); }
              else showMsg(context, res['error'] ?? 'خطأ', error: true, type: 'خطأ');
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> p) async {
    if (!await confirmDelete(context, p['full_name'])) return;
    final res = await AdminApi.deleteParent(p['parent_id']);
    if (!mounted) return;
    if (res['ok'] == true) { showMsg(context, 'حذف ولي أمر: ${p['full_name']}', type: 'حذف'); _load(); }
    else showMsg(context, res['error'] ?? 'خطأ', error: true, type: 'خطأ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أولياء الأمور', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: kPrimary, foregroundColor: Colors.white,
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
          : _parents.isEmpty
              ? const Center(child: Text('لا يوجد أولياء أمور', style: TextStyle(fontFamily: 'Cairo')))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _parents.length,
                  itemBuilder: (_, i) {
                    final p = _parents[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(backgroundColor: const Color(0xFFFFA000), child: Text(p['full_name'][0], style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'))),
                        title: Text(p['full_name'], style: kTitle),
                        subtitle: Text('رقم: ${p['parent_id']}', style: kBody),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: kPrimary), onPressed: () => _openForm(p)),
                          deleteBtn(() => _delete(p)),
                          const Icon(Icons.expand_more),
                        ]),
                        children: [_ParentChildrenSection(parent: p, onRefresh: _load)],
                      ),
                    );
                  },
                ),
    );
  }
}

// ─── قسم أبناء ولي الأمر ─────────────────────────────────────────────────────
class _ParentChildrenSection extends StatelessWidget {
  final Map<String, dynamic> parent;
  final VoidCallback onRefresh;
  const _ParentChildrenSection({required this.parent, required this.onRefresh});

  void _addChild(BuildContext context) {
    final academicId = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة ابن', style: TextStyle(fontFamily: 'Cairo')),
        content: kField(academicId, 'الرقم الأكاديمي للطالب', type: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          TextButton(
            onPressed: () async {
              final res = await AdminApi.addChildToParent(parent['parent_id'], academicId.text.trim());
              if (!context.mounted) return;
              Navigator.pop(context);
              if (res['ok'] == true) { showMsg(context, 'إضافة ابن لـ: ${parent['full_name']}', type: 'إضافة'); onRefresh(); }
              else showMsg(context, res['error'] ?? 'خطأ', error: true, type: 'خطأ');
            },
            child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo', color: kPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = (parent['children'] as List?) ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('الأبناء (${children.length})', style: kBody.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addChild(context),
              icon: const Icon(Icons.person_add, size: 16, color: kPrimary),
              label: const Text('إضافة ابن', style: TextStyle(fontFamily: 'Cairo', color: kPrimary, fontSize: 12)),
            ),
          ]),
          ...children.map((c) => ListTile(
            dense: true,
            title: Text(c['full_name'] ?? '', style: kBody),
            subtitle: Text(c['academic_id'] ?? '', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: kDanger, size: 20),
              onPressed: () async {
                final res = await AdminApi.removeChildFromParent(parent['parent_id'], c['academic_id']);
                if (!context.mounted) return;
                if (res['ok'] == true) { showMsg(context, 'حذف ابن من: ${parent['full_name']}', type: 'حذف'); onRefresh(); }
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
