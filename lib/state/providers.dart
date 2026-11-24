import 'dart:math';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../core/format.dart';
import '../data/models.dart';
import '../data/repo.dart';
import '../services/sms_sync_service.dart';

final repoProvider = Provider<Repo>((ref) => throw UnimplementedError());
final smsSyncServiceProvider = Provider<SmsSyncService>((ref) {
  return SmsSyncService(ref.watch(repoProvider));
});
final initialSettingsProvider =
    Provider<Settings>((ref) => throw UnimplementedError());

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() => ref.read(initialSettingsProvider);

  Future<void> update(Settings s) async {
    state = s;
    await ref.read(repoProvider).saveSettings(s);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

/// بعد از هر نوشتن در دیتابیس یکی زیاد می‌شود تا کوئری‌ها دوباره اجرا شوند.
final versionProvider = StateProvider<int>((ref) => 0);

extension RefX on WidgetRef {
  Repo get repo => read(repoProvider);
  void bump() => read(versionProvider.notifier).state++;
}

/// ماه انتخاب‌شده (اولین روز ماه شمسی)
final monthProvider = StateProvider<Jalali>(
    (ref) => currentAnchor(ref.read(settingsProvider).startDay));

final periodProvider = Provider<DateTimeRange>((ref) =>
    periodOf(ref.watch(monthProvider), ref.watch(settingsProvider).startDay));

final isCurrentPeriodProvider = Provider<bool>((ref) {
  final p = ref.watch(periodProvider);
  final now = DateTime.now();
  return !now.isBefore(p.start) && now.isBefore(p.end);
});

// ---------- پایه ----------
final accountsProvider = FutureProvider.autoDispose<List<Account>>((ref) {
  ref.watch(versionProvider);
  return ref.watch(repoProvider).accounts();
});

final balancesProvider = FutureProvider.autoDispose<Map<String, int>>((ref) {
  ref.watch(versionProvider);
  return ref.watch(repoProvider).balances();
});

final categoriesProvider =
    FutureProvider.autoDispose.family<List<Category>, TxnKind>((ref, kind) {
  ref.watch(versionProvider);
  return ref.watch(repoProvider).categories(kind);
});

final categoryMapProvider =
    FutureProvider.autoDispose<Map<String, Category>>((ref) async {
  ref.watch(versionProvider);
  final all = await ref.watch(repoProvider).allCategories();
  return {for (final c in all) c.id: c};
});

final txnProvider =
    FutureProvider.autoDispose.family<Txn?, String>((ref, id) {
  ref.watch(versionProvider);
  return ref.watch(repoProvider).txn(id);
});

// ---------- دوره جاری ----------
final periodTxnsProvider = FutureProvider.autoDispose<List<Txn>>((ref) {
  ref.watch(versionProvider);
  final p = ref.watch(periodProvider);
  return ref.watch(repoProvider).transactions(p.start, p.end);
});

final uncategorizedCountProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(versionProvider);
  final p = ref.watch(periodProvider);
  return ref.watch(repoProvider).uncategorizedCount(p.start, p.end);
});

final recentTxnsProvider = FutureProvider.autoDispose<List<Txn>>((ref) {
  ref.watch(versionProvider);
  return ref.watch(repoProvider).recent(3);
});

final totalsProvider = FutureProvider.autoDispose<Totals>((ref) {
  ref.watch(versionProvider);
  final p = ref.watch(periodProvider);
  return ref.watch(repoProvider).totals(p.start, p.end);
});

final prevTotalsProvider = FutureProvider.autoDispose<Totals>((ref) {
  ref.watch(versionProvider);
  final s = ref.watch(settingsProvider).startDay;
  final p = periodOf(addMonths(ref.watch(monthProvider), -1), s);
  return ref.watch(repoProvider).totals(p.start, p.end);
});

final categorySpendProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) {
  ref.watch(versionProvider);
  final p = ref.watch(periodProvider);
  return ref.watch(repoProvider).categorySpend(p.start, p.end);
});

final filteredCategorySpendProvider =
    FutureProvider.autoDispose.family<Map<String, int>, Necessity?>((ref, nec) {
  ref.watch(versionProvider);
  final p = ref.watch(periodProvider);
  return ref.watch(repoProvider).categorySpend(p.start, p.end, necessity: nec);
});

final necessitySpendProvider =
    FutureProvider.autoDispose<Map<Necessity, int>>((ref) {
  ref.watch(versionProvider);
  final p = ref.watch(periodProvider);
  return ref.watch(repoProvider).necessitySpend(p.start, p.end);
});

class SeriesPoint {
  final String label;
  final Totals totals;
  const SeriesPoint(this.label, this.totals);
}

/// روند ۶ ماه اخیر تا ماه انتخاب‌شده
final seriesProvider = FutureProvider.autoDispose<List<SeriesPoint>>((ref) async {
  ref.watch(versionProvider);
  final repo = ref.watch(repoProvider);
  final s = ref.watch(settingsProvider).startDay;
  final anchor = ref.watch(monthProvider);
  final out = <SeriesPoint>[];
  for (var i = 5; i >= 0; i--) {
    final a = addMonths(anchor, -i);
    final p = periodOf(a, s);
    out.add(SeriesPoint(monthNames[a.month - 1], await repo.totals(p.start, p.end)));
  }
  return out;
});

// ---------- تشخیص نشتی ----------
class Leak {
  final Category cat;
  final int spent;
  final int baseline; // میانگین ۳ دوره قبل
  final bool overBudget;
  const Leak(this.cat, this.spent, this.baseline, this.overBudget);

  int get excess => overBudget ? spent - cat.budget : spent - baseline;
  int get percent => overBudget
      ? ((spent / cat.budget - 1) * 100).round()
      : ((spent / baseline - 1) * 100).round();
}

final leaksProvider = FutureProvider.autoDispose<List<Leak>>((ref) async {
  ref.watch(versionProvider);
  final repo = ref.watch(repoProvider);
  final s = ref.watch(settingsProvider).startDay;
  final anchor = ref.watch(monthProvider);
  final p = ref.watch(periodProvider);
  final cats = await repo.categories(TxnKind.expense);
  final spend = await repo.categorySpend(p.start, p.end);
  final hist = <Map<String, int>>[];
  for (var i = 1; i <= 3; i++) {
    final h = periodOf(addMonths(anchor, -i), s);
    hist.add(await repo.categorySpend(h.start, h.end));
  }
  final leaks = <Leak>[];
  for (final c in cats) {
    final spent = spend[c.id] ?? 0;
    if (spent <= 0 || !c.leak) continue;
    final avg = hist.fold<int>(0, (a, m) => a + (m[c.id] ?? 0)) ~/ 3;
    if (c.budget > 0 && spent > c.budget) {
      leaks.add(Leak(c, spent, avg, true));
    } else if (avg > 0 && spent >= avg * 1.3 && spent - avg >= 500000) {
      leaks.add(Leak(c, spent, avg, false));
    }
  }
  leaks.sort((a, b) => b.excess.compareTo(a.excess));
  return leaks.take(5).toList();
});

// ---------- پول قابل خرج ----------
class Spendable {
  final int amount;
  final int perDay;
  final int daysLeft;
  const Spendable(this.amount, this.perDay, this.daysLeft);
}

/// قابل‌خرج = جمع موجودی حساب‌ها − بدهی‌های سررسید شونده تا پایان دوره
final spendableProvider = FutureProvider.autoDispose<Spendable>((ref) async {
  ref.watch(versionProvider);
  final repo = ref.watch(repoProvider);
  final p = ref.watch(periodProvider);
  final bal = (await repo.balances()).values.fold<int>(0, (a, b) => a + b);
  final due = await repo.dueDebts(p.end);
  final days =
      max(1, (p.end.difference(DateTime.now()).inHours / 24).ceil());
  final amount = bal - due;
  return Spendable(amount, amount > 0 ? amount ~/ days : 0, days);
});

// ---------- ثروت ----------
final assetsProvider = FutureProvider.autoDispose<List<Asset>>((ref) {
  ref.watch(versionProvider);
  return ref.watch(repoProvider).assets();
});

final debtsProvider =
    FutureProvider.autoDispose.family<List<DebtItem>, DebtDir>((ref, dir) {
  ref.watch(versionProvider);
  return ref.watch(repoProvider).debts(dir);
});

class NetWorth {
  final int accounts, assets, credits, debts;
  const NetWorth(this.accounts, this.assets, this.credits, this.debts);
  int get total => accounts + assets + credits - debts;
}

final netWorthProvider = FutureProvider.autoDispose<NetWorth>((ref) async {
  final bal = await ref.watch(balancesProvider.future);
  final assets = await ref.watch(assetsProvider.future);
  final credits = await ref.watch(debtsProvider(DebtDir.credit).future);
  final debts = await ref.watch(debtsProvider(DebtDir.debt).future);
  return NetWorth(
    bal.values.fold(0, (a, b) => a + b),
    assets.fold(0, (a, b) => a + b.amount),
    credits.fold(0, (a, b) => a + b.remaining),
    debts.fold(0, (a, b) => a + b.remaining),
  );
});
