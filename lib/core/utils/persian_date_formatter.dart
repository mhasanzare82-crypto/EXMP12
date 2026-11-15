import 'package:shamsi_date/shamsi_date.dart';

class PersianDateFormatter {
  static const _digits = <String>['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
  static String digits(String value) => value.replaceAllMapped(RegExp(r'[0-9]'), (m) => _digits[int.parse(m.group(0)!)]);
  static String date(DateTime value) {
    final j = Jalali.fromDateTime(value);
    return digits('${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}');
  }
  static String time(DateTime value) => digits('${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}');
  static String dateTime(DateTime value) => '${date(value)} - ${time(value)}';
}
