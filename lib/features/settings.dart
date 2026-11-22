import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../state/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _msg(BuildContext c, String s) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final ok = await confirm(context,
        'فایل پشتیبان رمزگذاری نشده است و شامل همه اطلاعات مالی‌ات می‌شود. جای امنی نگهش دار. ادامه بدهیم؟');
    if (!ok) return;
    final data = await ref.repo.exportAll();
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/baguette-backup-${DateTime.now().millisecondsSinceEpoch}.json');
    await f.writeAsString(jsonEncode(data));
    await Share.shareXFiles([XFile(f.path)], text: 'پشتیبان باگت');
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = res?.files.single.path;
    if (path == null) return;
    if (!context.mounted) return;
    if (!await confirm(context, 'همه اطلاعات فعلی با فایل پشتیبان جایگزین می‌شود. مطمئنی؟')) return;
    try {
      final data = jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
      await ref.repo.importAll(data);
      ref.bump();
      if (context.mounted) _msg(context, 'اطلاعات بازیابی شد');
    } catch (_) {
      if (context.mounted) _msg(context, 'فایل پشتیبان معتبر نیست');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    final bal = ref.watch(balancesProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        TextFormField(
          initialValue: s.name,
          decoration: const InputDecoration(labelText: 'اسم'),
          onChanged: (v) => n.update(s.copyWith(name: v.trim())),
        ),
        const SizedBox(height: 20),
        const Text('واحد پول'),
        const SizedBox(height: 8),
        SegmentedButton<Unit>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: Unit.toman, label: Text('تومان')),
            ButtonSegment(value: Unit.rial, label: Text('ریال')),
          ],
          selected: {s.unit},
          onSelectionChanged: (v) => n.update(s.copyWith(unit: v.first)),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          value: s.startDay,
          decoration: const InputDecoration(labelText: 'روز شروع ماه مالی'),
          items: [
            for (var d = 1; d <= 28; d++) DropdownMenuItem(value: d, child: Text('$d'))
          ],
          onChanged: (v) {
            if (v == null) return;
            n.update(s.copyWith(startDay: v));
            ref.read(monthProvider.notifier).state = currentAnchor(v);
          },
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('همگام‌سازی خودکار پیامک‌ها'),
          subtitle: const Text(
            'خواندن خودکار پیامک‌های بانکی و ثبت تراکنش‌ها با تاریخ دقیق',
            style: TextStyle(fontSize: 12, color: BColors.primary),
          ),
          value: s.autoSmsSync,
          onChanged: (v) => n.update(s.copyWith(autoSmsSync: v)),
        ),
        const SizedBox(height: 20),
        Row(children: [
          const Expanded(
              child: Text('حساب‌ها', style: TextStyle(fontWeight: FontWeight.w700))),
          TextButton.icon(
              onPressed: () => _accountSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('افزودن')),
        ]),
        for (final a in accounts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Material(
              color: BColors.tertiary,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: Text(a.name),
                trailing: MoneyText(bal[a.id] ?? 0, s.unit, size: 14),
                onTap: () => _accountSheet(context, ref, existing: a),
              ),
            ),
          ),
        const SizedBox(height: 28),
        const Text('پشتیبان‌گیری', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => _export(context, ref),
          icon: const Icon(Icons.upload),
          label: const Text('خروجی گرفتن (JSON)'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => _import(context, ref),
          icon: const Icon(Icons.download),
          label: const Text('بازیابی از فایل'),
        ),
        const SizedBox(height: 28),
        const Center(
          child: Text('باگت نسخه 0.3.0 • ساخته‌شده با ❤️ توسط Camros',
              style: TextStyle(fontSize: 11, color: BColors.secondary)),
        ),
      ]),
    );
  }
}

Future<void> _accountSheet(BuildContext context, WidgetRef ref, {Account? existing}) {
  final unit = ref.read(settingsProvider).unit;
  final name = TextEditingController(text: existing?.name ?? '');
  final bank = TextEditingController(text: existing?.bank ?? '');
  final cardSuffix = TextEditingController(text: existing?.cardSuffix ?? '');
  final init = TextEditingController(
      text: existing == null || existing.initialBalance == 0
          ? ''
          : groupDigits(toDisplay(existing.initialBalance, unit)));
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(existing == null ? 'حساب جدید' : 'ویرایش حساب',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        TextField(controller: name, decoration: const InputDecoration(hintText: 'نام حساب (مثلاً کارت اصلی)')),
        const SizedBox(height: 10),
        TextField(
          controller: init,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          inputFormatters: [ThousandsFormatter()],
          decoration: InputDecoration(hintText: 'موجودی اولیه', suffixText: unitLabel(unit)),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: bank,
              decoration: const InputDecoration(hintText: 'نام بانک (مثلاً ملت)'),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: TextField(
              controller: cardSuffix,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                hintText: '۴ رقم کارت',
                counterText: '',
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          if (existing != null)
            IconButton(
              onPressed: () async {
                if (await confirm(ctx, 'این حساب حذف شود؟')) {
                  await ref.repo.deleteAccount(existing.id);
                  ref.bump();
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              icon: const Icon(Icons.delete_outline, color: BColors.expenseText),
            ),
          Expanded(
            child: FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await ref.repo.upsertAccount(Account(
                  id: existing?.id ?? const Uuid().v4(),
                  name: name.text.trim(),
                  kind: existing?.kind ?? 'bank',
                  bank: bank.text.trim(),
                  cardSuffix: cardSuffix.text.trim(),
                  initialBalance: fromDisplay(parseAmount(init.text), unit),
                ));
                ref.bump();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('ذخیره'),
            ),
          ),
        ]),
      ]),
    ),
  );
}
