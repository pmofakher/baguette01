import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/repo.dart';
import '../state/providers.dart';

const _palette = [
  Color(0xFF40506A), Color(0xFFF6CA56), Color(0xFF7FB69E), Color(0xFFE07A5F),
  Color(0xFF9BA5B7), Color(0xFF81B1D5), Color(0xFFB08BBB), Color(0xFFC9A66B),
];

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsProvider).unit;
    final totals = ref.watch(totalsProvider).valueOrNull ?? const Totals(0, 0);
    final prev = ref.watch(prevTotalsProvider).valueOrNull ?? const Totals(0, 0);
    final spend = ref.watch(categorySpendProvider).valueOrNull ?? {};
    final cats = ref.watch(categoryMapProvider).valueOrNull ?? {};
    final series = ref.watch(seriesProvider).valueOrNull ?? [];
    final nec = ref.watch(necessitySpendProvider).valueOrNull ?? {};
    final leaks = ref.watch(leaksProvider).valueOrNull ?? [];

    final entries = spend.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalExp = totals.expense;
    final optional =
        (nec[Necessity.optional] ?? 0) + (nec[Necessity.fun] ?? 0);

    Widget line(String k, int v, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(child: Text(k)),
            MoneyText(v, unit, size: 15, color: color, sign: false),
          ]),
        );

    String change() {
      if (prev.expense == 0) return 'ماه قبل داده‌ای نیست';
      final p = ((totals.expense / prev.expense - 1) * 100).round();
      return p >= 0 ? 'خرج $p٪ بیشتر از ماه قبل' : 'خرج ${-p}٪ کمتر از ماه قبل';
    }

    return Column(children: [
      const BTopBar(title: 'گزارش'),
      const MonthPager(),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            SectionCard(
              child: Column(children: [
                line('مجموع درآمد', totals.income, color: BColors.incomeText),
                line('مجموع مخارج', totals.expense, color: BColors.expenseText),
                const Divider(),
                line('تراز ماه', totals.balance),
                Align(
                    alignment: Alignment.centerRight,
                    child: Text(change(),
                        style: const TextStyle(fontSize: 12, color: BColors.primary))),
              ]),
            ),
            const SizedBox(height: 16),
            const Text('سهم دسته‌ها از خرج', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const EmptyState('خرجی برای نمایش نیست')
            else ...[
              SizedBox(
                height: 190,
                child: PieChart(PieChartData(
                  centerSpaceRadius: 46,
                  sectionsSpace: 2,
                  sections: [
                    for (var i = 0; i < entries.length; i++)
                      PieChartSectionData(
                        value: entries[i].value.toDouble(),
                        color: _palette[i % _palette.length],
                        title: '',
                        radius: 44,
                      ),
                  ],
                )),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: _palette[i % _palette.length],
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            '${cats[entries[i].key]?.emoji ?? ''} ${cats[entries[i].key]?.name ?? 'نامشخص'}')),
                    Text('${(entries[i].value / totalExp * 100).round()}٪  ',
                        style: const TextStyle(fontSize: 12)),
                    MoneyText(entries[i].value, unit, size: 13),
                  ]),
                ),
            ],
            const SizedBox(height: 20),
            const Text('روند ۶ ماه اخیر', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Row(children: [
              Icon(Icons.circle, size: 10, color: BColors.incomeText),
              SizedBox(width: 4),
              Text('درآمد', style: TextStyle(fontSize: 12)),
              SizedBox(width: 12),
              Icon(Icons.circle, size: 10, color: BColors.expenseText),
              SizedBox(width: 4),
              Text('خرج', style: TextStyle(fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: series.isEmpty
                  ? const SizedBox()
                  : BarChart(BarChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(series[v.toInt()].label,
                                  style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < series.length; i++)
                          BarChartGroupData(x: i, barsSpace: 3, barRods: [
                            BarChartRodData(
                                toY: toDisplay(series[i].totals.income, unit).toDouble(),
                                color: BColors.incomeText,
                                width: 9),
                            BarChartRodData(
                                toY: toDisplay(series[i].totals.expense, unit).toDouble(),
                                color: BColors.expenseText,
                                width: 9),
                          ]),
                      ],
                    )),
            ),
            const SizedBox(height: 20),
            if (totalExp > 0)
              SectionCard(
                color: BColors.recentBg,
                child: Text(
                    '${(optional / totalExp * 100).round()}٪ خرجت این ماه «غیرضروری» یا «لذت از زندگی» بوده (${money(optional, unit)} ${unitLabel(unit)}).'),
              ),
            const SizedBox(height: 12),
            SectionCard(
              color: BColors.expenseCard.withAlpha(110),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🐞 نشتی‌های مالی', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (leaks.isEmpty) const Text('موردی پیدا نشد.'),
                for (final l in leaks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(l.overBudget
                        ? '${l.cat.emoji} ${l.cat.name}: ${l.percent}٪ بالاتر از بودجه'
                        : '${l.cat.emoji} ${l.cat.name}: ${l.percent}٪ بالاتر از میانگین ۳ ماه قبل (${money(l.excess, unit)} ${unitLabel(unit)} اضافه)'),
                  ),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }
}
