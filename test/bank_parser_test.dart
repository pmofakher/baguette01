import 'package:baguette/core/bank_parser.dart';
import 'package:baguette/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BankSmsParser', () {
    test('parses Mellat withdrawal', () {
      const sms = 'بانک ملت\nبرداشت مبلغ ۲۵۰,۰۰۰ ریال\nاز حساب ...۱۲۳۴\nمانده: ۱۵,۲۰۰,۰۰۰ ریال\n۱۴۰۳/۰۸/۲۵ ۱۲:۴۵';
      final res = BankSmsParser.parse(
        id: '1',
        body: sms,
        sender: 'Bank Mellat',
        date: DateTime(2024, 11, 15),
      );

      expect(res, isNotNull);
      expect(res!.bankName, 'بانک ملت');
      expect(res.kind, TxnKind.expense);
      expect(res.amount, 250000);
      expect(res.cardSuffix, '1234');
      expect(res.balance, 15200000);
      expect(res.occurredAt.year, isNotNull);
    });

    test('parses BluBank purchase in Tomans', () {
      const sms = 'بلوبانک\nخرید ۵۰,۰۰۰ تومان\nکارت: ۸۷۶۵\nمانده: ۳۴۵,۰۰۰ تومان';
      final res = BankSmsParser.parse(
        id: '2',
        body: sms,
        sender: 'BLUBANK',
        date: DateTime(2024, 11, 16),
      );

      expect(res, isNotNull);
      expect(res!.bankName, 'بلوبانک');
      expect(res.kind, TxnKind.expense);
      expect(res.amount, 500000); // 50,000 Tomans = 500,000 Rials
      expect(res.cardSuffix, '8765');
      expect(res.balance, 3450000);
    });

    test('parses Melli deposit with + sign', () {
      const sms = 'بانک ملی ایران\nواریز: ۲,۰۰۰,۰۰۰+ ریال\nحساب ...۴۳۲۱\nمانده: ۱۲,۰۰۰,۰۰۰';
      final res = BankSmsParser.parse(
        id: '3',
        body: sms,
        sender: 'BMI',
        date: DateTime(2024, 11, 17),
      );

      expect(res, isNotNull);
      expect(res!.bankName, 'بانک ملی');
      expect(res.kind, TxnKind.income);
      expect(res.amount, 2000000);
      expect(res.cardSuffix, '4321');
    });

    test('parses Saman deduction', () {
      const sms = 'بانک سامان\nکسر شد: ۸۰۰,۰۰۰ ریال\nکارت ۵۶۷۸\nمانده: ۲,۰۰۰,۰۰۰ ریال';
      final res = BankSmsParser.parse(
        id: '6',
        body: sms,
        sender: 'Saman',
        date: DateTime(2024, 11, 18),
      );

      expect(res, isNotNull);
      expect(res!.bankName, 'بانک سامان');
      expect(res.kind, TxnKind.expense);
      expect(res.amount, 800000);
      expect(res.cardSuffix, '5678');
    });

    test('parses Pasargad transfer with date', () {
      const sms = 'بانک پاسارگاد\nانتقال از حساب ...۹۰۱۲\nمبلغ: ۱,۵۰۰,۰۰۰ ریال\n۱۴۰۳/۰۹/۰۱ ۱۴:۲۰';
      final res = BankSmsParser.parse(
        id: '7',
        body: sms,
        sender: 'BPI',
        date: DateTime(2024, 11, 1),
      );

      expect(res, isNotNull);
      expect(res!.bankName, 'بانک پاسارگاد');
      expect(res.kind, TxnKind.expense);
      expect(res.amount, 1500000);
      expect(res.cardSuffix, '9012');
      expect(res.occurredAt.hour, 14);
      expect(res.occurredAt.minute, 20);
    });

    test('ignores OTP messages', () {
      const sms = 'رمز یکبار مصرف شما: ۱۲۳۴۵۶ بانک سامان';
      final res = BankSmsParser.parse(
        id: '4',
        body: sms,
        sender: 'Saman',
        date: DateTime.now(),
      );

      expect(res, isNull);
    });

    test('ignores failed transactions', () {
      const sms = 'بانک صادرات: تراکنش ناموفق مبلغ ۱۰۰,۰۰۰ ریال';
      final res = BankSmsParser.parse(
        id: '5',
        body: sms,
        sender: 'BSI',
        date: DateTime.now(),
      );

      expect(res, isNull);
    });
  });
}
