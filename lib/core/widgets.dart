import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../data/models.dart';
import '../state/providers.dart';
import 'format.dart';
import 'theme.dart';

/// نوار بالای صفحه: عنوان + منوی سه‌نقطه (مثل فیگما)
class BTopBar extends StatelessWidget {
  final String title;
  final bool menu;
  final Widget? action;
  const BTopBar(
      {super.key, required this.title, this.menu = true, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(children: [
        Expanded(
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (action != null) ...[
          action!,
          const SizedBox(width: 8),
        ],
        if (menu)
          PopupMenuButton<String>(
            onSelected: (v) => context.push('/$v'),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'categories', child: Text('دسته‌ها')),
              PopupMenuItem(value: 'wealth', child: Text('دارایی و بدهی')),
              PopupMenuItem(value: 'settings', child: Text('تنظیمات')),
            ],
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: BColors.tertiary, shape: BoxShape.circle),
              child: const Icon(Icons.more_vert, size: 20),
            ),
          ),
      ]),
    );
  }
}

class MonthPager extends ConsumerWidget {
  const MonthPager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(monthProvider);
    final cur = currentAnchor(ref.watch(settingsProvider).startDay);
    final isCurrent = m.year == cur.year && m.month == cur.month;
    final n = ref.read(monthProvider.notifier);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(
          onPressed: () => n.state = addMonths(m, -1),
          icon: const Icon(Icons.chevron_right)),
      SizedBox(
          width: 140,
          child: Text(monthLabel(m),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600))),
      IconButton(
          onPressed: isCurrent ? null : () => n.state = addMonths(m, 1),
          icon: const Icon(Icons.chevron_left)),
    ]);
  }
}

/// مبلغ با رقم‌های کم‌رنگ‌شده بعد از اولین ویرگول (مثل فیگما)
class MoneyText extends StatelessWidget {
  final int rial;
  final Unit unit;
  final double size;
  final bool sign;
  final Color? color;
  final FontWeight? weight;
  const MoneyText(this.rial, this.unit,
      {super.key, this.size = 16, this.sign = false, this.color, this.weight});

  @override
  Widget build(BuildContext context) {
    final s = money(rial, unit, sign: sign);
    final i = s.indexOf(',');
    final c = color ?? BColors.primaryDark;
    final style = TextStyle(fontSize: size, color: c, fontWeight: weight);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(TextSpan(style: style, children: [
        TextSpan(text: i < 0 ? s : s.substring(0, i)),
        if (i >= 0)
          TextSpan(
              text: s.substring(i), style: style.copyWith(color: c.withAlpha(102))),
      ])),
    );
  }
}

class TxnTile extends ConsumerWidget {
  final Txn t;
  const TxnTile(this.t, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsProvider).unit;
    final cats = ref.watch(categoryMapProvider).valueOrNull ?? {};
    final cat = cats[t.categoryId];
    final isUncategorized = t.kind != TxnKind.transfer && cat == null;
    final bg = switch (t.kind) {
      TxnKind.income => BColors.incomeRow,
      TxnKind.expense => BColors.expenseRow,
      TxnKind.transfer => BColors.tertiary,
    };
    final head = t.kind == TxnKind.transfer
        ? 'انتقال بین حساب‌ها'
        : isUncategorized
            ? '${t.kind.label} - بدون دسته‌بندی'
            : '${t.kind.label} - ${cat!.name}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/txn/${t.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(head,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isUncategorized
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                )),
                          ),
                          if (isUncategorized) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () =>
                                  showQuickCategoryPicker(context, ref, t),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: BColors.annotation.withAlpha(70),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: BColors.annotation, width: 0.8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.label_outline,
                                        size: 12, color: BColors.primaryDark),
                                    SizedBox(width: 4),
                                    Text('تعیین دسته',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (t.title.isNotEmpty)
                        Text(t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: BColors.primary)),
                    ]),
              ),
              MoneyText(t.amount, unit,
                  size: 14,
                  sign: t.kind != TxnKind.transfer,
                  weight: FontWeight.w600),
            ]),
          ),
        ),
      ),
    );
  }
}

Future<void> showQuickCategoryPicker(
    BuildContext context, WidgetRef ref, Txn t) async {
  final cats = await ref.read(repoProvider).categories(t.kind);
  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'انتخاب دسته برای «${t.title.isNotEmpty ? t.title : t.kind.label}»',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (cats.isEmpty)
              const Text('دسته‌ای تعریف نشده است')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in cats)
                    ActionChip(
                      avatar: Text(c.emoji),
                      label: Text(c.name),
                      onPressed: () async {
                        await ref
                            .read(repoProvider)
                            .upsertTxn(t.copyWith(categoryId: c.id));
                        ref.bump();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

class SectionCard extends StatelessWidget {
  final Color color;
  final Widget child;
  final EdgeInsets padding;
  const SectionCard(
      {super.key,
      required this.child,
      this.color = BColors.tertiary,
      this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: child,
      );
}

class EmptyState extends StatelessWidget {
  final String text;
  const EmptyState(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          Opacity(
              opacity: .9,
              child: Image.asset('assets/images/logo.png', width: 120)),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: BColors.secondary)),
        ]),
      );
}

/// دیالوگ ساده برای گرفتن مبلغ (به واحد نمایشی کاربر). null = انصراف
Future<int?> showAmountPrompt(BuildContext context,
    {required String title, required Unit unit, int initial = 0}) {
  final c = TextEditingController(text: initial > 0 ? groupDigits(initial) : '');
  return showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        inputFormatters: [ThousandsFormatter()],
        decoration: InputDecoration(suffixText: unitLabel(unit)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
          onPressed: () => Navigator.pop(ctx, parseAmount(c.text)),
          child: const Text('ذخیره'),
        ),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, String text) async =>
    (await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('خیر')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('بله')),
        ],
      ),
    )) ??
    false;

/// انتخابگر تاریخ شمسی (سال / ماه / روز)
Future<DateTime?> showJalaliPicker(BuildContext context, DateTime initial) {
  final j0 = Jalali.fromDateTime(initial);
  final nowY = Jalali.now().year;
  final start = j0.year < nowY - 8 ? j0.year : nowY - 8;
  final years = List<int>.generate(nowY + 3 - start, (i) => start + i);
  var y = j0.year, m = j0.month, d = j0.day;
  final yc = FixedExtentScrollController(initialItem: y - start);
  final mc = FixedExtentScrollController(initialItem: m - 1);
  final dc = FixedExtentScrollController(initialItem: d - 1);

  Widget wheel(FixedExtentScrollController c, List<String> items,
          ValueChanged<int> on) =>
      Expanded(
        child: CupertinoPicker(
          scrollController: c,
          itemExtent: 40,
          onSelectedItemChanged: on,
          children: [for (final s in items) Center(child: Text(s))],
        ),
      );

  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
      final maxD = Jalali(y, m, 1).monthLength;
      if (d > maxD) d = maxD;
      return SizedBox(
        height: 320,
        child: Column(children: [
          Expanded(
            child: Row(children: [
              wheel(yc, [for (final v in years) '$v'], (i) => set(() => y = years[i])),
              wheel(mc, monthNames, (i) => set(() => m = i + 1)),
              wheel(dc, [for (var i = 1; i <= maxD; i++) '$i'],
                  (i) => set(() => d = i + 1)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, Jalali(y, m, d).toDateTime()),
              child: const Text('تأیید'),
            ),
          ),
        ]),
      );
    }),
  );
}
