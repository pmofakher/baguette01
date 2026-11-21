import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../state/providers.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دسته‌ها'),
          bottom: const TabBar(tabs: [Tab(text: 'خرج'), Tab(text: 'درآمد')]),
        ),
        body: const TabBarView(children: [
          _CatList(TxnKind.expense),
          _CatList(TxnKind.income),
        ]),
      ),
    );
  }
}

class _CatList extends ConsumerWidget {
  final TxnKind kind;
  const _CatList(this.kind);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider(kind)).valueOrNull ?? [];
    final unit = ref.watch(settingsProvider).unit;
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: 'cat-${kind.name}',
        onPressed: () => showCategorySheet(context, ref, kind: kind),
        child: const Icon(Icons.add, size: 30),
      ),
      body: cats.isEmpty
          ? const Center(child: EmptyState('دسته‌ای نیست'))
          : ListView(padding: const EdgeInsets.fromLTRB(24, 12, 24, 100), children: [
              for (final c in cats)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Material(
                    color: BColors.tertiary,
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      leading: Text(c.emoji, style: const TextStyle(fontSize: 22)),
                      title: Text(c.name),
                      subtitle: kind == TxnKind.expense && c.budget > 0
                          ? Text('بودجه: ${money(c.budget, unit)} ${unitLabel(unit)}',
                              style: const TextStyle(fontSize: 11))
                          : null,
                      onTap: () =>
                          showCategorySheet(context, ref, kind: kind, existing: c),
                    ),
                  ),
                ),
            ]),
    );
  }
}

Future<void> showCategorySheet(BuildContext context, WidgetRef ref,
    {required TxnKind kind, Category? existing}) {
  final unit = ref.read(settingsProvider).unit;
  final name = TextEditingController(text: existing?.name ?? '');
  final emoji = TextEditingController(text: existing?.emoji ?? '🏷️');
  final budget = TextEditingController(
      text: existing != null && existing.budget > 0
          ? groupDigits(toDisplay(existing.budget, unit))
          : '');
  var leak = existing?.leak ?? kind == TxnKind.expense;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(existing == null ? 'افزودن دسته جدید' : 'ویرایش دسته',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            SizedBox(
              width: 72,
              child: TextField(
                controller: emoji,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24),
                maxLength: 4,
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                  controller: name,
                  decoration: const InputDecoration(hintText: 'نام دسته')),
            ),
          ]),
          if (kind == TxnKind.expense) ...[
            const SizedBox(height: 12),
            TextField(
              controller: budget,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              inputFormatters: [ThousandsFormatter()],
              decoration: InputDecoration(
                  hintText: 'بودجه ماهانه (اختیاری)', suffixText: unitLabel(unit)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('در تشخیص نشتی حساب شود'),
              value: leak,
              onChanged: (v) => set(() => leak = v),
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            if (existing != null)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: IconButton(
                  onPressed: () async {
                    if (await confirm(ctx, 'این دسته حذف شود؟ تراکنش‌های قبلی می‌مانند.')) {
                      await ref.repo.deleteCategory(existing.id);
                      ref.bump();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: BColors.expenseText),
                ),
              ),
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  if (name.text.trim().isEmpty) return;
                  final c = Category(
                    id: existing?.id ?? const Uuid().v4(),
                    name: name.text.trim(),
                    kind: kind,
                    emoji: emoji.text.trim().isEmpty ? '🏷️' : emoji.text.trim(),
                    budget: fromDisplay(parseAmount(budget.text), unit),
                    leak: leak,
                  );
                  await ref.repo.upsertCategory(c);
                  ref.bump();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('ذخیره'),
              ),
            ),
          ]),
        ]),
      ),
    ),
  );
}
