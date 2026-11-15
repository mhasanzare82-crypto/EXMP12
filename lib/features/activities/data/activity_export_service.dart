import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/persian_date_formatter.dart';
import '../domain/models/activity.dart';
import '../domain/models/activity_entry.dart';
import '../domain/models/activity_folder.dart';

class ActivityExportService {
  Future<void> exportExcel({
    required List<Activity> activities,
    required List<ActivityEntry> entries,
    required List<ActivityFolder> folders,
  }) async {
    final names = {for (final activity in activities) activity.id: activity.name};
    final folderNames = {for (final folder in folders) folder.id: folder.name};
    final excel = Excel.createExcel();
    final sheet = excel['گزارش فعالیت‌ها'];
    sheet.appendRow([
      TextCellValue('نام فعالیت'),
      TextCellValue('پوشه'),
      TextCellValue('تعداد'),
      TextCellValue('تاریخ شمسی'),
      TextCellValue('ساعت'),
      TextCellValue('دلیل'),
    ]);

    for (final entry in entries) {
      final activity = activities.where((item) => item.id == entry.activityId);
      final folderName = activity.isEmpty || activity.first.folderId == null
          ? 'بدون پوشه'
          : folderNames[activity.first.folderId] ?? 'بدون پوشه';
      sheet.appendRow([
        TextCellValue(names[entry.activityId] ?? 'فعالیت حذف‌شده'),
        TextCellValue(folderName),
        IntCellValue(entry.count),
        TextCellValue(PersianDateFormatter.date(entry.createdAt)),
        TextCellValue(PersianDateFormatter.time(entry.createdAt)),
        TextCellValue(entry.reason ?? 'بدون دلیل'),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) throw StateError('ساخت فایل Excel ناموفق بود.');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/activity_report.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'گزارش اکسل فعالیت‌ها',
      text: 'گزارش فعالیت‌ها شامل تعداد، پوشه، تاریخ، ساعت و دلیل ثبت',
    ));
  }
}
