import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

Future<Database> openBaguetteDb(String password) async {
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'baguette.db'),
    password: password,
    version: 3,
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
  if (oldVersion < 3) {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'categories',
      {'deleted': 1, 'updated_at': now},
      where: 'deleted = 0',
    );
    final b = db.batch();
    _seedCategories(b, now);
    await b.commit(noResult: true);
  }
}

void _seedCategories(Batch b, int now) {
  // دسته‌های پیش‌فرض به ترتیب عمومیت و استفاده روزمره (در ادامه بر اساس تکرار انتخاب کاربر مرتب می‌شوند)
  const expense = [
    ['خوراک و خواروبار', '🛒', 1],
    ['رستوران و تیک اوی', '🍔', 1],
    ['قهوه و نوشیدنی', '☕', 1],
    ['حمل و نقل', '🚕', 1],
    ['خرده خرج', '🧾', 1],
    ['قبض و اشتراک', '📱', 1],
    ['مسکن و ساختمان', '🏠', 1],
    ['ماشین', '🚗', 1],
    ['سلامت و درمان', '🩺', 1],
    ['لباس', '👕', 1],
    ['تفریح سرگرمی', '🎮', 1],
    ['خانواده', '👨\u200d👩\u200d👧\u200d👦', 1],
    ['آرایشگاه', '💈', 1],
    ['ورزش', '🏋️', 1],
    ['قسط و بدهی', '🗓️', 0],
    ['پرداخت بدهی', '💳', 0],
    ['تجهیزات کار', '💻', 1],
    ['کلاس و آموزش', '📚', 1],
    ['هدیه و مناسبت', '🎁', 1],
    ['بیمه و مالیات', '🛡️', 0],
    ['خیریه', '🤲', 0],
    ['سفر', '✈️', 1],
    ['حیوان خانگی', '🐾', 1],
  ];
  for (final c in expense) {
    b.insert('categories', {
      'id': _uuid.v4(),
      'name': c[0],
      'kind': 'expense',
      'emoji': c[1],
      'budget': 0,
      'leak': c[2],
      'updated_at': now,
      'deleted': 0,
    });
  }
  const income = [
    ['حقوق', '💼'],
    ['پروژه', '🧑\u200d💻'],
    ['بیزنس', '🏢'],
    ['فروش دارایی', '🏷️'],
    ['سود', '💰'],
    ['اجاره', '🔑'],
    ['سرمایه گذاری', '📈'],
    ['دلالی', '🤝'],
    ['پس گرفتن طلب', '💸'],
  ];
  for (final c in income) {
    b.insert('categories', {
      'id': _uuid.v4(),
      'name': c[0],
      'kind': 'income',
      'emoji': c[1],
      'budget': 0,
      'leak': 0,
      'updated_at': now,
      'deleted': 0,
    });
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
  _seedCategories(b, now);
  await b.commit(noResult: true);
}
