import 'package:sqflite_sqlcipher/sqflite.dart';

import 'models.dart';

const _tables = [
  'accounts',
  'categories',
  'transactions',
  'assets',
  'debts',
  'imported_sms',
];

class Totals {
  final int income;
  final int expense;
  const Totals(this.income, this.expense);
  int get balance => income - expense;
}

class Repo {
  final Database db;
  Repo(this.db);

  int get _now => DateTime.now().millisecondsSinceEpoch;

  Map<String, Object?> _stamp(Map<String, dynamic> m) =>
      {...m, 'updated_at': _now, 'deleted': 0};

  Future<void> _upsert(String table, Map<String, dynamic> m) => db.insert(
      table, _stamp(m),
      conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> _softDelete(String table, String id) => db.update(
      table, {'deleted': 1, 'updated_at': _now},
      where: 'id = ?', whereArgs: [id]);

  // ---------- settings ----------
  Future<Settings> loadSettings() async {
    final rows = await db.query('settings');
    final m = {for (final r in rows) r['key'] as String: r['value'] as String};
    return Settings(
      name: m['name'] ?? '',
      unit: m['unit'] == 'rial' ? Unit.rial : Unit.toman,
      startDay: int.tryParse(m['start_day'] ?? '') ?? 1,
      onboarded: m['onboarded'] == '1',
      autoSmsSync: m['auto_sms_sync'] != '0',
    );
  }

  Future<void> saveSettings(Settings s) async {
    final b = db.batch();
    final kv = {
      'name': s.name,
      'unit': s.unit.name,
      'start_day': '${s.startDay}',
      'onboarded': s.onboarded ? '1' : '0',
      'auto_sms_sync': s.autoSmsSync ? '1' : '0',
    };
    kv.forEach((k, v) => b.insert('settings', {'key': k, 'value': v},
        conflictAlgorithm: ConflictAlgorithm.replace));
    await b.commit(noResult: true);
  }

  // ---------- imported_sms ----------
  Future<Set<String>> getImportedSmsIds() async {
    final rows = await db.query('imported_sms', columns: ['sms_id']);
    return {for (final r in rows) r['sms_id'] as String};
  }

  Future<void> recordImportedSms(String smsId, String txnId) async {
    await db.insert(
      'imported_sms',
      {
        'sms_id': smsId,
        'txn_id': txnId,
        'imported_at': _now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> uncategorizedCount(DateTime from, DateTime to) async {
    final r = await db.rawQuery('''
SELECT COUNT(*) AS c FROM transactions
WHERE deleted=0 AND category_id IS NULL AND occurred_at>=? AND occurred_at<?''',
        [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch]);
    return (r.first['c'] as num?)?.toInt() ?? 0;
  }

  // ---------- accounts ----------
  Future<List<Account>> accounts() async => (await db.query('accounts',
          where: 'deleted = 0', orderBy: 'rowid'))
      .map(Account.fromJson)
      .toList();
  Future<void> upsertAccount(Account a) => _upsert('accounts', a.toJson());
  Future<void> deleteAccount(String id) => _softDelete('accounts', id);

  /// موجودی هر حساب = اولیه + دخل − خرج − انتقال خروجی + انتقال ورودی
  Future<Map<String, int>> balances() async {
    final rows = await db.rawQuery('''
SELECT a.id AS id, a.initial_balance
 + COALESCE((SELECT SUM(amount) FROM transactions t WHERE t.deleted=0 AND t.account_id=a.id AND t.kind='income'),0)
 - COALESCE((SELECT SUM(amount) FROM transactions t WHERE t.deleted=0 AND t.account_id=a.id AND t.kind='expense'),0)
 - COALESCE((SELECT SUM(amount) FROM transactions t WHERE t.deleted=0 AND t.account_id=a.id AND t.kind='transfer'),0)
 + COALESCE((SELECT SUM(amount) FROM transactions t WHERE t.deleted=0 AND t.to_account_id=a.id AND t.kind='transfer'),0) AS bal
FROM accounts a WHERE a.deleted=0''');
    return {for (final r in rows) r['id'] as String: (r['bal'] as num).toInt()};
  }

  // ---------- categories ----------
  /// دسته‌ها بر اساس تعداد دفعات انتخاب در تراکنش‌ها و سپس ترتیب پیش‌فرض مرتب می‌شوند
  Future<List<Category>> categories(TxnKind kind) async =>
      (await db.rawQuery('''
SELECT c.*, (
  SELECT COUNT(*) FROM transactions t
  WHERE t.deleted = 0 AND t.category_id = c.id
) AS usage_count
FROM categories c
WHERE c.deleted = 0 AND c.kind = ?
ORDER BY usage_count DESC, c.rowid ASC''', [kind.name]))
          .map(Category.fromJson)
          .toList();

  Future<List<Category>> allCategories() async =>
      (await db.query('categories')).map(Category.fromJson).toList();

  Future<void> upsertCategory(Category c) => _upsert('categories', c.toJson());
  Future<void> deleteCategory(String id) => _softDelete('categories', id);

  // ---------- transactions ----------
  Future<List<Txn>> transactions(DateTime from, DateTime to) async =>
      (await db.query('transactions',
              where: 'deleted = 0 AND occurred_at >= ? AND occurred_at < ?',
              whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
              orderBy: 'occurred_at DESC'))
          .map(Txn.fromJson)
          .toList();

  Future<List<Txn>> recent(int n) async => (await db.query('transactions',
          where: 'deleted = 0', orderBy: 'occurred_at DESC', limit: n))
      .map(Txn.fromJson)
      .toList();

  Future<Txn?> txn(String id) async {
    final r = await db.query('transactions',
        where: 'id = ? AND deleted = 0', whereArgs: [id], limit: 1);
    return r.isEmpty ? null : Txn.fromJson(r.first);
  }

  Future<void> upsertTxn(Txn t) => _upsert('transactions', t.toJson());
  Future<void> deleteTxn(String id) => _softDelete('transactions', id);

  Future<Totals> totals(DateTime from, DateTime to) async {
    final rows = await db.rawQuery('''
SELECT kind, SUM(amount) AS s FROM transactions
WHERE deleted=0 AND kind IN ('income','expense') AND occurred_at>=? AND occurred_at<?
GROUP BY kind''', [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch]);
    var inc = 0, exp = 0;
    for (final r in rows) {
      final s = (r['s'] as num?)?.toInt() ?? 0;
      if (r['kind'] == 'income') inc = s;
      if (r['kind'] == 'expense') exp = s;
    }
    return Totals(inc, exp);
  }

  Future<Map<String, int>> categorySpend(DateTime from, DateTime to,
      {Necessity? necessity}) async {
    final args = <Object?>[
      from.millisecondsSinceEpoch,
      to.millisecondsSinceEpoch,
    ];
    final necClause = necessity != null ? ' AND necessity=?' : '';
    if (necessity != null) args.add(necessity.name);
    final rows = await db.rawQuery('''
SELECT COALESCE(category_id,'') AS cid, SUM(amount) AS s FROM transactions
WHERE deleted=0 AND kind='expense' AND occurred_at>=? AND occurred_at<?$necClause
GROUP BY cid''', args);
    return {
      for (final r in rows) r['cid'] as String: (r['s'] as num).toInt()
    };
  }

  Future<Map<Necessity, int>> necessitySpend(DateTime from, DateTime to) async {
    final rows = await db.rawQuery('''
SELECT necessity, SUM(amount) AS s FROM transactions
WHERE deleted=0 AND kind='expense' AND occurred_at>=? AND occurred_at<?
GROUP BY necessity''', [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch]);
    return {
      for (final r in rows)
        enumByName(Necessity.values, r['necessity'], Necessity.essential):
            (r['s'] as num).toInt()
    };
  }

  // ---------- assets ----------
  Future<List<Asset>> assets() async =>
      (await db.query('assets', where: 'deleted = 0', orderBy: 'rowid'))
          .map(Asset.fromJson)
          .toList();
  Future<void> upsertAsset(Asset a) => _upsert('assets', a.toJson());
  Future<void> deleteAsset(String id) => _softDelete('assets', id);

  // ---------- debts / credits ----------
  Future<List<DebtItem>> debts(DebtDir dir) async => (await db.query('debts',
          where: 'deleted = 0 AND direction = ?',
          whereArgs: [dir.name],
          orderBy: 'rowid'))
      .map(DebtItem.fromJson)
      .toList();
  Future<void> upsertDebt(DebtItem d) => _upsert('debts', d.toJson());
  Future<void> deleteDebt(String id) => _softDelete('debts', id);

  /// جمع مانده بدهی‌هایی که سررسیدشان قبل از [before] است
  Future<int> dueDebts(DateTime before) async {
    final r = await db.rawQuery('''
SELECT SUM(amount - paid) AS s FROM debts
WHERE deleted=0 AND direction='debt' AND due_at IS NOT NULL AND due_at < ? AND amount > paid''',
        [before.millisecondsSinceEpoch]);
    return (r.first['s'] as num?)?.toInt() ?? 0;
  }

  // ---------- backup ----------
  Future<Map<String, dynamic>> exportAll() async => {
        'app': 'baguette',
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'tables': {for (final t in _tables) t: await db.query(t)},
      };

  Future<void> importAll(Map<String, dynamic> data) async {
    if (data['app'] != 'baguette' || data['tables'] is! Map) {
      throw const FormatException('فایل پشتیبان معتبر نیست');
    }
    final tables = data['tables'] as Map<String, dynamic>;
    await db.transaction((tx) async {
      for (final t in _tables) {
        await tx.delete(t);
        for (final row in (tables[t] as List? ?? const [])) {
          await tx.insert(t, Map<String, Object?>.from(row as Map));
        }
      }
    });
  }
}
