import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/persian_date_formatter.dart';
import '../../domain/models/activity.dart';
import '../controllers/activity_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = ActivityController();
  final _activityNameController = TextEditingController();
  final _countController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      await _controller.load();
    } catch (error) {
      if (mounted) _showMessage('بارگذاری اطلاعات انجام نشد: $error');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _activityNameController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _addActivity() async {
    try {
      final result = await _controller.addActivity(_activityNameController.text);
      if (!mounted) return;

      switch (result) {
        case AddActivityResult.added:
          _activityNameController.clear();
          _showMessage('فعالیت با موفقیت اضافه شد.');
          break;
        case AddActivityResult.emptyName:
          _showMessage('لطفاً نام فعالیت را وارد کن.');
          break;
        case AddActivityResult.duplicate:
          _showMessage('این فعالیت قبلاً اضافه شده است.');
          break;
      }
    } catch (error) {
      if (mounted) _showMessage('ذخیره فعالیت انجام نشد: $error');
    }
  }

  Future<void> _recordActivity(Activity activity) async {
    _countController.clear();
    final count = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('ثبت تعداد برای ${activity.name}'),
        content: TextField(
          controller: _countController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'تعداد انجام‌شده',
            hintText: 'مثلاً ۲۰',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(_toEnglishDigits(_countController.text));
              if (value != null && value > 0) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('ثبت'),
          ),
        ],
      ),
    );

    if (count == null || !mounted) return;
    try {
      await _controller.addEntry(activity: activity, count: count);
      if (mounted) _showMessage('تعداد با موفقیت ثبت شد.');
    } catch (error) {
      if (mounted) _showMessage('ثبت تعداد انجام نشد: $error');
    }
  }

  String _toEnglishDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    for (var index = 0; index < 10; index++) {
      value = value
          .replaceAll(persian[index], '$index')
          .replaceAll(arabic[index], '$index');
    }
    return value.trim();
  }

  Future<void> _export() async {
    try {
      await _controller.export();
    } catch (error) {
      if (mounted) _showMessage('تهیه خروجی انجام نشد: $error');
    }
  }

  void _showHistory(Activity activity) {
    final records = _controller.entriesFor(activity.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.65,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تاریخچه ${activity.name}',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: records.isEmpty
                      ? const Center(child: Text('هنوز رکوردی ثبت نشده است.'))
                      : ListView.separated(
                          itemCount: records.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final entry = records[index];
                            return ListTile(
                              leading: const Icon(Icons.history),
                              title: Text(
                                'تعداد: ${PersianDateFormatter.digits(entry.count.toString())}',
                              ),
                              subtitle: Text(
                                PersianDateFormatter.dateTime(entry.createdAt),
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

  Future<void> _confirmExport() async {
    if (_controller.entries.isEmpty) {
      _showMessage('هنوز گزارشی برای خروجی گرفتن ثبت نشده است.');
      return;
    }
    await _export();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text(AppConstants.appName),
            actions: [
              IconButton(
                onPressed: _controller.isExporting ? null : _confirmExport,
                tooltip: 'خروجی گزارش',
                icon: _controller.isExporting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined),
              ),
            ],
          ),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildAddActivityCard(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'فعالیت‌های من',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            PersianDateFormatter.digits(
                              '${_controller.activities.length} فعالیت',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildActivityList()),
                  ],
                ),
          floatingActionButton: _controller.entries.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: _controller.isExporting ? null : _confirmExport,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('خروجی گزارش'),
                ),
        ),
      ),
    );
  }

  Widget _buildAddActivityCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'افزودن فعالیت جدید',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _activityNameController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addActivity(),
                      decoration: const InputDecoration(
                        hintText: 'نام فعالیت؛ مثلاً مطالعه',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    final activities = _controller.activities;
    if (activities.isEmpty) {
      return const Center(child: Text('هنوز فعالیتی اضافه نکرده‌ای.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: activities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Card(
          child: ListTile(
            title: Text(
              activity.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'مجموع انجام: ${PersianDateFormatter.digits(_controller.totalFor(activity.id).toString())}',
            ),
            onTap: () => _showHistory(activity),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: 'تاریخچه',
                  onPressed: () => _showHistory(activity),
                  icon: const Icon(Icons.history),
                ),
                IconButton.filledTonal(
                  tooltip: 'ثبت تعداد',
                  onPressed: () => _recordActivity(activity),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
