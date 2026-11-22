import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../state/providers.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  Future<void> _syncSms(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('در حال بررسی و خواندن پیامک‌های بانکی...'),
        duration: Duration(seconds: 1),
      ),
    );
    final res =
        await ref.read(smsSyncServiceProvider).sync(requestPermission: true);
    if (res.importedCount > 0) {
      ref.bump();
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(res.message ??
            (res.success ? 'همگام‌سازی انجام شد' : 'خطا در دریافت پیامک‌ها')),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(periodTxnsProvider).valueOrNull ?? [];
    final uncategorized =
        ref.watch(uncategorizedCountProvider).valueOrNull ?? 0;
    final children = <Widget>[];

    if (uncategorized > 0) {
      children.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: BColors.annotation.withAlpha(60),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BColors.annotation, width: 0.8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 20, color: BColors.primaryDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$uncategorized تراکنش وارد شده از پیامک نیازمند تعیین دسته‌اند.',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    String? last;
    for (final t in txns) {
      final label = dayLabel(t.occurredAt);
      if (label != last) {
        if (last != null) {
          children.add(const Padding(
              padding: EdgeInsets.symmetric(vertical: 8), child: Divider()));
        }
        children.add(Padding(
            padding: const EdgeInsets.only(bottom: 4, top: 4),
            child: Text(label, style: const TextStyle(fontSize: 13))));
        last = label;
      }
      children.add(TxnTile(t));
    }
    return Column(children: [
      BTopBar(
        title: 'تراکنش‌ها',
        action: InkWell(
          onTap: () => _syncSms(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: BColors.fabPanel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BColors.annotation, width: 0.8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sms_outlined, size: 16, color: BColors.primaryDark),
                SizedBox(width: 6),
                Text(
                  'وارد کردن تراکنش از sms ها',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: BColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const MonthPager(),
      Expanded(
        child: txns.isEmpty
            ? const Center(child: EmptyState('تراکنشی در این ماه نیست'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
                children: children),
      ),
    ]);
  }
}

class TxnDetailPage extends ConsumerWidget {
  final String id;
  const TxnDetailPage({super.key, required this.id});

  Future<void> _convertToTransfer(BuildContext context, WidgetRef ref, Txn t,
      List<Account> accounts) async {
    final otherAccounts = accounts.where((a) => a.id != t.accountId).toList();
    if (otherAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای انتقال، حداقل به دو حساب در تنظیمات نیاز دارید.'),
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'این جیب به اون جیب (انتقال بین حساب‌ها)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'حساب دیگر را انتخاب کنید. این تراکنش از مخارج/درآمدهای ماه خارج شده و فقط موجودی را جابجا می‌کند:',
                style: TextStyle(fontSize: 12, color: BColors.primary),
              ),
              const SizedBox(height: 16),
              for (final a in otherAccounts)
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(a.name),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final updated = t.copyWith(
                      kind: TxnKind.transfer,
                      toAccountId: a.id,
                      title: 'انتقال بین حساب‌ها',
                      clearCategory: true,
                    );
                    await ref.read(repoProvider).upsertTxn(updated);
                    ref.bump();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'به عنوان انتقال به «${a.name}» (این جیب به اون جیب) ثبت شد'),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(txnProvider(id)).valueOrNull;
    final unit = ref.watch(settingsProvider).unit;
    final cats = ref.watch(categoryMapProvider).valueOrNull ?? {};
    final accountsList = ref.watch(accountsProvider).valueOrNull ?? <Account>[];
    final accs = {for (final a in accountsList) a.id: a.name};
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            SizedBox(
                width: 100,
                child: Text(k, style: const TextStyle(color: BColors.primary))),
            Expanded(child: Text(v)),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('جزئیات تراکنش')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        if (t.kind == TxnKind.transfer)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: BColors.annotation.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BColors.annotation, width: 0.8),
            ),
            child: const Row(
              children: [
                Icon(Icons.swap_horiz, color: BColors.primaryDark),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'این تراکنش «این جیب به اون جیب» است و در جمع مخارج ماه تاثیری ندارد.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        row('نوع:', t.kind == TxnKind.transfer ? 'انتقال (این جیب به اون جیب)' : t.kind.label),
        if (t.title.isNotEmpty) row('عنوان:', t.title),
        if (t.kind != TxnKind.transfer)
          InkWell(
            onTap: () => showQuickCategoryPicker(context, ref, t),
            child: row('دسته:',
                cats[t.categoryId]?.name ?? 'تعیین نشده (لمس برای انتخاب) 🏷️'),
          ),
        if (t.kind == TxnKind.expense) ...[
          row('اهمیت:', t.necessity.label),
          row('نوع خرج:', t.isFixed ? 'ثابت ماهانه' : 'یونیک'),
        ],
        row('مبلغ:', '${money(t.amount, unit)} ${unitLabel(unit)}'),
        row('تاریخ:', jDate(t.occurredAt)),
        row('ساعت:', hm(t.occurredAt)),
        row(t.kind == TxnKind.transfer ? 'از حساب:' : 'حساب:',
            accs[t.accountId] ?? '—'),
        if (t.toAccountId != null) row('به حساب:', accs[t.toAccountId] ?? '—'),
        if (t.note.isNotEmpty) row('توضیحات:', t.note),
        const SizedBox(height: 24),
        if (t.kind != TxnKind.transfer) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: BColors.primaryDark,
            ),
            onPressed: () =>
                _convertToTransfer(context, ref, t, accountsList),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('این جیب به اون جیب (انتقال بین حساب‌ها)'),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(
            onPressed: () => context.push('/txn/edit/${t.id}'),
            child: const Text('ویرایش')),
        const SizedBox(height: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: BColors.expenseText),
          onPressed: () async {
            if (await confirm(context, 'این تراکنش حذف شود؟')) {
              await ref.repo.deleteTxn(t.id);
              ref.bump();
              if (context.mounted) context.pop();
            }
          },
          child: const Text('حذف'),
        ),
      ]),
    );
  }
}

class TxnFormPage extends ConsumerStatefulWidget {
  final String? id;
  final String? kind;
  const TxnFormPage({super.key, this.id, this.kind});
  @override
  ConsumerState<TxnFormPage> createState() => _TxnFormPageState();
}

class _TxnFormPageState extends ConsumerState<TxnFormPage> {
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _note = TextEditingController();
  bool _ready = false;
  late String _id;
  TxnKind _kind = TxnKind.expense;
  String? _cat;
  String? _acc;
  String? _to;
  Necessity _nec = Necessity.essential;
  bool _fixed = false;
  DateTime _dt = DateTime.now();
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = ref.read(repoProvider);
    final unit = ref.read(settingsProvider).unit;
    _accounts = await repo.accounts();
    _id = widget.id ?? const Uuid().v4();
    if (widget.id != null) {
      final t = await repo.txn(widget.id!);
      if (t != null) {
        _kind = t.kind;
        _amount.text = groupDigits(toDisplay(t.amount, unit));
        _title.text = t.title;
        _note.text = t.note;
        _cat = t.categoryId;
        _acc = t.accountId;
        _to = t.toAccountId;
        _nec = t.necessity;
        _fixed = t.isFixed;
        _dt = t.occurredAt;
      }
    } else {
      _kind = enumByName(TxnKind.values, widget.kind, TxnKind.expense);
    }
    _acc ??= _accounts.isNotEmpty ? _accounts.first.id : null;
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _msg(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _save() async {
    final unit = ref.read(settingsProvider).unit;
    final amount = fromDisplay(parseAmount(_amount.text), unit);
    if (amount <= 0) return _msg('مبلغ را وارد کن');
    if (_acc == null) return _msg('یک حساب انتخاب کن');
    if (_kind != TxnKind.transfer && _cat == null) {
      return _msg('یک دسته انتخاب کن');
    }
    if (_kind == TxnKind.transfer && (_to == null || _to == _acc)) {
      return _msg('حساب مقصد باید با مبدأ فرق داشته باشد');
    }
    await ref.repo.upsertTxn(Txn(
      id: _id,
      kind: _kind,
      title: _title.text.trim(),
      amount: amount,
      categoryId: _kind == TxnKind.transfer ? null : _cat,
      accountId: _acc!,
      toAccountId: _kind == TxnKind.transfer ? _to : null,
      necessity: _kind == TxnKind.expense ? _nec : Necessity.essential,
      isFixed: _kind == TxnKind.expense && _fixed,
      note: _note.text.trim(),
      occurredAt: _dt,
    ));
    ref.bump();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final unit = ref.watch(settingsProvider).unit;
    final cats = _kind == TxnKind.transfer
        ? <Category>[]
        : ref.watch(categoriesProvider(_kind)).valueOrNull ?? [];

    DropdownButtonFormField<String> accDrop(
            String label, String? v, ValueChanged<String?> on) =>
        DropdownButtonFormField<String>(
          value: v,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final a in _accounts)
              DropdownMenuItem(value: a.id, child: Text(a.name))
          ],
          onChanged: on,
        );

    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null ? 'تراکنش جدید' : 'ویرایش تراکنش')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        SegmentedButton<TxnKind>(
          showSelectedIcon: false,
          segments: [
            for (final k in TxnKind.values)
              ButtonSegment(value: k, label: Text(k.label))
          ],
          selected: {_kind},
          onSelectionChanged: (s) => setState(() {
            _kind = s.first;
            _cat = null;
          }),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          inputFormatters: [ThousandsFormatter()],
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          decoration: InputDecoration(labelText: 'مبلغ', suffixText: unitLabel(unit)),
        ),
        const SizedBox(height: 14),
        TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'عنوان (اختیاری)')),
        const SizedBox(height: 14),
        if (_kind != TxnKind.transfer) ...[
          const Text('دسته'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in cats)
              ChoiceChip(
                label: Text('${c.emoji} ${c.name}'),
                selected: _cat == c.id,
                onSelected: (_) => setState(() => _cat = c.id),
              ),
          ]),
          const SizedBox(height: 14),
        ],
        accDrop(_kind == TxnKind.transfer ? 'از حساب' : 'حساب', _acc,
            (v) => setState(() => _acc = v)),
        if (_kind == TxnKind.transfer) ...[
          const SizedBox(height: 14),
          accDrop('به حساب', _to, (v) => setState(() => _to = v)),
        ],
        if (_kind == TxnKind.expense) ...[
          const SizedBox(height: 14),
          const Text('اهمیت این خرج'),
          const SizedBox(height: 8),
          SegmentedButton<Necessity>(
            showSelectedIcon: false,
            segments: [
              for (final n in Necessity.values)
                ButtonSegment(value: n, label: Text(n.label, style: const TextStyle(fontSize: 12)))
            ],
            selected: {_nec},
            onSelectionChanged: (s) => setState(() => _nec = s.first),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('خرج ثابت ماهانه'),
            value: _fixed,
            onChanged: (v) => setState(() => _fixed = v),
          ),
        ],
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: Text(jDate(_dt)),
              onPressed: () async {
                final d = await showJalaliPicker(context, _dt);
                if (d != null) {
                  setState(() =>
                      _dt = DateTime(d.year, d.month, d.day, _dt.hour, _dt.minute));
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.schedule),
              label: Text(hm(_dt)),
              onPressed: () async {
                final t = await showTimePicker(
                    context: context, initialTime: TimeOfDay.fromDateTime(_dt));
                if (t != null) {
                  setState(() => _dt =
                      DateTime(_dt.year, _dt.month, _dt.day, t.hour, t.minute));
                }
              },
            ),
          ),
        ]),
        const SizedBox(height: 14),
        TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'توضیحات')),
        const SizedBox(height: 24),
        FilledButton(onPressed: _save, child: const Text('ذخیره')),
      ]),
    );
  }
}
