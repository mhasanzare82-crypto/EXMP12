import 'package:exm1/features/activities/domain/models/activity.dart';
import 'package:exm1/features/activities/domain/models/activity_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Activity serialization', () {
    test('round trips an activity through JSON', () {
      const activity = Activity(id: 'activity-1', name: 'مطالعه');

      final restored = Activity.fromJson(activity.toJson());

      expect(restored.id, activity.id);
      expect(restored.name, activity.name);
    });
  });

  group('ActivityEntry serialization', () {
    test('round trips an entry and preserves its timestamp', () {
      final entry = ActivityEntry(
        id: 'entry-1',
        activityId: 'activity-1',
        count: 12,
        createdAt: DateTime(2026, 11, 15, 9, 30),
      );

      final restored = ActivityEntry.fromJson(entry.toJson());

      expect(restored.id, entry.id);
      expect(restored.activityId, entry.activityId);
      expect(restored.count, entry.count);
      expect(restored.createdAt, entry.createdAt);
    });
  });
}
