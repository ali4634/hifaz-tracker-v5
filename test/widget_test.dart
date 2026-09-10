import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:huffa_tracker_5/app.dart';
import 'package:huffa_tracker_5/localization/app_localizations.dart';
import 'package:huffa_tracker_5/models/app_settings.dart';
import 'package:huffa_tracker_5/models/daily_record.dart';
import 'package:huffa_tracker_5/models/student.dart';
import 'package:huffa_tracker_5/providers/app_provider.dart';
import 'package:huffa_tracker_5/providers/settings_provider.dart';
import 'package:huffa_tracker_5/providers/google_drive_provider.dart';
import 'package:huffa_tracker_5/services/storage_service.dart';

void main() {
  // All real file I/O must happen outside the FakeAsync zone of testWidgets.
  late final StorageService storage;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    Hive.init(Directory.systemTemp.createTempSync('hifaz_test_').path);
    Hive
      ..registerAdapter(StudentAdapter())
      ..registerAdapter(DailyRecordAdapter())
      ..registerAdapter(SabaqEntryAdapter())
      ..registerAdapter(SabqiEntryAdapter())
      ..registerAdapter(ManzilEntryAdapter())
      ..registerAdapter(AppSettingsAdapter());

    await AppLocalizations.load();

    storage = StorageService.instance;
    await storage.init();
    await storage.clearAll();
  });

  testWidgets('boots and shows the attendance screen', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider(storage)..init()),
          ChangeNotifierProvider(create: (_) => SettingsProvider(storage)..init()),
          ChangeNotifierProvider(create: (_) => GoogleDriveProvider(storage)..init()),
        ],
        child: const HifazApp(),
      ),
    );

    // Bounded pumps instead of pumpAndSettle (some widgets animate forever).
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Hifaz Tracker'), findsOneWidget);
    expect(find.text('No students yet'), findsOneWidget);
  });

  // Real Hive I/O must run outside the FakeAsync zone of testWidgets, so this
  // is a plain async test (it only exercises provider logic, no widgets).
  test('naagha: viewing alerts clears the bell, logging re-arms it', () async {
    final app = AppProvider(storage)..init();
    final settings = SettingsProvider(storage)..init();
    await app.init();
    await settings.init();

    // A student with no records at all has a gap in every track since the
    // day they were added (10 days ago > default 3-day threshold).
    final s = Student(
      id: 's-gap',
      name: 'Gap Student',
      section: 'A',
      createdAt: DateTime.now()
          .subtract(const Duration(days: 10))
          .toIso8601String(),
    );
    await app.addStudent(s);

    final threshold = settings.settings.missingSabqiDays;
    final alerts = app.naaghaAlerts(threshold);
    expect(alerts, isNotEmpty);
    expect(app.naaghaUnseenStudentCount(threshold), 1);

    // Opening the naagha list marks everything as seen → badge clears.
    await app.markNaaghaSeen(alerts);
    expect(app.naaghaUnseenStudentCount(threshold), 0);
    expect(app.naaghaSeenKeys, isNotEmpty);

    // Logging every track resolves the gaps and drops the seen state, so a
    // NEW gap later will ring the bell again.
    await app.saveLessons(
      studentId: s.id,
      date: DateTime.now(),
      present: true,
      sabaq: SabaqEntry(
        juz: 1,
        pageLabel: '5',
        lines: 3,
        startPage: 3,
        endPage: 5,
      ),
      sabqi: SabqiEntry(juz: 1, startPage: 3, endPage: 5, heardPage: 5),
      manzil: ManzilEntry(juz: 1, ruba: 1),
    );
    expect(app.naaghaUnseenStudentCount(threshold), 0);
    expect(app.naaghaSeenKeys, isEmpty);

    await app.deleteStudent(s.id);
  });
}
