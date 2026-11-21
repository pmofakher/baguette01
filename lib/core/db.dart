import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

Future<Database> openBaguetteDb(String password) async {
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'baguette.db'),
    password: password,
    version: 2,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('''CREATE TABLE IF NOT EXISTS imported_sms(
      sms_id TEXT PRIMARY KEY,
      txn_id TEXT NOT NULL,
      imported_at INTEGER NOT NULL)''');
    try {
      await db.execute("ALTER TABLE accounts ADD COLUMN bank TEXT NOT NULL DEFAULT ''");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE accounts ADD COLUMN card_suffix TEXT NOT NULL DEFAULT ''");
    } catch (_) {}
  }
}

Future<void> _onCreate(Database db, int v) async {
  // ستون‌های id (uuid) و updated_at/deleted از الان برای sync آینده (change-log) آماده‌اند.
  await db.execute('''CREATE TABLE accounts(
    id TEXT PRIMARY KEY, name TEXT NOT NULL, kind TEXT NOT NULL,
    bank TEXT NOT NULL DEFAULT '', card_suffix TEXT NOT NULL DEFAULT '',
    initial_balance INTEGER NOT NULL DEFAULT 0,
    updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0)''');
  await db.execute('''CREATE TABLE categories(
    id TEXT PRIMARY KEY, name TEXT NOT NULL, kind TEXT NOT NULL,
    emoji TEXT NOT NULL, budget INTEGER NOT NULL DEFAULT 0,
    leak INTEGER NOT NULL DEFAULT 1,
    updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0)''');
  await db.execute('''CREATE TABLE transactions(
    id TEXT PRIMARY KEY, kind TEXT NOT NULL, title TEXT NOT NULL DEFAULT '',
    amount INTEGER NOT NULL, category_id TEXT, account_id TEXT NOT NULL,
    to_account_id TEXT, necessity TEXT NOT NULL, is_fixed INTEGER NOT NULL DEFAULT 0,
    note TEXT NOT NULL DEFAULT '', occurred_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0)''');
  await db.execute(
      'CREATE INDEX idx_txn_time ON transactions(occurred_at)');
  await db.execute('''CREATE TABLE assets(
    id TEXT PRIMARY KEY, name TEXT NOT NULL, grp TEXT NOT NULL,
    amount INTEGER NOT NULL, note TEXT NOT NULL DEFAULT '',
    updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0)''');
  await db.execute('''CREATE TABLE debts(
    id TEXT PRIMARY KEY, direction TEXT NOT NULL, person TEXT NOT NULL,
    amount INTEGER NOT NULL, paid INTEGER NOT NULL DEFAULT 0,
    reason TEXT NOT NULL DEFAULT '', due_at INTEGER,
    updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0)''');
  await db.execute(
      'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
  await db.execute('''CREATE TABLE IF NOT EXISTS imported_sms(
    sms_id TEXT PRIMARY KEY,
    txn_id TEXT NOT NULL,
    imported_at INTEGER NOT NULL)''');

  final now = DateTime.now().millisecondsSinceEpoch;
  final b = db.batch();
  for (final a in const [
    ['کارت ملت', 'bank'],
    ['کارت سامان', 'bank'],
    ['پول نقد', 'cash'],
  ]) {
    b.insert('accounts', {
      'id': _uuid.v4(), 'name': a[0], 'kind': a[1],
      'initial_balance': 0, 'updated_at': now, 'deleted': 0,
    });
  }
  // دسته‌های پیش‌فرض (از لیست دسته‌های فیگما). آخرین مقدار = حساب شدن در تشخیص نشتی
  const expense = [
    ['باشگاه', '🏋️', 1], ['لیزر', '✨', 1], ['آرایشگاه', '💈', 1],
    ['لباس', '👕', 1], ['بیرون رفاقتی', '🍔', 1], ['دیت', '❤️', 1],
    ['برنامه', '📱', 1], ['رفت و آمد', '🚌', 1], ['خرده خرج', '🧾', 1],
    ['درمان', '🩺', 1], ['صدقه', '🤲', 0], ['سرمایه‌گذاری', '📈', 0],
    ['پرداخت بدهی', '💳', 0], ['قسط', '🗓️', 0], ['قرض دادن', '🤝', 0],
    ['ماشین', '🚗', 1],
  ];
  for (final c in expense) {
    b.insert('categories', {
      'id': _uuid.v4(), 'name': c[0], 'kind': 'expense', 'emoji': c[1],
      'budget': 0, 'leak': c[2], 'updated_at': now, 'deleted': 0,
    });
  }
  for (final c in const [
    ['حقوق شرکت', '💼'], ['پروژه', '🧑‍💻'], ['سایر درآمدها', '💰'],
  ]) {
    b.insert('categories', {
      'id': _uuid.v4(), 'name': c[0], 'kind': 'income', 'emoji': c[1],
      'budget': 0, 'leak': 0, 'updated_at': now, 'deleted': 0,
    });
  }
  await b.commit(noResult: true);
}
