import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../data/models.dart';

const monthNames = [
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
  'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
];

String groupDigits(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// مبالغ در دیتابیس به ریال ذخیره می‌شوند.
int toDisplay(int rial, Unit u) => u == Unit.toman ? (rial / 10).round() : rial;
int fromDisplay(int v, Unit u) => u == Unit.toman ? v * 10 : v;
String unitLabel(Unit u) => u == Unit.toman ? 'تومان' : 'ریال';

String money(int rial, Unit u, {bool sign = false}) {
  final v = toDisplay(rial, u);
  final pre = v < 0 ? '-' : (sign && v > 0 ? '+' : '');
  return '$pre${groupDigits(v)}';
}

int parseAmount(String s) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  var out = s;
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
  }
  return int.tryParse(out.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue n) {
    if (n.text.isEmpty) return n;
    final t = groupDigits(parseAmount(n.text));
    return TextEditingValue(
        text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

// ---------- تاریخ شمسی ----------
Jalali addMonths(Jalali j, int n) {
  final idx = j.year * 12 + (j.month - 1) + n;
  return Jalali(idx ~/ 12, idx % 12 + 1, 1);
}

String jDate(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return '${j.year}/${j.month}/${j.day}';
}

String hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String dayLabel(DateTime d) {
  final now = DateTime.now();
  final diff = DateTime(now.year, now.month, now.day)
      .difference(DateTime(d.year, d.month, d.day))
      .inDays;
  if (diff == 0) return 'امروز';
  if (diff == 1) return 'دیروز';
  return jDate(d);
}

/// ماه مالی جاری (با احتساب «روز شروع ماه مالی»)
Jalali currentAnchor(int startDay) {
  final j = Jalali.now();
  final first = Jalali(j.year, j.month, 1);
  return j.day < startDay ? addMonths(first, -1) : first;
}

DateTimeRange periodOf(Jalali anchor, int startDay) {
  final n = addMonths(anchor, 1);
  return DateTimeRange(
    start: Jalali(anchor.year, anchor.month, startDay).toDateTime(),
    end: Jalali(n.year, n.month, startDay).toDateTime(),
  );
}

String monthLabel(Jalali a) => '${monthNames[a.month - 1]} ${a.year}';
