import 'package:material_ui/material_ui.dart';
import '../../../../core/utils/persian_date_formatter.dart';
import '../../data/activity_export_service.dart';
import '../../data/activity_repository.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/activity_entry.dart';
import '../../domain/models/activity_folder.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _unfiledValue = '__unfiled__';
  final _repository = ActivityRepository();
  final _exporter = ActivityExportService();
  final _nameController = TextEditingController();
  final _countController = TextEditingController();
  List<Activity> _activities = [];
  List<ActivityEntry> _entries = [];
  List<ActivityFolder> _folders = [];
  String? _selectedFolderId;
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final activities = await _repository.loadActivities();
    final entries = await _repository.loadEntries();
    final folders = await _repository.loadFolders();
    if (!mounted) return;
    setState(() {
      _activities = activities;
      _entries = entries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _folders = folders;
      _loading = false;
    });
  }

  Future<void> _addActivity() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_activities.any((a) => a.name.toLowerCase() == name.toLowerCase())) {
      _message('این فعالیت قبلاً اضافه شده است.');
      return;
    }
    final item = Activity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      folderId: _selectedFolderId,
    );
    final updated = [..._activities, item];
    await _repository.saveActivities(updated);
    if (!mounted) return;
    setState(() { _activities = updated; _nameController.clear(); });
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ساخت پوشه جدید'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
          decoration: const InputDecoration(
            labelText: 'نام پوشه',
            hintText: 'مثلاً کار، ورزش یا مطالعه',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('ساخت پوشه'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    if (_folders.any((f) => f.name.toLowerCase() == name.toLowerCase())) {
      _message('پوشه‌ای با این نام وجود دارد.');
      return;
    }
    final folder = ActivityFolder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
    );
    final updated = [..._folders, folder];
    await _repository.saveFolders(updated);
    if (!mounted) return;
    setState(() { _folders = updated; _selectedFolderId = folder.id; });
    _message('پوشه ساخته شد. فعالیت‌های جدید در همین پوشه قرار می‌گیرند.');
  }

  Future<void> _moveActivity(Activity activity, String destination) async {
    final moved = destination == _unfiledValue
        ? activity.copyWith(clearFolder: true)
        : activity.copyWith(folderId: destination);
    final updated = _activities
        .map((item) => item.id == activity.id ? moved : item)
        .toList();
    await _repository.saveActivities(updated);
    if (!mounted) return;
    setState(() => _activities = updated);
  }

  Future<String?> _askReason() async {
    final hasReason = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('دلیل ثبت این تعداد'),
        content: const Text('آیا این ثبت دلیل یا توضیحی دارد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('بدون دلیل'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('بله، با دلیل'),
          ),
        ],
      ),
    );
    if (hasReason == null) return null;
    if (!hasReason) return '';

    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ثبت دلیل'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'دلیل یا توضیح این ثبت را بنویسید',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(ctx, value);
            },
            child: const Text('ثبت دلیل'),
          ),
        ],
      ),
    );
    controller.dispose();
    return reason?.trim().isEmpty == true ? null : reason?.trim();
  }

  Future<void> _addQuickEntry(Activity activity) async {
    final reason = await _askReason();
    if (reason == null) return;
    await _saveEntry(activity, 1, reason: reason);
    if (mounted) _message('یک عدد برای «' + activity.name + '» ثبت شد.');
  }

  Future<void> _addEntry(Activity activity) async {
    _countController.clear();
    final count = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ثبت تعداد برای ' + activity.name),
        content: TextField(
          controller: _countController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'تعداد انجام‌شده',
            hintText: 'مثلاً ۲۰',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(_toEnglishDigits(_countController.text.trim()));
              if (value != null && value > 0) Navigator.pop(ctx, value);
            },
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
    if (count == null) return;
    final reason = await _askReason();
    if (reason == null) return;
    await _saveEntry(activity, count, reason: reason);
    if (mounted) _message('تعداد با موفقیت ثبت شد.');
  }

  Future<void> _saveEntry(Activity activity, int count, {String? reason}) async {
    final entry = ActivityEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      activityId: activity.id,
      count: count,
      reason: reason == null || reason.isEmpty ? null : reason,
      createdAt: DateTime.now(),
    );
    final updated = [entry, ..._entries];
    await _repository.saveEntries(updated);
    if (!mounted) return;
    setState(() => _entries = updated);
  }

  String _toEnglishDigits(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      value = value.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
    }
    return value;
  }

  int _total(String id) => _entries
      .where((entry) => entry.activityId == id)
      .fold(0, (sum, entry) => sum + entry.count);

  String _folderName(String? id) {
    if (id == null) return 'بدون پوشه';
    for (final folder in _folders) {
      if (folder.id == id) return folder.name;
    }
    return 'بدون پوشه';
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _export() async {
    if (_entries.isEmpty) {
      _message('هنوز گزارشی برای خروجی گرفتن ثبت نشده است.');
      return;
    }
    setState(() => _exporting = true);
    try {
      await _exporter.exportCsv(activities: _activities, entries: _entries);
    } catch (e) {
      if (mounted) _message('تهیه خروجی انجام نشد: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showHistory(Activity activity) {
    final records = _entries.where((entry) => entry.activityId == activity.id).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .65,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('تاریخچه ' + activity.name, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                Expanded(
                  child: records.isEmpty
                      ? const Center(child: Text('هنوز رکوردی ثبت نشده است.'))
                      : ListView.separated(
                          itemCount: records.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (_, i) {
                            final entry = records[i];
                            return ListTile(
                              leading: const Icon(Icons.history),
                              title: Text('تعداد: ' + PersianDateFormatter.digits(entry.count.toString())),
                              subtitle: Text(
                                PersianDateFormatter.dateTime(entry.createdAt) +
                                (entry.reason == null ? '' : '\nدلیل: ' + entry.reason!),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleActivities = _activities.where((activity) =>
      _selectedFolderId == null || activity.folderId == _selectedFolderId
    ).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ثبت فعالیت‌ها'),
          actions: [
            IconButton(
              onPressed: _exporting ? null : _export,
              tooltip: 'خروجی گزارش',
              icon: _exporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.file_download_outlined),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('افزودن فعالیت جدید', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nameController,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _addActivity(),
                                    decoration: const InputDecoration(
                                      hintText: 'نام فعالیت؛ مثلاً مطالعه',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: _addActivity,
                                  icon: const Icon(Icons.add),
                                  label: const Text('افزودن'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedFolderId == null
                                        ? 'فعالیت جدید بدون پوشه ذخیره می‌شود'
                                        : 'پوشه: ' + _folderName(_selectedFolderId),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _createFolder,
                                  icon: const Icon(Icons.create_new_folder_outlined),
                                  label: const Text('پوشه جدید'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        Text('پوشه‌ها', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _createFolder,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('ساخت پوشه'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: const Text('همه'),
                            selected: _selectedFolderId == null,
                            onSelected: (_) => setState(() => _selectedFolderId = null),
                          ),
                        ),
                        ..._folders.map((folder) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            avatar: const Icon(Icons.folder_outlined, size: 18),
                            label: Text(folder.name),
                            selected: _selectedFolderId == folder.id,
                            onSelected: (_) => setState(() => _selectedFolderId = folder.id),
                          ),
                        )),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Text('فعالیت‌های من', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text(PersianDateFormatter.digits('${visibleActivities.length} فعالیت')),
                      ],
                    ),
                  ),
                  Expanded(
                    child: visibleActivities.isEmpty
                        ? Center(
                            child: Text(_selectedFolderId == null
                                ? 'هنوز فعالیتی اضافه نکرده‌ای.'
                                : 'این پوشه هنوز فعالیتی ندارد.'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: visibleActivities.length,
                            itemBuilder: (_, i) {
                              final activity = visibleActivities[i];
                              return Card(
                                child: ListTile(
                                  title: Text(activity.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    'مجموع انجام: ' +
                                    PersianDateFormatter.digits(_total(activity.id).toString()) +
                                    '  •  ' + _folderName(activity.folderId),
                                  ),
                                  onTap: () => _showHistory(activity),
                                  trailing: Wrap(
                                    spacing: 0,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      IconButton(
                                        tooltip: 'تاریخچه',
                                        onPressed: () => _showHistory(activity),
                                        icon: const Icon(Icons.history),
                                      ),
                                      PopupMenuButton<String>(
                                        tooltip: 'انتقال به پوشه',
                                        icon: const Icon(Icons.drive_file_move_outline),
                                        onSelected: (value) => _moveActivity(activity, value),
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: _unfiledValue,
                                            child: Text('بدون پوشه'),
                                          ),
                                          ..._folders.map((folder) => PopupMenuItem(
                                            value: folder.id,
                                            child: Text(folder.name),
                                          )),
                                        ],
                                      ),
                                      IconButton.filledTonal(
                                        tooltip: 'ثبت سریع +۱',
                                        onPressed: () => _addQuickEntry(activity),
                                        icon: const Icon(Icons.add),
                                      ),
                                      IconButton(
                                        tooltip: 'ورود دستی تعداد',
                                        onPressed: () => _addEntry(activity),
                                        icon: const Icon(Icons.edit_note),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
        floatingActionButton: _entries.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: _exporting ? null : _export,
                icon: const Icon(Icons.ios_share),
                label: const Text('خروجی گزارش'),
              ),
      ),
    );
  }
}
