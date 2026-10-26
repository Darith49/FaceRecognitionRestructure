import 'dart:io';
import 'package:face_recognition_attendance/features/notification/model/notification_model.dart';
import '../server/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Model & Lenient isRead Parsing Tests', () {
    test('NotificationItem.fromJson handles boolean, integer, and string representations', () {
      final nTrue = NotificationItem.fromJson({
        'id': 1,
        'title': 'Test 1',
        'message': 'Message',
        'is_read': true,
      });
      expect(nTrue.isRead, isTrue);

      final nIntOne = NotificationItem.fromJson({
        'id': 2,
        'title': 'Test 2',
        'message': 'Message',
        'is_read': 1,
      });
      expect(nIntOne.isRead, isTrue);

      final nStrOne = NotificationItem.fromJson({
        'id': 3,
        'title': 'Test 3',
        'message': 'Message',
        'is_read': '1',
      });
      expect(nStrOne.isRead, isTrue);

      final nStrTrue = NotificationItem.fromJson({
        'id': 4,
        'title': 'Test 4',
        'message': 'Message',
        'is_read': 'true',
      });
      expect(nStrTrue.isRead, isTrue);

      final nFalse = NotificationItem.fromJson({
        'id': 5,
        'title': 'Test 5',
        'message': 'Message',
        'is_read': false,
      });
      expect(nFalse.isRead, isFalse);

      final nIntZero = NotificationItem.fromJson({
        'id': 6,
        'title': 'Test 6',
        'message': 'Message',
        'is_read': 0,
      });
      expect(nIntZero.isRead, isFalse);
    });
  });

  group('SQLite Notification Persistence Across Database Sessions', () {
    final testDbPath = 'test_notification_persistence.db';

    setUp(() {
      if (File(testDbPath).existsSync()) {
        File(testDbPath).deleteSync();
      }
    });

    tearDown(() {
      AppSqliteDatabase().close();
      if (File(testDbPath).existsSync()) {
        File(testDbPath).deleteSync();
      }
    });

    test('Notifications preserve read status across database reconnects', () {
      final db = AppSqliteDatabase();
      db.init(dbPath: testDbPath);

      // 1. Add notification with unread status
      db.saveNotification({
        'id': 201,
        'title': 'Leave Request Submitted',
        'message': 'Alex submitted a leave request.',
        'is_read': 0,
        'is_demo': 1,
        'recipient_id': '1',
      });

      var notifs = db.getNotifications(employeeId: '1', forDemo: true);
      expect(notifs.length, 1);
      expect(notifs.first['is_read'], isFalse);

      // 2. Mark as read in session 1
      db.markNotificationRead(201);
      notifs = db.getNotifications(employeeId: '1', forDemo: true);
      expect(notifs.first['is_read'], isTrue);

      // 3. Close database and reopen (simulating session 2 / app restart)
      db.close();

      final dbSession2 = AppSqliteDatabase();
      dbSession2.init(dbPath: testDbPath);

      final notifsSession2 = dbSession2.getNotifications(employeeId: '1', forDemo: true);
      expect(notifsSession2.length, 1);
      // It MUST still show as seen (is_read = true)!
      expect(notifsSession2.first['is_read'], isTrue);

      // 4. Test markAllNotificationsRead
      dbSession2.saveNotification({
        'id': 202,
        'title': 'Overtime Request',
        'message': 'Overtime pending.',
        'is_read': 0,
        'is_demo': 1,
        'recipient_id': '1',
      });

      dbSession2.markAllNotificationsRead(forDemo: true);
      final allNotifs = dbSession2.getNotifications(employeeId: '1', forDemo: true);
      for (final n in allNotifs) {
        expect(n['is_read'], isTrue);
      }
    });
  });
}
