import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/repo.dart';
import '../state/providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final totals = ref.watch(totalsProvider).valueOrNull ?? const Totals(0, 0);
    final recent = ref.watch(recentTxnsProvider).valueOrNull ?? [];
    final leaks = ref.watch(leaksProvider).valueOrNull ?? [];
    final spendable = ref.watch(spendableProvider).valueOrNull;
    final isCurrent = ref.watch(isCurrentPeriodProvider);

    Widget stat(String label, int v, Color bg) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label),
              const SizedBox(height: 18),
              MoneyText(v, s.unit, size: 16),
            ]),
          ),
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        BTopBar(title: s.name.isEmpty ? 'سلام 👋' : 'سلام ${s.name} 👋'),
        const MonthPager(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 8),
            Row(children: [
              stat('درآمد ماه', totals.income, BColors.incomeCard),
              const SizedBox(width: 12),
              stat('مخارج ماه', totals.expense, BColors.expenseCard),
            ]),
            const SizedBox(height: 12),
            SectionCard(
              color: BColors.balanceBg,
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('تراز:', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Center(
                    child: MoneyText(totals.balance, s.unit,
                        size: 28, sign: true)),
              ]),
            ),
            if (isCurrent && spendable != null) ...[
              const SizedBox(height: 12),
              SectionCard(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('پول آزاد قابل خرج',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      MoneyText(spendable.amount, s.unit, size: 18),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('روزانه (${spendable.daysLeft} روز مانده)',
                        style: const TextStyle(fontSize: 11)),
                    const SizedBox(height: 6),
                    MoneyText(spendable.perDay, s.unit, size: 15),
                  ]),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            SectionCard(
              color: leaks.isEmpty ? BColors.incomeCard.withAlpha(90) : BColors.expenseCard.withAlpha(110),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(leaks.isEmpty ? '🐞 باگی پیدا نشد' : '🐞 باگ‌های ولخرجی این ماه',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (leaks.isEmpty)
                  const Text('فعلاً خرجی از سقف یا از روند ۳ ماه قبلت بیرون نزده.',
                      style: TextStyle(fontSize: 13))
                else
                  for (final l in leaks.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        l.overBudget
                            ? '${l.cat.emoji} ${l.cat.name}: ${money(l.excess, s.unit)} ${unitLabel(s.unit)} بیشتر از بودجه'
                            : '${l.cat.emoji} ${l.cat.name}: ${l.percent}٪ بیشتر از میانگین ۳ ماه قبل',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
              ]),
            ),
            const SizedBox(height: 12),
            const SectionCard(
              color: BColors.quoteBg,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('«یک پنی که پس‌انداز می‌کنی، یک پنی است که به دست آورده‌ای.»',
                    style: TextStyle(color: Color(0xFF636363), height: 1.7)),
                SizedBox(height: 6),
                Text('بنجامین فرانکلین',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8B8B8B))),
              ]),
            ),
            const SizedBox(height: 12),
            SectionCard(
              color: BColors.recentBg,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Expanded(child: Text('آخرین تراکنش‌ها:')),
                  TextButton(
                      onPressed: () => context.go('/transactions'),
                      child: const Text('همه')),
                ]),
                if (recent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('هنوز تراکنشی ثبت نکردی. با دکمه + شروع کن.',
                        style: TextStyle(fontSize: 13)),
                  )
                else
                  for (final t in recent) TxnTile(t),
              ]),
            ),
          ]),
        ),
      ],
    );
  }
}
