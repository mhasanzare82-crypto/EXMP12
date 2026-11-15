import 'package:flutter/foundation.dart';

import '../../data/activity_export_service.dart';
import '../../data/activity_repository.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/activity_entry.dart';

enum AddActivityResult { added, emptyName, duplicate }

class ActivityController extends ChangeNotifier {
  ActivityController({
    ActivityRepository? repository,
    ActivityExportService? exportService,
  })  : _repository = repository ?? ActivityRepository(),
        _exportService = exportService ?? ActivityExportService();

  final ActivityRepository _repository;
  final ActivityExportService _exportService;

  List<Activity> _activities = const [];
  List<ActivityEntry> _entries = const [];
  bool _isLoading = true;
  bool _isExporting = false;

  List<Activity> get activities => List.unmodifiable(_activities);
  List<ActivityEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.loadActivities(),
        _repository.loadEntries(),
      ]);
      _activities = results[0] as List<Activity>;
      _entries = (results[1] as List<ActivityEntry>)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AddActivityResult> addActivity(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return AddActivityResult.emptyName;

    final normalizedName = name.toLowerCase();
    if (_activities.any((item) => item.name.trim().toLowerCase() == normalizedName)) {
      return AddActivityResult.duplicate;
    }

    final activity = Activity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
    );
    final updated = [..._activities, activity];
    await _repository.saveActivities(updated);
    _activities = updated;
    notifyListeners();
    return AddActivityResult.added;
  }

  Future<void> addEntry({
    required Activity activity,
    required int count,
  }) async {
    if (count <= 0) {
      throw ArgumentError.value(count, 'count', 'Must be greater than zero.');
    }
    if (!_activities.any((item) => item.id == activity.id)) {
      throw StateError('The selected activity no longer exists.');
    }

    final entry = ActivityEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      activityId: activity.id,
      count: count,
      createdAt: DateTime.now(),
    );
    final updated = [entry, ..._entries];
    await _repository.saveEntries(updated);
    _entries = updated;
    notifyListeners();
  }

  int totalFor(String activityId) => _entries
      .where((entry) => entry.activityId == activityId)
      .fold(0, (total, entry) => total + entry.count);

  List<ActivityEntry> entriesFor(String activityId) => List.unmodifiable(
        _entries.where((entry) => entry.activityId == activityId),
      );

  Future<void> export() async {
    if (_entries.isEmpty) {
      throw StateError('There are no activity records to export.');
    }

    _isExporting = true;
    notifyListeners();
    try {
      await _exportService.exportCsv(
        activities: _activities,
        entries: _entries,
      );
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}
