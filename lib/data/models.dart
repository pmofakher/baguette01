enum Unit { toman, rial }

enum TxnKind { income, expense, transfer }

enum Necessity { essential, optional, fun }

enum DebtDir { debt, credit }

enum AssetGroup { bank, gold, crypto, stock, cash, other }

extension TxnKindX on TxnKind {
  String get label => switch (this) {
        TxnKind.income => 'دخل',
        TxnKind.expense => 'خرج',
        TxnKind.transfer => 'انتقال',
      };
}

extension NecessityX on Necessity {
  String get label => switch (this) {
        Necessity.essential => 'واجب',
        Necessity.optional => 'انتخابی',
        Necessity.fun => 'لذت از زندگی',
      };
}

extension AssetGroupX on AssetGroup {
  String get label => switch (this) {
        AssetGroup.bank => 'بانک',
        AssetGroup.gold => 'طلا و سکه',
        AssetGroup.crypto => 'ارز دیجیتال',
        AssetGroup.stock => 'سهام',
        AssetGroup.cash => 'نقد',
        AssetGroup.other => 'سایر',
      };
}

T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

int _i(Object? v) => (v as num?)?.toInt() ?? 0;

class Settings {
  final String name;
  final Unit unit;
  final int startDay;
  final bool onboarded;
  final bool autoSmsSync;
  const Settings({
    this.name = '',
    this.unit = Unit.toman,
    this.startDay = 1,
    this.onboarded = false,
    this.autoSmsSync = true,
  });

  Settings copyWith({
    String? name,
    Unit? unit,
    int? startDay,
    bool? onboarded,
    bool? autoSmsSync,
  }) =>
      Settings(
        name: name ?? this.name,
        unit: unit ?? this.unit,
        startDay: startDay ?? this.startDay,
        onboarded: onboarded ?? this.onboarded,
        autoSmsSync: autoSmsSync ?? this.autoSmsSync,
      );
}

class Account {
  final String id;
  final String name;
  final String kind;
  final String bank;
  final String cardSuffix;
  final int initialBalance;
  const Account({
    required this.id,
    required this.name,
    this.kind = 'bank',
    this.bank = '',
    this.cardSuffix = '',
    this.initialBalance = 0,
  });

  Account copyWith({
    String? name,
    String? kind,
    String? bank,
    String? cardSuffix,
    int? initialBalance,
  }) =>
      Account(
        id: id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        bank: bank ?? this.bank,
        cardSuffix: cardSuffix ?? this.cardSuffix,
        initialBalance: initialBalance ?? this.initialBalance,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind,
        'bank': bank,
        'card_suffix': cardSuffix,
        'initial_balance': initialBalance,
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: (j['kind'] as String?) ?? 'bank',
        bank: (j['bank'] as String?) ?? '',
        cardSuffix: (j['card_suffix'] as String?) ?? '',
        initialBalance: _i(j['initial_balance']),
      );
}

class Category {
  final String id;
  final String name;
  final TxnKind kind;
  final String emoji;
  final int budget; // ریال، ماهانه؛ 0 یعنی بدون بودجه
  final bool leak; // در تشخیص نشتی حساب شود
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    this.emoji = '🏷️',
    this.budget = 0,
    this.leak = true,
  });

  Category copyWith({String? name, String? emoji, int? budget, bool? leak}) =>
      Category(
        id: id,
        name: name ?? this.name,
        kind: kind,
        emoji: emoji ?? this.emoji,
        budget: budget ?? this.budget,
        leak: leak ?? this.leak,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'emoji': emoji,
        'budget': budget,
        'leak': leak ? 1 : 0,
      };

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: enumByName(TxnKind.values, j['kind'], TxnKind.expense),
        emoji: (j['emoji'] as String?) ?? '🏷️',
        budget: _i(j['budget']),
        leak: _i(j['leak']) == 1,
      );
}

class Txn {
  final String id;
  final TxnKind kind;
  final String title;
  final int amount; // همیشه مثبت، به ریال
  final String? categoryId;
  final String accountId;
  final String? toAccountId;
  final Necessity necessity;
  final bool isFixed;
  final String note;
  final DateTime occurredAt;
  const Txn({
    required this.id,
    required this.kind,
    this.title = '',
    required this.amount,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    this.necessity = Necessity.essential,
    this.isFixed = false,
    this.note = '',
    required this.occurredAt,
  });

  Txn copyWith({
    String? id,
    TxnKind? kind,
    String? title,
    int? amount,
    String? categoryId,
    bool clearCategory = false,
    String? accountId,
    String? toAccountId,
    Necessity? necessity,
    bool? isFixed,
    String? note,
    DateTime? occurredAt,
  }) =>
      Txn(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        accountId: accountId ?? this.accountId,
        toAccountId: toAccountId ?? this.toAccountId,
        necessity: necessity ?? this.necessity,
        isFixed: isFixed ?? this.isFixed,
        note: note ?? this.note,
        occurredAt: occurredAt ?? this.occurredAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'amount': amount,
        'category_id': categoryId,
        'account_id': accountId,
        'to_account_id': toAccountId,
        'necessity': necessity.name,
        'is_fixed': isFixed ? 1 : 0,
        'note': note,
        'occurred_at': occurredAt.millisecondsSinceEpoch,
      };

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        id: j['id'] as String,
        kind: enumByName(TxnKind.values, j['kind'], TxnKind.expense),
        title: (j['title'] as String?) ?? '',
        amount: _i(j['amount']),
        categoryId: j['category_id'] as String?,
        accountId: j['account_id'] as String,
        toAccountId: j['to_account_id'] as String?,
        necessity:
            enumByName(Necessity.values, j['necessity'], Necessity.essential),
        isFixed: _i(j['is_fixed']) == 1,
        note: (j['note'] as String?) ?? '',
        occurredAt: DateTime.fromMillisecondsSinceEpoch(_i(j['occurred_at'])),
      );
}

class Asset {
  final String id;
  final String name;
  final AssetGroup group;
  final int amount; // ارزش به ریال
  final String note;
  const Asset({
    required this.id,
    required this.name,
    required this.group,
    required this.amount,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grp': group.name,
        'amount': amount,
        'note': note,
      };

  factory Asset.fromJson(Map<String, dynamic> j) => Asset(
        id: j['id'] as String,
        name: j['name'] as String,
        group: enumByName(AssetGroup.values, j['grp'], AssetGroup.other),
        amount: _i(j['amount']),
        note: (j['note'] as String?) ?? '',
      );
}

class DebtItem {
  final String id;
  final DebtDir direction;
  final String person;
  final int amount;
  final int paid;
  final String reason;
  final DateTime? dueAt;
  const DebtItem({
    required this.id,
    required this.direction,
    required this.person,
    required this.amount,
    this.paid = 0,
    this.reason = '',
    this.dueAt,
  });

  int get remaining => amount - paid;

  Map<String, dynamic> toJson() => {
        'id': id,
        'direction': direction.name,
        'person': person,
        'amount': amount,
        'paid': paid,
        'reason': reason,
        'due_at': dueAt?.millisecondsSinceEpoch,
      };

  factory DebtItem.fromJson(Map<String, dynamic> j) => DebtItem(
        id: j['id'] as String,
        direction: enumByName(DebtDir.values, j['direction'], DebtDir.debt),
        person: j['person'] as String,
        amount: _i(j['amount']),
        paid: _i(j['paid']),
        reason: (j['reason'] as String?) ?? '',
        dueAt: j['due_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(_i(j['due_at'])),
      );
}
