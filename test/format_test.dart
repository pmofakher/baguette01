import 'package:baguette/core/format.dart';
import 'package:baguette/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groupDigits', () {
    expect(groupDigits(8700000), '8,700,000');
    expect(groupDigits(950), '950');
  });
  test('parseAmount handles Persian digits and separators', () {
    expect(parseAmount('۱۲,۵۰۰'), 12500);
    expect(parseAmount(''), 0);
  });
  test('unit conversion', () {
    expect(fromDisplay(1000, Unit.toman), 10000);
    expect(toDisplay(10000, Unit.toman), 1000);
    expect(money(-87000, Unit.toman), '-8,700');
  });
  test('necessity labels', () {
    expect(Necessity.essential.label, 'واجب');
    expect(Necessity.optional.label, 'انتخابی');
    expect(Necessity.fun.label, 'لذت از زندگی');
  });
}
