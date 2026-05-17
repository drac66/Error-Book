import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/app_stats.dart';
import '../models/mistake.dart';
import 'database_service.dart';

class MistakeRepository {
  static const _kReviewPlanDate = 'review_plan_date';
  static const _kReviewPlanIds = 'review_plan_ids';
  static const _kReviewTodayReviewedIds = 'review_today_reviewed_ids';
  static const _kCheckinLastDate = 'review_checkin_last_date';
  static const _kCheckinStreak = 'review_checkin_streak';

  final DatabaseService databaseService;

  MistakeRepository(this.databaseService);

  Future<int> count() async {
    final db = await databaseService.database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM mistakes'),
        ) ??
        0;
  }

  Future<List<Mistake>> list({
    String keyword = '',
    String notebookId = 'all',
    MasteryStatus? status,
  }) async {
    final db = await databaseService.database;
    final where = <String>[];
    final args = <Object?>[];
    if (notebookId != 'all') {
      where.add('notebookId = ?');
      args.add(notebookId);
    }
    if (status != null) {
      where.add('masteryStatus = ?');
      args.add(status.value);
    }
    if (keyword.trim().isNotEmpty) {
      final like = '%${keyword.trim()}%';
      where.add(
        '(question LIKE ? OR wrongAnswer LIKE ? OR correctAnswer LIKE ? OR reason LIKE ? OR category LIKE ? OR tagsJson LIKE ?)',
      );
      args.addAll([like, like, like, like, like, like]);
    }
    final rows = await db.query(
      'mistakes',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'updatedAt DESC',
    );
    return rows.map(Mistake.fromDb).toList();
  }

  Future<void> upsert(Mistake mistake) async {
    final db = await databaseService.database;
    final normalized = mistake.copyWith(updatedAt: DateTime.now());
    await db.insert(
      'mistakes',
      normalized.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMany(List<Mistake> mistakes) async {
    final db = await databaseService.database;
    final batch = db.batch();
    for (final mistake in mistakes) {
      batch.insert(
        'mistakes',
        mistake.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(String id) async {
    final db = await databaseService.database;
    await db.delete('review_events', where: 'mistakeId = ?', whereArgs: [id]);
    await db.delete('mistakes', where: 'id = ?', whereArgs: [id]);
  }

  Future<Mistake?> nextForReview() async {
    final items = await plannedReviewList(maxCount: 50, forceRefresh: true);
    if (items.isEmpty) return null;
    return items[Random().nextInt(items.length)];
  }

  Future<void> recordReview(
    String mistakeId,
    MasteryStatus status, {
    String planNotebookId = 'all',
  }) async {
    final db = await databaseService.database;
    final rows = await db.query(
      'mistakes',
      where: 'id = ?',
      whereArgs: [mistakeId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final old = Mistake.fromDb(rows.first);
    final now = DateTime.now();
    final next = old.copyWith(
      masteryStatus: status,
      reviewCount: old.reviewCount + 1,
      updatedAt: now,
      lastReviewedAt: now,
    );
    await db.insert(
      'mistakes',
      next.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert('review_events', {
      'id': const Uuid().v4(),
      'mistakeId': mistakeId,
      'result': status.value,
      'createdAt': now.toIso8601String(),
    });
    await _markReviewedToday(mistakeId, planNotebookId: planNotebookId);
  }

  Future<AppStats> stats({String notebookId = 'all'}) async {
    final items = await list(notebookId: notebookId);
    final total = items.length;
    final reviewing = items
        .where((e) => e.masteryStatus != MasteryStatus.mastered)
        .length;
    final mastered = items
        .where((e) => e.masteryStatus == MasteryStatus.mastered)
        .length;
    final withReviewedAt = items.where((e) => e.lastReviewedAt != null).toList()
      ..sort((a, b) => b.lastReviewedAt!.compareTo(a.lastReviewedAt!));
    return AppStats(
      total: total,
      reviewing: reviewing,
      mastered: mastered,
      lastReviewedAt: withReviewedAt.isEmpty ? null : withReviewedAt.first.lastReviewedAt,
    );
  }

  Future<ReviewDashboardStats> reviewDashboardStats({
    String notebookId = 'all',
  }) async {
    final plan = await plannedReviewList(notebookId: notebookId);
    final ids = plan.map((e) => e.id).toSet();
    final reviewedToday = await _todayReviewedIds(notebookId: notebookId);
    final reviewedCount = reviewedToday.where(ids.contains).length;

    final sp = await SharedPreferences.getInstance();
    final today = _dayKey(DateTime.now());
    final lastCheckin = sp.getString(_kCheckinLastDate);
    final streak = sp.getInt(_kCheckinStreak) ?? 0;

    return ReviewDashboardStats(
      todayReviewed: reviewedCount,
      todayPlanned: plan.length,
      checkinStreak: streak,
      checkedInToday: lastCheckin == today,
    );
  }

  Future<ReviewPlanReport> reviewPlanReport({
    String notebookId = 'all',
  }) async {
    final all = await list(notebookId: notebookId);
    final candidates = await _rankCandidates(all);
    final summary = await reviewDashboardStats(notebookId: notebookId);
    final overdueCount =
        candidates.where((e) => e.dueNow && e.daysSinceLast >= e.intervalDays).length;
    final yesterdayUnmasteredCount =
        candidates.where((e) => e.yesterdayUnmastered).length;
    final hardMistakeCount =
        candidates.where((e) => e.history.recentFailures >= 2).length;
    final coolingMistakeCount =
        candidates.where((e) => !e.dueNow && e.mistake.masteryStatus == MasteryStatus.mastered).length;
    final newMistakeCount = candidates.where((e) => e.neverReviewed).length;

    return ReviewPlanReport(
      summary: summary,
      overdueCount: overdueCount,
      yesterdayUnmasteredCount: yesterdayUnmasteredCount,
      hardMistakeCount: hardMistakeCount,
      coolingMistakeCount: coolingMistakeCount,
      newMistakeCount: newMistakeCount,
      totalPool: all.length,
      bars: [
        ReviewPlanBarDatum(label: '计划', value: summary.todayPlanned),
        ReviewPlanBarDatum(label: '完成', value: summary.todayReviewed),
        ReviewPlanBarDatum(label: '补救', value: yesterdayUnmasteredCount),
        ReviewPlanBarDatum(label: '顽固', value: hardMistakeCount),
      ],
    );
  }

  Future<MistakeReviewMeta> reviewMeta(String mistakeId) async {
    final db = await databaseService.database;
    final rows = await db.query(
      'review_events',
      columns: ['result', 'createdAt'],
      where: 'mistakeId = ?',
      whereArgs: [mistakeId],
      orderBy: 'createdAt ASC',
    );
    if (rows.isEmpty) return MistakeReviewMeta.empty;

    final events = rows
        .map(
          (row) => _ReviewEvent(
            result: row['result'].toString(),
            createdAt: DateTime.parse(row['createdAt'].toString()),
          ),
        )
        .toList();
    final desc = [...events].reversed.toList();
    var consecutiveMastered = 0;
    for (final event in desc) {
      if (event.result == MasteryStatus.mastered.value) {
        consecutiveMastered++;
      } else {
        break;
      }
    }

    return MistakeReviewMeta(
      firstReviewedAt: events.first.createdAt,
      totalReviews: events.length,
      totalWrongReviews:
          events.where((e) => e.result != MasteryStatus.mastered.value).length,
      totalMasteredReviews:
          events.where((e) => e.result == MasteryStatus.mastered.value).length,
      consecutiveMastered: consecutiveMastered,
    );
  }

  Future<List<Mistake>> plannedReviewList({
    String notebookId = 'all',
    int maxCount = 20,
    bool forceRefresh = false,
  }) async {
    final all = await list(notebookId: notebookId);
    if (all.isEmpty) return [];

    final today = _dayKey(DateTime.now());
    final sp = await SharedPreferences.getInstance();
    final cachedDate = sp.getString(_planDateKey(notebookId));
    final cachedIds = ((jsonDecode(sp.getString(_planIdsKey(notebookId)) ?? '[]')
                as List)
            .map((e) => e.toString())
            .toList());

    if (!forceRefresh && cachedDate == today && cachedIds.isNotEmpty) {
      final byId = {for (final m in all) m.id: m};
      final kept = cachedIds.map((id) => byId[id]).whereType<Mistake>().toList();
      if (kept.isNotEmpty) return kept;
    }

    final candidates = await _rankCandidates(all);
    final plan = candidates
        .where((e) => e.dueNow || e.priority > 0)
        .take(maxCount)
        .map((e) => e.mistake)
        .toList();
    await sp.setString(_planDateKey(notebookId), today);
    await sp.setString(
      _planIdsKey(notebookId),
      jsonEncode(plan.map((e) => e.id).toList()),
    );
    if (cachedDate != today) {
      await sp.setString(_reviewedIdsKey(notebookId), jsonEncode(<String>[]));
    }
    return plan;
  }

  Future<List<Mistake>> remainingPlannedReviewList({
    String notebookId = 'all',
    int maxCount = 20,
  }) async {
    final plan = await plannedReviewList(
      notebookId: notebookId,
      maxCount: maxCount,
    );
    final reviewed = await _todayReviewedIds(notebookId: notebookId);
    return plan.where((m) => !reviewed.contains(m.id)).toList();
  }

  Future<List<_PlanCandidate>> _rankCandidates(List<Mistake> all) async {
    final historyMap = await _loadHistoryStats(all.map((e) => e.id).toList());
    final now = DateTime.now();
    final candidates = all.map((mistake) {
      final history = historyMap[mistake.id] ?? const _HistoryStats.empty();
      final last = mistake.lastReviewedAt;
      final daysSinceLast =
          last == null ? 999 : max(0, now.difference(last).inDays);
      final intervalDays = _recommendedIntervalDays(
        masteryStatus: mistake.masteryStatus,
        consecutiveMastered: history.consecutiveMastered,
      );
      final yesterdayUnmastered = last != null &&
          _dayKey(last) == _dayKey(now.subtract(const Duration(days: 1))) &&
          mistake.masteryStatus != MasteryStatus.mastered;
      final neverReviewed = !history.hasReviewed;
      final dueNow = neverReviewed ||
          mistake.masteryStatus != MasteryStatus.mastered ||
          daysSinceLast >= intervalDays;

      final priority = _priorityScore(
        mistake: mistake,
        history: history,
        daysSinceLast: daysSinceLast,
        intervalDays: intervalDays,
        yesterdayUnmastered: yesterdayUnmastered,
        neverReviewed: neverReviewed,
      );

      return _PlanCandidate(
        mistake: mistake,
        history: history,
        priority: priority,
        daysSinceLast: daysSinceLast,
        intervalDays: intervalDays,
        dueNow: dueNow,
        yesterdayUnmastered: yesterdayUnmastered,
        neverReviewed: neverReviewed,
      );
    }).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return candidates;
  }

  int _priorityScore({
    required Mistake mistake,
    required _HistoryStats history,
    required int daysSinceLast,
    required int intervalDays,
    required bool yesterdayUnmastered,
    required bool neverReviewed,
  }) {
    var score = 0;
    if (neverReviewed) score += 900;
    score += min(daysSinceLast, 30) * 35;
    score += history.recentFailures * 120;
    score += history.totalFailures * 18;
    score += mistake.difficultyLevel * 55;
    score += mistake.importanceLevel * 70;

    if (mistake.masteryStatus == MasteryStatus.fresh) score += 180;
    if (mistake.masteryStatus == MasteryStatus.reviewing) score += 120;
    if (yesterdayUnmastered) score += 260;

    if (mistake.importanceLevel >= 4) score += 90;
    if (mistake.difficultyLevel >= 4) score += 60;

    if (mistake.masteryStatus == MasteryStatus.mastered) {
      final overdueDays = daysSinceLast - intervalDays;
      score += overdueDays * 55;
      score -= history.consecutiveMastered * 45;
      if (overdueDays < 0) {
        score -= 400 + (-overdueDays * 50);
      }
    } else if (daysSinceLast <= 1) {
      score += 40;
    }

    return score;
  }

  int _recommendedIntervalDays({
    required MasteryStatus masteryStatus,
    required int consecutiveMastered,
  }) {
    if (masteryStatus != MasteryStatus.mastered) return 1;
    if (consecutiveMastered <= 1) return 1;
    if (consecutiveMastered == 2) return 2;
    if (consecutiveMastered == 3) return 4;
    if (consecutiveMastered == 4) return 7;
    if (consecutiveMastered == 5) return 15;
    return 30;
  }

  Future<Map<String, _HistoryStats>> _loadHistoryStats(List<String> ids) async {
    if (ids.isEmpty) return {};
    final db = await databaseService.database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.rawQuery(
      'SELECT mistakeId, result, createdAt FROM review_events WHERE mistakeId IN ($placeholders) ORDER BY createdAt DESC',
      ids,
    );

    final grouped = <String, List<_ReviewEvent>>{};
    for (final row in rows) {
      final mistakeId = row['mistakeId'].toString();
      grouped.putIfAbsent(mistakeId, () => []).add(
            _ReviewEvent(
              result: row['result'].toString(),
              createdAt: DateTime.parse(row['createdAt'].toString()),
            ),
          );
    }

    final map = <String, _HistoryStats>{};
    for (final id in ids) {
      final events = grouped[id] ?? const <_ReviewEvent>[];
      if (events.isEmpty) {
        map[id] = const _HistoryStats.empty();
        continue;
      }

      var consecutiveMastered = 0;
      for (final event in events) {
        if (event.result == MasteryStatus.mastered.value) {
          consecutiveMastered++;
        } else {
          break;
        }
      }

      final recentSlice = events.take(4).toList();
      map[id] = _HistoryStats(
        firstReviewedAt: events.last.createdAt,
        totalReviews: events.length,
        totalFailures:
            events.where((e) => e.result != MasteryStatus.mastered.value).length,
        recentFailures: recentSlice
            .where((e) => e.result != MasteryStatus.mastered.value)
            .length,
        consecutiveMastered: consecutiveMastered,
      );
    }
    return map;
  }

  Future<void> _markReviewedToday(
    String id, {
    required String planNotebookId,
  }) async {
    final sp = await SharedPreferences.getInstance();
    final today = _dayKey(DateTime.now());
    final storedDate = sp.getString(_planDateKey(planNotebookId));
    if (storedDate != today) {
      await sp.setString(_planDateKey(planNotebookId), today);
      await sp.setString(_reviewedIdsKey(planNotebookId), jsonEncode([id]));
    } else {
      final reviewed = await _todayReviewedIds(notebookId: planNotebookId);
      reviewed.add(id);
      await sp.setString(
        _reviewedIdsKey(planNotebookId),
        jsonEncode(reviewed.toList()),
      );
    }
    await _tryCheckin(planNotebookId: planNotebookId);
  }

  Future<Set<String>> _todayReviewedIds({
    required String notebookId,
  }) async {
    final sp = await SharedPreferences.getInstance();
    final today = _dayKey(DateTime.now());
    final storedDate = sp.getString(_planDateKey(notebookId));
    if (storedDate != today) return {};
    final list = (jsonDecode(sp.getString(_reviewedIdsKey(notebookId)) ?? '[]')
            as List)
        .map((e) => e.toString())
        .toSet();
    return list;
  }

  Future<void> _tryCheckin({required String planNotebookId}) async {
    final sp = await SharedPreferences.getInstance();
    final today = _dayKey(DateTime.now());
    final lastCheckin = sp.getString(_kCheckinLastDate);
    if (lastCheckin == today) return;

    final planIds = (jsonDecode(sp.getString(_planIdsKey(planNotebookId)) ?? '[]')
            as List)
        .map((e) => e.toString())
        .toSet();
    if (planIds.isEmpty) return;

    final reviewed = await _todayReviewedIds(notebookId: planNotebookId);
    if (reviewed.length < planIds.length) return;

    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    final oldStreak = sp.getInt(_kCheckinStreak) ?? 0;
    final streak = (lastCheckin == yesterday) ? oldStreak + 1 : 1;
    await sp.setString(_kCheckinLastDate, today);
    await sp.setInt(_kCheckinStreak, streak);
  }

  String _planDateKey(String notebookId) => '${_kReviewPlanDate}_$notebookId';

  String _planIdsKey(String notebookId) => '${_kReviewPlanIds}_$notebookId';

  String _reviewedIdsKey(String notebookId) =>
      '${_kReviewTodayReviewedIds}_$notebookId';

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<String> exportJson() async {
    final items = await list();
    return const JsonEncoder.withIndent('  ')
        .convert(items.map((e) => e.toJson()).toList());
  }
}

class _PlanCandidate {
  final Mistake mistake;
  final _HistoryStats history;
  final int priority;
  final int daysSinceLast;
  final int intervalDays;
  final bool dueNow;
  final bool yesterdayUnmastered;
  final bool neverReviewed;

  const _PlanCandidate({
    required this.mistake,
    required this.history,
    required this.priority,
    required this.daysSinceLast,
    required this.intervalDays,
    required this.dueNow,
    required this.yesterdayUnmastered,
    required this.neverReviewed,
  });
}

class _HistoryStats {
  final DateTime? firstReviewedAt;
  final int totalReviews;
  final int totalFailures;
  final int recentFailures;
  final int consecutiveMastered;

  const _HistoryStats({
    required this.firstReviewedAt,
    required this.totalReviews,
    required this.totalFailures,
    required this.recentFailures,
    required this.consecutiveMastered,
  });

  bool get hasReviewed => totalReviews > 0;

  const _HistoryStats.empty()
      : firstReviewedAt = null,
        totalReviews = 0,
        totalFailures = 0,
        recentFailures = 0,
        consecutiveMastered = 0;
}

class _ReviewEvent {
  final String result;
  final DateTime createdAt;

  const _ReviewEvent({
    required this.result,
    required this.createdAt,
  });
}
