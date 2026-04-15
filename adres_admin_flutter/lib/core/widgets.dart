import 'package:flutter/material.dart';
import '../main.dart';

const kPrimary = Color(0xFF1E88E5);
const kDanger  = Color(0xFFE53935);
const kBg      = Color(0xFFF5F6FA);

TextStyle get kTitle => const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold);
TextStyle get kBody  => const TextStyle(fontFamily: 'Cairo', fontSize: 14);

/// زر حذف صغير
Widget deleteBtn(VoidCallback onTap) => IconButton(
  icon: const Icon(Icons.delete_outline, color: kDanger),
  onPressed: onTap,
);

/// حوار تأكيد الحذف
Future<bool> confirmDelete(BuildContext context, String name) async {
  return await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
      content: Text('هل تريد حذف "$name"؟', style: const TextStyle(fontFamily: 'Cairo')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
        TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: kDanger))),
      ],
    ),
  ) ?? false;
}

/// حقل نص موحد
Widget kField(TextEditingController c, String label, {bool obscure = false, TextInputType? type}) =>
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    ),
  );

/// زر رئيسي
Widget kBtn(String label, VoidCallback onTap, {Color color = kPrimary}) =>
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 15)),
    ),
  );

/// snackbar + تسجيل العملية
void showMsg(BuildContext context, String msg, {bool error = false, String type = 'عملية'}) {
  HomeScreenState.addLog(type, msg);
  // تحديث السجل في الواجهة إذا كانت HomeScreen مفتوحة
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
    backgroundColor: error ? kDanger : Colors.green,
  ));
}

/// مؤشر تحميل مركزي
Widget loadingWidget() => const Center(child: CircularProgressIndicator());
