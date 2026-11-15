import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/activity.dart';
import '../domain/models/activity_entry.dart';
import '../domain/models/activity_folder.dart';

class ActivityRepository {
  static const _activitiesKey = 'activities_v1';
  static const _entriesKey = 'activity_entries_v1';
  static const _foldersKey = 'activity_folders_v1';

  Future<List<Activity>> loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activitiesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActivityEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_entriesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => ActivityEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActivityFolder>> loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_foldersKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => ActivityFolder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveActivities(List<Activity> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _activitiesKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveEntries(List<ActivityEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _entriesKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveFolders(List<ActivityFolder> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _foldersKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
