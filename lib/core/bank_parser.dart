import 'package:shamsi_date/shamsi_date.dart';

import '../data/models.dart';

class ParsedBankSms {
  final String smsId;
  final String rawBody;
  final String sender;
  final DateTime smsDate;
  final String bankName;
  final TxnKind kind;
  final int amount; // به ریال
  final String? cardSuffix; // ۴ رقم آخر
  final String? toCardSuffix; // ۴ رقم آخر کارت مقصد (در صورت وجود برای انتقال)
  final int? balance; // مانده به ریال در صورت وجود
  final DateTime occurredAt;
  final String title;

  const ParsedBankSms({
    required this.smsId,
    required this.rawBody,
    required this.sender,
    required this.smsDate,
    required this.bankName,
    required this.kind,
    required this.amount,
    this.cardSuffix,
    this.toCardSuffix,
    this.balance,
    required this.occurredAt,
    required this.title,
  });
}

class BankSmsParser {
  static const _banks = [
    ('بلوبانک', ['بلو', 'بلوبانک', 'blubank', 'blu']),
    ('بانک ملت', ['بانک ملت', 'ملت', 'mellat']),
    ('بانک ملی', ['بانک ملی', 'ملی ایران', 'bmi', 'سامانه بام', 'بام ملی']),
    ('بانک سامان', ['بانک سامان', 'سامان', 'saman']),
    ('بانک پاسارگاد', ['بانک پاسارگاد', 'پاسارگاد', 'pasargad', 'bpi', 'ویپاد', 'wepod']),
    ('بانک رسالت', ['بانک رسالت', 'رسالت', 'resalat', 'قرض الحسنه رسالت']),
    ('بانک تجارت', ['بانک تجارت', 'تجارت', 'tejarat', 'باجت']),
    ('بانک صادرات', ['بانک صادرات', 'صادرات', 'saderat', 'bsi', 'سپهر صادرات']),
    ('بانک سپه', ['بانک سپه', 'سپه', 'sepah', 'انصار', 'قوامین', 'حکمت ایرانیان', 'کوثر', 'مهر اقتصاد']),
    ('بانک آینده', ['بانک آینده', 'آینده', 'ayandeh', 'آبانک', 'abank', 'کیلید']),
    ('بانک پارسیان', ['بانک پارسیان', 'پارسیان', 'parsian', 'توبانک']),
    ('بانک شهر', ['بانک شهر', 'شهر', 'shahr', 'شهرزاد']),
    ('بانک رفاه', ['بانک رفاه', 'رفاه', 'refah', 'رفاه کارگران']),
    ('بانک کشاورزی', ['بانک کشاورزی', 'کشاورزی', 'agri', 'keshavarzi', 'بکاپ']),
    ('بانک مسکن', ['بانک مسکن', 'مسکن', 'maskan']),
    ('بانک اقتصاد نوین', ['بانک اقتصاد نوین', 'اقتصاد نوین', 'enbank', 'en bank']),
    ('بانک مهر ایران', ['بانک مهر ایران', 'مهر ایران', 'qmb', 'مهرایران', 'مهرایرانیان']),
    ('بانک سینا', ['بانک سینا', 'سینا', 'sina']),
    ('بانک کارآفرین', ['بانک کارآفرین', 'کارآفرین', 'karafarin']),
    ('پست بانک', ['پست بانک', 'postbank', 'post bank']),
    ('بانک گردشگری', ['بانک گردشگری', 'گردشگری', 'tourism bank', 'tourismbank']),
    ('بانک دی', ['بانک دی', 'دی', 'day bank', 'daybank']),
    ('بانک سرمایه', ['بانک سرمایه', 'سرمایه', 'sarmayeh']),
    ('بانک ایران زمین', ['بانک ایران زمین', 'ایران زمین', 'iranzamin', 'فراز']),
    ('بانک توسعه تعاون', ['بانک توسعه تعاون', 'توسعه تعاون', 'ttbank', 'tt bank']),
    ('بانک خاورمیانه', ['بانک خاورمیانه', 'خاورمیانه', 'middle east', 'mebank']),
    ('بانک صنعت و معدن', ['بانک صنعت و معدن', 'صنعت و معدن', 'bim']),
    ('بانک توسعه صادرات', ['بانک توسعه صادرات', 'توسعه صادرات', 'edbi']),
    ('بانک مشترک ایران و ونزوئلا', ['ایران و ونزوئلا', 'ivbb']),
    ('بانک مرکزی', ['بانک مرکزی', 'cbi']),
    ('موسسه ملل', ['موسسه ملل', 'ملل', 'askariyeh', 'عسکریه']),
    ('موسسه نور', ['موسسه نور', 'نور']),
  ];

  static String normalize(String s) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    var out = s
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('\u200c', ' ')
        .replaceAll('\u200f', '')
        .replaceAll('،', ',');
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
    }
    return out;
  }

  /// تشخیص می‌دهد که آیا این پیامک یک تراکنش بانکی معتبر است یا خیر
  static ParsedBankSms? parse({
    required String id,
    required String body,
    required String sender,
    required DateTime date,
  }) {
    if (body.trim().isEmpty) return null;
    final norm = normalize(body);
    final normLower = norm.toLowerCase();
    final senderLower = sender.toLowerCase();

    // فیلتر کردن پیامک‌های رمز پویا، کد فعال‌سازی، پیام‌های ورود و پیام‌های تبلیغاتی
    if (_isIgnored(normLower)) return null;

    // تشخیص بانک
    final bank = _detectBank(normLower, senderLower);
    final isBankSender = _isBankSender(normLower, senderLower, bank != null);
    if (!isBankSender && bank == null) {
      return null; // نه نام بانک دارد و نه به نظر پیامک بانکی می‌آید
    }

    final finalBankName = bank ?? 'بانک';

    // تشخیص نوع تراکنش (دخل یا خرج)
    final kind = _detectKind(normLower);
    if (kind == null) return null;

    // استخراج مانده موجودی (اگر باشد، تا با مبلغ تراکنش اشتباه گرفته نشود)
    final balance = _extractBalance(norm);

    // استخراج مبلغ تراکنش
    final amount = _extractAmount(norm, kind);
    if (amount == null || amount <= 0) return null;

    // استخراج ۴ رقم آخر کارت یا حساب
    final cardSuffix = _extractCardSuffix(norm);
    final toCardSuffix = _extractToCardSuffix(norm);

    // استخراج تاریخ و ساعت از متن پیامک (در صورت وجود، وگرنه زمان پیامک)
    final occurredAt = _extractDateTime(norm, date);

    final title = switch (kind) {
      TxnKind.expense => cardSuffix != null
          ? 'برداشت $finalBankName ($cardSuffix)'
          : 'برداشت $finalBankName',
      TxnKind.income => cardSuffix != null
          ? 'واریز $finalBankName ($cardSuffix)'
          : 'واریز $finalBankName',
      _ => finalBankName,
    };

    return ParsedBankSms(
      smsId: id,
      rawBody: body,
      sender: sender,
      smsDate: date,
      bankName: finalBankName,
      kind: kind,
      amount: amount,
      cardSuffix: cardSuffix,
      toCardSuffix: toCardSuffix,
      balance: balance,
      occurredAt: occurredAt,
      title: title,
    );
  }

  static bool _isIgnored(String s) {
    if (s.contains('رمز پویا') ||
        s.contains('رمز یکبار مصرف') ||
        s.contains('کد تایید') ||
        s.contains('کد فعالسازی') ||
        s.contains('ورود به همراه بانک') ||
        s.contains('ورود به اینترنت بانک') ||
        s.contains('ورود به سامانه') ||
        s.contains('تراکنش ناموفق') ||
        s.contains('تراکنش انجام نشد') ||
        s.contains('خطا در تراکنش') ||
        s.contains('موجودی ناکافی')) {
      return true;
    }
    return false;
  }

  static String? _detectBank(String text, String sender) {
    for (final item in _banks) {
      for (final kw in item.$2) {
        if (_matchesKeyword(text, sender, kw)) {
          return item.$1;
        }
      }
    }
    return null;
  }

  static bool _matchesKeyword(String text, String sender, String kw) {
    if (sender.contains(kw)) return true;
    if (kw.length > 3) {
      return text.contains(kw);
    }
    // بررسی مرز کلمه برای واژه‌های کوتاه نظیر «بلو»، «دی»، «شهر»
    final pat = RegExp('(^|[^a-zA-Z0-9آ-ی])${RegExp.escape(kw)}([^a-zA-Z0-9آ-ی]|\$)');
    return pat.hasMatch(text);
  }

  static bool _isBankSender(String text, String sender, bool hasBankName) {
    if (hasBankName) return true;
    if (sender.startsWith('+982000') ||
        sender.startsWith('982000') ||
        sender.startsWith('2000') ||
        sender.startsWith('+981000') ||
        sender.startsWith('1000') ||
        sender.startsWith('+983000') ||
        sender.startsWith('3000') ||
        sender.startsWith('+9898') ||
        sender.startsWith('9898') ||
        sender.startsWith('4040')) {
      return text.contains('حساب') ||
          text.contains('کارت') ||
          text.contains('برداشت') ||
          text.contains('واریز') ||
          text.contains('موجودی') ||
          text.contains('مانده');
    }
    return false;
  }

  static TxnKind? _detectKind(String text) {
    // نشانه‌های واریز
    final hasIncome = text.contains('واریز') ||
        text.contains('حقوق') ||
        text.contains('سود سپرده') ||
        text.contains('افزوده شد') ||
        text.contains('به حساب شما') ||
        text.contains('برگشت وجه') ||
        text.contains('اصلاحیه واریز');

    // نشانه‌های برداشت
    final hasExpense = text.contains('برداشت') ||
        text.contains('خرید') ||
        text.contains('کسر شد') ||
        text.contains('انتقال از') ||
        text.contains('کارمزد') ||
        text.contains('قسط') ||
        text.contains('صورتحساب') ||
        text.contains('پرداخت قبض') ||
        text.contains('انتقال به') ||
        text.contains('پایا به') ||
        text.contains('ساتنا به');

    if (hasExpense && !hasIncome) return TxnKind.expense;
    if (hasIncome && !hasExpense) return TxnKind.income;

    // بررسی علامت‌های + یا - در کنار اعداد
    if (RegExp(r'\+\s*[\d,]+|[\d,]+\s*\+').hasMatch(text)) {
      return TxnKind.income;
    }
    if (RegExp(r'-\s*[\d,]+|[\d,]+\s*-').hasMatch(text)) {
      return TxnKind.expense;
    }

    if (hasExpense) return TxnKind.expense;
    if (hasIncome) return TxnKind.income;

    return null;
  }

  static int? _extractBalance(String norm) {
    final m = RegExp(
            r'(?:مانده|موجودی|مانده حساب|موجودی جدید)[\s:]*([0-9,]+)\s*(ریال|تومان|ت)?')
        .firstMatch(norm);
    if (m != null) {
      final raw = m.group(1)?.replaceAll(',', '') ?? '';
      final val = int.tryParse(raw);
      if (val != null) {
        final unit = m.group(2);
        return (unit == 'تومان' || unit == 'ت') ? val * 10 : val;
      }
    }
    return null;
  }

  static int? _extractAmount(String norm, TxnKind kind) {
    // برای اینکه مبلغ تراکنش با مانده یا موجودی اشتباه نشود، بخش مانده را موقتاً ماسک می‌کنیم
    final masked = norm.replaceAll(
        RegExp(r'(?:مانده|موجودی|مانده حساب)[\s:]*[0-9,]+\s*(?:ریال|تومان|ت)?'),
        '');

    // ۱. جستجوی الگوهای واضح مثل «مبلغ: ... ریال» یا «برداشت ... ریال»
    final patterns = [
      RegExp(r'(?:مبلغ|خرید|برداشت|واریز|کسر|انتقال)[\s:]*([0-9,]+)\s*(ریال|تومان|ت)?'),
      RegExp(r'([0-9,]+)\s*(ریال|تومان)'),
      RegExp(r'(?:[+-]\s*)([0-9,]+)\s*(ریال|تومان|ت)?'),
      RegExp(r'([0-9,]+)\s*[+-]'),
    ];

    for (final pat in patterns) {
      final matches = pat.allMatches(masked);
      for (final m in matches) {
        final raw = m.group(1)?.replaceAll(',', '') ?? '';
        final val = int.tryParse(raw);
        if (val != null && val > 0) {
          // بررسی اینکه آیا ۴ رقم است و احتمالاً کارت نباشد
          if (val < 1000 && !m.group(0)!.contains('تومان') && !m.group(0)!.contains('ریال')) {
            continue;
          }
          final unit = m.groupCount >= 2 ? m.group(2) : null;
          final isToman = unit == 'تومان' || unit == 'ت';
          return isToman ? val * 10 : val;
        }
      }
    }

    // fallback: جستجوی هر عدد بالای ۱۰۰۰ که در متن وجود دارد
    final numMatches = RegExp(r'\b([0-9]{1,3}(?:,[0-9]{3})+|[0-9]{4,})\b').allMatches(masked);
    for (final m in numMatches) {
      final raw = m.group(1)?.replaceAll(',', '') ?? '';
      final val = int.tryParse(raw);
      if (val != null && val >= 1000) {
        return val;
      }
    }

    return null;
  }

  static String? _extractCardSuffix(String norm) {
    // الگوهای کارت یا حساب
    final patterns = [
      RegExp(r'(?:از\s+کارت|از\s+حساب|از\s+سپرده|کارت|حساب|سپرده|از)[\s:.*xX-]*([0-9]{4})\b'),
      RegExp(r'(?:\*{2,}|[xX]{2,}|\.{2,})([0-9]{4})\b'),
      RegExp(r'\b[0-9]{4}[-*.]{1,4}([0-9]{4})\b'),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(norm);
      if (m != null) {
        return m.group(1);
      }
    }
    return null;
  }

  static String? _extractToCardSuffix(String norm) {
    final patterns = [
      RegExp(r'(?:به\s+کارت|به\s+حساب|به\s+سپرده|مقصد)[\s:.*xX-]*([0-9]{4})\b'),
      RegExp(r'\bبه[\s:.*xX-]*([0-9]{4})\b'),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(norm);
      if (m != null) {
        return m.group(1);
      }
    }
    return null;
  }

  static DateTime _extractDateTime(String norm, DateTime fallback) {
    try {
      // جستجوی تاریخ شمسی مثل 1403/08/25 یا 1403-08-25 یا 03/08/25
      final dateMatch = RegExp(r'\b(14[0-9]{2}|[0-9]{2})[/-]([0-9]{1,2})[/-]([0-9]{1,2})\b').firstMatch(norm);
      final timeMatch = RegExp(r'\b([0-9]{1,2}):([0-9]{2})(?::([0-9]{2}))?\b').firstMatch(norm);

      if (dateMatch != null) {
        var y = int.parse(dateMatch.group(1)!);
        if (y < 100) y += 1400;
        final m = int.parse(dateMatch.group(2)!);
        final d = int.parse(dateMatch.group(3)!);

        var h = fallback.hour;
        var min = fallback.minute;
        var sec = fallback.second;

        if (timeMatch != null) {
          h = int.parse(timeMatch.group(1)!);
          min = int.parse(timeMatch.group(2)!);
          if (timeMatch.group(3) != null) {
            sec = int.parse(timeMatch.group(3)!);
          }
        }

        if (m >= 1 && m <= 12 && d >= 1 && d <= 31) {
          final j = Jalali(y, m, d);
          final g = j.toDateTime();
          return DateTime(g.year, g.month, g.day, h, min, sec);
        }
      }
    } catch (_) {}

    return fallback;
  }
}
