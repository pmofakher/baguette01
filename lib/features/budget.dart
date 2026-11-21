import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../state/providers.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsProvider).unit;
    final cats = ref.watch(categoriesProvider(TxnKind.expense)).valueOrNull ?? [];
    final spend = ref.watch(categorySpendProvider).valueOrNull ?? {};
    final period = ref.watch(periodProvider);
    final isCurrent = ref.watch(isCurrentPeriodProvider);

    final totalBudget = cats.fold<int>(0, (a, c) => a + c.budget);
    final totalSpent = spend.values.fold<int>(0, (a, b) => a + b);

    // تخمین خرج پایان ماه بر اساس روند فعلی
    int? projected;
    if (isCurrent) {
      final total = period.end.difference(period.start).inHours / 24;
      final elapsed =
          (DateTime.now().difference(period.start).inHours / 24).clamp(1, total);
      projected = (totalSpent / elapsed * total).round();
    }

    Future<void> setBudget(Category c) async {
      final v = await showAmountPrompt(context,
          title: 'بودجه ماهانه «${c.name}»',
          unit: unit,
          initial: toDisplay(c.budget, unit));
      if (v == null) return;
      await ref.repo.upsertCategory(c.copyWith(budget: fromDisplay(v, unit)));
      ref.bump();
    }

    final sorted = [...cats]
      ..sort((a, b) => (spend[b.id] ?? 0).compareTo(spend[a.id] ?? 0));

    return Column(children: [
      const BTopBar(title: 'بودجه'),
      const MonthPager(),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            SectionCard(
              color: BColors.recentBg,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Expanded(child: Text('کل بودجه خرج')),
                  MoneyText(totalBudget, unit),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Expanded(child: Text('خرج‌شده تا الان')),
                  MoneyText(totalSpent, unit),
                ]),
                if (projected != null) ...[
                  const Divider(height: 20),
                  Row(children: [
                    const Expanded(child: Text('تخمین خرج تا آخر ماه')),
                    MoneyText(projected, unit,
                        weight: FontWeight.w700,
                        color: totalBudget > 0 && projected > totalBudget
                            ? BColors.expenseText
                            : null),
                  ]),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            const Text('روی هر دسته بزن تا بودجه‌اش را تعیین کنی',
                style: TextStyle(fontSize: 12, color: BColors.primary)),
            const SizedBox(height: 8),
            for (final c in sorted)
              _BudgetRow(
                  cat: c,
                  spent: spend[c.id] ?? 0,
                  unit: unit,
                  onTap: () => setBudget(c)),
          ],
        ),
      ),
    ]);
  }
}

class _BudgetRow extends StatelessWidget {
  final Category cat;
  final int spent;
  final Unit unit;
  final VoidCallback onTap;
  const _BudgetRow(
      {required this.cat,
      required this.spent,
      required this.unit,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final has = cat.budget > 0;
    final ratio = has ? spent / cat.budget : 0.0;
    final color = ratio > 1
        ? BColors.expenseText
        : ratio >= .8
            ? BColors.annotation
            : BColors.incomeText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: BColors.tertiary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(child: Text(cat.name)),
                MoneyText(spent, unit, size: 14),
                Text(has ? '  /  ' : '', style: const TextStyle(fontSize: 12)),
                if (has) MoneyText(cat.budget, unit, size: 12),
              ]),
              if (has) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0, 1).toDouble(),
                    minHeight: 8,
                    color: color,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
