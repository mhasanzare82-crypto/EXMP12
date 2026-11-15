import 'package:exm1/core/utils/persian_date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersianDateFormatter', () {
    test('converts western digits to Persian digits', () {
      expect(PersianDateFormatter.digits('Working 2026'), 'Working ۲۰۲۶');
    });

    test('formats Gregorian date as Jalali date', () {
      expect(
        PersianDateFormatter.date(DateTime(2024, 3, 20)),
        '۱۴۰۳/۰۱/۰۱',
      );
    });

    test('formats time with Persian digits and two-digit fields', () {
      expect(
        PersianDateFormatter.time(DateTime(2026, 11, 5, 8, 4)),
        '۰۸:۰۴',
      );
    });
  });
}
