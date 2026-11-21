import 'dart:io';

import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../core/bank_parser.dart';
import '../data/models.dart';
import '../data/repo.dart';

class SmsSyncResult {
  final bool success;
  final int importedCount;
  final String? message;
  final bool permissionDenied;

  const SmsSyncResult({
    required this.success,
    required this.importedCount,
    this.message,
    this.permissionDenied = false,
  });
}

class SmsSyncService {
  final Repo repo;
  final SmsQuery _query = SmsQuery();
  static const _uuid = Uuid();

  SmsSyncService(this.repo);

  /// بررسی و اجرای همگام‌سازی خودکار یا دستی پیامک‌ها
  Future<SmsSyncResult> sync({bool requestPermission = false, int count = 200}) async {
    // خواندن پیامک فقط در سیستم‌عامل اندروید امکان‌پذیر است
    if (!Platform.isAndroid) {
      return const SmsSyncResult(
        success: false,
        importedCount: 0,
        message: 'خواندن پیامک فقط در سیستم‌عامل اندروید پشتیبانی می‌شود',
      );
    }

    // بررسی مجوز دسترسی به پیامک
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      if (requestPermission) {
        status = await Permission.sms.request();
      }
      if (!status.isGranted) {
        return const SmsSyncResult(
          success: false,
          importedCount: 0,
          permissionDenied: true,
          message: 'دسترسی خواندن پیامک داده نشده است',
        );
      }
    }

    try {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: count,
      );

      final importedIds = await repo.getImportedSmsIds();
      final accounts = await repo.accounts();

      var importedCount = 0;

      for (final msg in messages) {
        final smsId = msg.id != null
            ? '${msg.id}'
            : '${msg.address}_${msg.date?.millisecondsSinceEpoch}_${msg.body?.hashCode}';

        // اگر قبلاً پردازش شده، رد شو
        if (importedIds.contains(smsId)) continue;

        final parsed = BankSmsParser.parse(
          id: smsId,
          body: msg.body ?? '',
          sender: msg.address ?? '',
          date: msg.date ?? DateTime.now(),
        );

        if (parsed == null) continue;

        // پیدا کردن حساب متناظر با این پیامک
        final account = _matchAccount(parsed, accounts);
        if (account == null) continue;

        final txnId = _uuid.v4();
        final txn = Txn(
          id: txnId,
          kind: parsed.kind,
          title: parsed.title,
          amount: parsed.amount,
          categoryId: null, // فیلد دسته طبق درخواست کاربر دقیقاً blank می‌ماند
          accountId: account.id,
          toAccountId: null,
          necessity: Necessity.essential,
          isFixed: false,
          note: parsed.rawBody,
          occurredAt: parsed.occurredAt, // تاریخ دقیق در ماه مربوط به خودش
        );

        await repo.upsertTxn(txn);
        await repo.recordImportedSms(smsId, txnId);
        importedIds.add(smsId);
        importedCount++;
      }

      return SmsSyncResult(
        success: true,
        importedCount: importedCount,
        message: importedCount > 0
            ? '$importedCount تراکنش جدید از پیامک‌ها ثبت شد'
            : 'پیامک بانکی جدیدی یافت نشد',
      );
    } catch (e) {
      return SmsSyncResult(
        success: false,
        importedCount: 0,
        message: 'خطا در خواندن پیامک‌ها: $e',
      );
    }
  }

  /// تطبیق هوشمند پیامک با حساب‌های کاربر در برنامه
  Account? _matchAccount(ParsedBankSms sms, List<Account> accounts) {
    if (accounts.isEmpty) return null;

    // ۱. بررسی تطبیق ۴ رقم آخر کارت
    if (sms.cardSuffix != null && sms.cardSuffix!.isNotEmpty) {
      for (final a in accounts) {
        if (a.cardSuffix.isNotEmpty && a.cardSuffix == sms.cardSuffix) {
          return a;
        }
        if (a.name.contains(sms.cardSuffix!)) {
          return a;
        }
      }
    }

    // ۲. بررسی تطبیق نام بانک در فیلد bank
    for (final a in accounts) {
      if (a.bank.isNotEmpty &&
          (a.bank.contains(sms.bankName) || sms.bankName.contains(a.bank))) {
        return a;
      }
    }

    // ۳. بررسی وجود نام بانک در عنوان حساب (مثل «کارت ملت» -> «بانک ملت»)
    for (final a in accounts) {
      final cleanBank = sms.bankName.replaceAll('بانک', '').trim();
      if (a.name.contains(cleanBank) || a.name.contains(sms.bankName)) {
        return a;
      }
    }

    // ۴. انتخاب پیش‌فرض اولین حساب بانکی
    for (final a in accounts) {
      if (a.kind == 'bank') return a;
    }

    return accounts.first;
  }
}
