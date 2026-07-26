import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/focus_session.dart';
import 'package:zentask/repositories/focus_session_repository.dart';
import 'package:zentask/services/focus/focus_statistics_service.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late FocusSessionRepository repository;
  late FocusStatisticsService service;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_focus_stats_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('focus_sessions_stats_test');
    repository = FocusSessionRepository(box: box);
    service = FocusStatisticsService(repository: repository);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('reports all zeros with no sessions', () {
    final stats = service.compute();
    expect(stats.totalSessions, 0);
    expect(stats.totalFocusMinutes, 0);
    expect(stats.sessionsToday, 0);
    expect(stats.sessionsThisWeek, 0);
    expect(stats.averageSessionMinutes, 0);
  });

  test('ignores incomplete sessions entirely', () async {
    final now = DateTime(2026, 3, 10, 9);
    await repository.save(FocusSession.create(
      startedAt: now,
      endedAt: now.add(const Duration(minutes: 25)),
      completed: false,
    ));

    final stats = service.compute(now: now);
    expect(stats.totalSessions, 0);
  });

  test('aggregates total/average minutes across completed sessions', () async {
    final now = DateTime(2026, 3, 10, 9);
    await repository.save(FocusSession.create(
      startedAt: now,
      endedAt: now.add(const Duration(minutes: 25)),
      completed: true,
    ));
    await repository.save(FocusSession.create(
      startedAt: now,
      endedAt: now.add(const Duration(minutes: 15)),
      completed: true,
    ));

    final stats = service.compute(now: now);
    expect(stats.totalSessions, 2);
    expect(stats.totalFocusMinutes, 40);
    expect(stats.averageSessionMinutes, 20);
  });

  test('sessionsToday only counts sessions started today', () async {
    final today = DateTime(2026, 3, 10, 9);
    final yesterday = DateTime(2026, 3, 9, 9);
    await repository.save(FocusSession.create(
      startedAt: today,
      endedAt: today.add(const Duration(minutes: 10)),
      completed: true,
    ));
    await repository.save(FocusSession.create(
      startedAt: yesterday,
      endedAt: yesterday.add(const Duration(minutes: 10)),
      completed: true,
    ));

    final stats = service.compute(now: today);
    expect(stats.sessionsToday, 1);
    expect(stats.sessionsThisWeek, 2);
  });

  test('sessionsThisWeek excludes sessions from the previous week', () async {
    // 2026-03-10 is a Tuesday; the previous Monday is 2026-03-02, so
    // 2026-02-20 is safely in the prior week.
    final thisWeek = DateTime(2026, 3, 10, 9);
    final lastWeek = DateTime(2026, 2, 20, 9);
    await repository.save(FocusSession.create(
      startedAt: thisWeek,
      endedAt: thisWeek.add(const Duration(minutes: 10)),
      completed: true,
    ));
    await repository.save(FocusSession.create(
      startedAt: lastWeek,
      endedAt: lastWeek.add(const Duration(minutes: 10)),
      completed: true,
    ));

    final stats = service.compute(now: thisWeek);
    expect(stats.sessionsThisWeek, 1);
    expect(stats.totalSessions, 2);
  });
}
