import 'package:flutter/material.dart';
import '../../../../core/utils/persian_date_formatter.dart';
import '../../data/activity_export_service.dart';
import '../../data/activity_repository.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/activity_entry.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repository = ActivityRepository();
  final _exporter = ActivityExportService();
  final _nameController = TextEditingController();
  final _countController = TextEditingController();
  List<Activity> _activities = [];
  List<ActivityEntry> _entries = [];
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _nameController.dispose(); _countController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final a = await _repository.loadActivities();
    final e = await _repository.loadEntries();
    if (!mounted) return;
    setState(() { _activities = a; _entries = e..sort((x, y) => y.createdAt.compareTo(x.createdAt)); _loading = false; });
  }

  Future<void> _addActivity() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_activities.any((a) => a.name.toLowerCase() == name.toLowerCase())) { _message('این فعالیت قبلاً اضافه شده است.'); return; }
    final item = Activity(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name);
    final updated = [..._activities, item];
    await _repository.saveActivities(updated);
    if (!mounted) return;
    setState(() { _activities = updated; _nameController.clear(); });
  }

  Future<void> _addEntry(Activity activity) async {
    _countController.clear();
    final count = await showDialog<int>(context: context, builder: (ctx) => AlertDialog(
      title: Text('ثبت تعداد برای ${activity.name}'),
      content: TextField(controller: _countController, autofocus: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'تعداد انجام‌شده', hintText: 'مثلاً ۲۰', border: OutlineInputBorder())),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')), FilledButton(onPressed: () {
        final value = int.tryParse(_toEnglishDigits(_countController.text.trim()));
        if (value != null && value > 0) Navigator.pop(ctx, value);
      }, child: const Text('ثبت'))],
    ));
    if (count == null) return;
    final entry = ActivityEntry(id: DateTime.now().microsecondsSinceEpoch.toString(), activityId: activity.id, count: count, createdAt: DateTime.now());
    final updated = [entry, ..._entries];
    await _repository.saveEntries(updated);
    if (!mounted) return;
    setState(() => _entries = updated);
    _message('تعداد با موفقیت ثبت شد.');
  }

  String _toEnglishDigits(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹'; const ar = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) { value = value.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i'); }
    return value;
  }
  int _total(String id) => _entries.where((e) => e.activityId == id).fold(0, (sum, e) => sum + e.count);
  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  Future<void> _export() async {
    if (_entries.isEmpty) { _message('هنوز گزارشی برای خروجی گرفتن ثبت نشده است.'); return; }
    setState(() => _exporting = true);
    try { await _exporter.exportCsv(activities: _activities, entries: _entries); }
    catch (e) { if (mounted) _message('تهیه خروجی انجام نشد: $e'); }
    finally { if (mounted) setState(() => _exporting = false); }
  }

  void _showHistory(Activity activity) {
    final records = _entries.where((e) => e.activityId == activity.id).toList();
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (ctx) => SafeArea(child: SizedBox(
      height: MediaQuery.sizeOf(ctx).height * .65,
      child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('تاریخچه ${activity.name}', style: Theme.of(ctx).textTheme.titleLarge), const SizedBox(height: 12),
        Expanded(child: records.isEmpty ? const Center(child: Text('هنوز رکوردی ثبت نشده است.')) : ListView.separated(
          itemCount: records.length, separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) { final e = records[i]; return ListTile(leading: const Icon(Icons.history), title: Text('تعداد: ${PersianDateFormatter.digits(e.count.toString())}'), subtitle: Text(PersianDateFormatter.dateTime(e.createdAt))); },
        )),
      ])),
    )));
  }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('ثبت فعالیت‌ها'), actions: [IconButton(onPressed: _exporting ? null : _export, tooltip: 'خروجی گزارش', icon: _exporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.file_download_outlined))]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('افزودن فعالیت جدید', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 12),
        Row(children: [Expanded(child: TextField(controller: _nameController, textInputAction: TextInputAction.done, onSubmitted: (_) => _addActivity(), decoration: const InputDecoration(hintText: 'نام فعالیت؛ مثلاً مطالعه', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 8), FilledButton.icon(onPressed: _addActivity, icon: const Icon(Icons.add), label: const Text('افزودن'))]),
      ])))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Row(children: [Text('فعالیت‌های من', style: Theme.of(context).textTheme.titleMedium), const Spacer(), Text(PersianDateFormatter.digits('${_activities.length} فعالیت'))])),
      Expanded(child: _activities.isEmpty ? const Center(child: Text('هنوز فعالیتی اضافه نکرده‌ای.')) : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), itemCount: _activities.length, itemBuilder: (_, i) {
        final a = _activities[i];
        return Card(child: ListTile(title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text('مجموع انجام: ${PersianDateFormatter.digits(_total(a.id).toString())}'), onTap: () => _showHistory(a), trailing: Wrap(spacing: 4, children: [IconButton(tooltip: 'تاریخچه', onPressed: () => _showHistory(a), icon: const Icon(Icons.history)), IconButton.filledTonal(tooltip: 'ثبت تعداد', onPressed: () => _addEntry(a), icon: const Icon(Icons.add))])));
      })),
    ]),
    floatingActionButton: _entries.isEmpty ? null : FloatingActionButton.extended(onPressed: _exporting ? null : _export, icon: const Icon(Icons.ios_share), label: const Text('خروجی گزارش')),
  ));
}
