import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/persian_date_formatter.dart';
import '../domain/models/activity.dart';
import '../domain/models/activity_entry.dart';

class ActivityExportService {
  Future<void> exportCsv({required List<Activity> activities, required List<ActivityEntry> entries}) async {
    final names = {for (final a in activities) a.id: a.name};
    final rows = <List<String>>[
      ['نام فعالیت', 'تعداد', 'تاریخ شمسی', 'ساعت'],
      ...entries.map((e) => [names[e.activityId] ?? 'فعالیت حذف‌شده', e.count.toString(), PersianDateFormatter.date(e.createdAt), PersianDateFormatter.time(e.createdAt)]),
    ];
    final csv = rows.map((row) => row.map(_escape).join(',')).join('\r\n');
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csv)];
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/activity_report.csv');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'text/csv')], subject: 'گزارش فعالیت‌ها', text: 'گزارش تعداد، تاریخ و ساعت فعالیت‌ها'));
  }
  String _escape(String value) => '"${value.replaceAll('"', '""')}"';
}
