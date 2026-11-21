import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../state/providers.dart';

class WealthPage extends ConsumerWidget {
  const WealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsProvider).unit;
    final nw = ref.watch(netWorthProvider).valueOrNull;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دارایی و بدهی'),
          bottom: const TabBar(
              tabs: [Tab(text: 'سرمایه‌ها'), Tab(text: 'بدهکاری'), Tab(text: 'طلبکاری')]),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: SectionCard(
              color: BColors.balanceBg,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('اجماع سرمایه‌ها (خالص)',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Center(child: MoneyText(nw?.total ?? 0, unit, size: 26, sign: true)),
                if (nw != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'حساب‌ها ${money(nw.accounts, unit)} + سرمایه‌ها ${money(nw.assets, unit)} + طلب ${money(nw.credits, unit)} − بدهی ${money(nw.debts, unit)}',
                    style: const TextStyle(fontSize: 11, color: BColors.primary),
                  ),
                ],
              ]),
            ),
          ),
          const Expanded(
            child: TabBarView(children: [
              _AssetsTab(),
              _DebtsTab(DebtDir.debt),
              _DebtsTab(DebtDir.credit),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _AssetsTab extends ConsumerWidget {
  const _AssetsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsProvider).unit;
    final items = ref.watch(assetsProvider).valueOrNull ?? [];
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: 'asset',
        onPressed: () => _assetSheet(context, ref),
        child: const Icon(Icons.add, size: 30),
      ),
      body: items.isEmpty
          ? const Center(child: EmptyState('هنوز سرمایه‌ای ثبت نشده'))
          : ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), children: [
              for (final a in items)
                Dismissible(
                  key: ValueKey(a.id),
                  background: Container(color: BColors.expenseCard),
                  confirmDismiss: (_) => confirm(context, 'حذف «${a.name}»؟'),
                  onDismissed: (_) async {
                    await ref.repo.deleteAsset(a.id);
                    ref.bump();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Material(
                      color: BColors.tertiary,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        title: Text(a.name),
                        subtitle: Text(a.group.label, style: const TextStyle(fontSize: 11)),
                        trailing: MoneyText(a.amount, unit, size: 14),
                        onTap: () => _assetSheet(context, ref, existing: a),
                      ),
                    ),
                  ),
                ),
            ]),
    );
  }
}

Future<void> _assetSheet(BuildContext context, WidgetRef ref, {Asset? existing}) {
  final unit = ref.read(settingsProvider).unit;
  final name = TextEditingController(text: existing?.name ?? '');
  final amount = TextEditingController(
      text: existing == null ? '' : groupDigits(toDisplay(existing.amount, unit)));
  var group = existing?.group ?? AssetGroup.bank;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(existing == null ? 'سرمایه جدید' : 'ویرایش سرمایه',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          TextField(controller: name, decoration: const InputDecoration(hintText: 'نام (مثلاً ۲۵ گرم طلا)')),
          const SizedBox(height: 10),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            inputFormatters: [ThousandsFormatter()],
            decoration: InputDecoration(hintText: 'ارزش کل', suffixText: unitLabel(unit)),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final g in AssetGroup.values)
              ChoiceChip(
                  label: Text(g.label),
                  selected: group == g,
                  onSelected: (_) => set(() => group = g)),
          ]),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              await ref.repo.upsertAsset(Asset(
                id: existing?.id ?? const Uuid().v4(),
                name: name.text.trim(),
                group: group,
                amount: fromDisplay(parseAmount(amount.text), unit),
              ));
              ref.bump();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('ذخیره'),
          ),
        ]),
      ),
    ),
  );
}

class _DebtsTab extends ConsumerWidget {
  final DebtDir dir;
  const _DebtsTab(this.dir);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsProvider).unit;
    final items = ref.watch(debtsProvider(dir)).valueOrNull ?? [];
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: 'debt-${dir.name}',
        onPressed: () => _debtSheet(context, ref, dir),
        child: const Icon(Icons.add, size: 30),
      ),
      body: items.isEmpty
          ? Center(child: EmptyState(dir == DebtDir.debt ? 'بدهی‌ای ثبت نشده' : 'طلبی ثبت نشده'))
          : ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), children: [
              for (final d in items)
                Dismissible(
                  key: ValueKey(d.id),
                  background: Container(color: BColors.expenseCard),
                  confirmDismiss: (_) => confirm(context, 'حذف مورد «${d.person}»؟'),
                  onDismissed: (_) async {
                    await ref.repo.deleteDebt(d.id);
                    ref.bump();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Material(
                      color: dir == DebtDir.debt
                          ? BColors.expenseRow
                          : BColors.incomeRow,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        title: Text(d.person),
                        subtitle: Text(
                          [
                            if (d.reason.isNotEmpty) d.reason,
                            if (d.dueAt != null) 'سررسید ${jDate(d.dueAt!)}',
                            if (d.paid > 0) 'تسویه‌شده: ${money(d.paid, unit)}',
                          ].join(' • '),
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: MoneyText(d.remaining, unit, size: 14),
                        onTap: () => _debtSheet(context, ref, dir, existing: d),
                      ),
                    ),
                  ),
                ),
            ]),
    );
  }
}

Future<void> _debtSheet(BuildContext context, WidgetRef ref, DebtDir dir,
    {DebtItem? existing}) {
  final unit = ref.read(settingsProvider).unit;
  final person = TextEditingController(text: existing?.person ?? '');
  final reason = TextEditingController(text: existing?.reason ?? '');
  final amount = TextEditingController(
      text: existing == null ? '' : groupDigits(toDisplay(existing.amount, unit)));
  final paid = TextEditingController(
      text: existing == null || existing.paid == 0
          ? ''
          : groupDigits(toDisplay(existing.paid, unit)));
  DateTime? due = existing?.dueAt;
  final isDebt = dir == DebtDir.debt;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(isDebt ? 'بدهی' : 'طلب',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
                controller: person,
                decoration: InputDecoration(hintText: isDebt ? 'به چه کسی بدهکاری؟' : 'از چه کسی طلب داری؟')),
            const SizedBox(height: 10),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              inputFormatters: [ThousandsFormatter()],
              decoration: InputDecoration(hintText: 'مبلغ کل', suffixText: unitLabel(unit)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: paid,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              inputFormatters: [ThousandsFormatter()],
              decoration: InputDecoration(hintText: 'تا الان تسویه شده', suffixText: unitLabel(unit)),
            ),
            const SizedBox(height: 10),
            TextField(controller: reason, decoration: const InputDecoration(hintText: 'بابت (اختیاری)')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(due == null ? 'سررسید (اختیاری)' : jDate(due!)),
                  onPressed: () async {
                    final d = await showJalaliPicker(ctx, due ?? DateTime.now());
                    if (d != null) set(() => due = d);
                  },
                ),
              ),
              if (due != null)
                IconButton(onPressed: () => set(() => due = null), icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final a = fromDisplay(parseAmount(amount.text), unit);
                if (person.text.trim().isEmpty || a <= 0) return;
                await ref.repo.upsertDebt(DebtItem(
                  id: existing?.id ?? const Uuid().v4(),
                  direction: dir,
                  person: person.text.trim(),
                  amount: a,
                  paid: fromDisplay(parseAmount(paid.text), unit),
                  reason: reason.text.trim(),
                  dueAt: due,
                ));
                ref.bump();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('ذخیره'),
            ),
          ]),
        ),
      ),
    ),
  );
}
