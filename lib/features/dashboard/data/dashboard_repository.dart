import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dust_count/shared/models/task_log.dart';
import 'package:dust_count/core/constants/app_constants.dart';

/// Entry in the leaderboard showing member statistics
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int totalMinutes;
  final int taskCount;
  final Map<TaskDifficulty, int> difficultyBreakdown;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.totalMinutes,
    required this.taskCount,
    required this.difficultyBreakdown,
  });

  LeaderboardEntry copyWith({
    String? userId,
    String? displayName,
    int? totalMinutes,
    int? taskCount,
    Map<TaskDifficulty, int>? difficultyBreakdown,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      taskCount: taskCount ?? this.taskCount,
      difficultyBreakdown: difficultyBreakdown ?? this.difficultyBreakdown,
    );
  }
}

/// Entry showing per-category breakdown for a single member
class CategoryBreakdownEntry {
  final String userId;
  final String displayName;
  final Map<String, int> minutesPerCategory;
  final Map<String, int> countPerCategory;

  const CategoryBreakdownEntry({
    required this.userId,
    required this.displayName,
    required this.minutesPerCategory,
    required this.countPerCategory,
  });
}

/// Repository for aggregating and computing dashboard statistics
class DashboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _taskLogsRef(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('taskLogs');
  }

  /// Fetches task logs from Firestore filtered by date range and optional filters.
  /// Falls back to local cache when the server is unreachable.
  Future<List<TaskLog>> _fetchTaskLogs(
    String householdId,
    DateTime start,
    DateTime end, {
    String? categoryId,
    String? taskNameFr,
    TaskDifficulty? difficulty,
  }) async {
    Query<Map<String, dynamic>> query = _taskLogsRef(householdId);

    if (categoryId != null) {
      query = query.where('category', isEqualTo: categoryId);
    }

    if (taskNameFr != null) {
      query = query.where('taskNameFr', isEqualTo: taskNameFr);
    }

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty.name);
    }

    query = query
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true);

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await query.get();
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        snapshot = await query.get(const GetOptions(source: Source.cache));
      } else {
        rethrow;
      }
    }

    return snapshot.docs
        .map((doc) => TaskLog.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  /// Get total minutes per member for a given period
  Future<Map<String, int>> getMinutesPerMember(
    String householdId,
    DateTime start,
    DateTime end, {
    String? categoryId,
    String? taskNameFr,
    TaskDifficulty? difficulty,
  }) async {
    final logs = await _fetchTaskLogs(householdId, start, end,
        categoryId: categoryId, taskNameFr: taskNameFr, difficulty: difficulty);

    final Map<String, int> minutesPerMember = {};

    for (final log in logs) {
      minutesPerMember[log.performedBy] =
          (minutesPerMember[log.performedBy] ?? 0) + log.durationMinutes;
    }

    return minutesPerMember;
  }

  /// Get daily cumulative minutes per member for charting
  /// Returns {userId: {dateString: cumulativeMinutes}}
  Future<Map<String, Map<String, int>>> getDailyMinutesPerMember(
    String householdId,
    DateTime start,
    DateTime end, {
    String? categoryId,
    String? taskNameFr,
    TaskDifficulty? difficulty,
  }) async {
    final logs = await _fetchTaskLogs(householdId, start, end,
        categoryId: categoryId, taskNameFr: taskNameFr, difficulty: difficulty);

    // Sort by date
    logs.sort((a, b) => a.date.compareTo(b.date));

    final Map<String, Map<String, int>> dailyMinutes = {};

    // Initialize all members with empty maps
    final Set<String> allMembers = logs.map((log) => log.performedBy).toSet();
    for (final member in allMembers) {
      dailyMinutes[member] = {};
    }

    // Build cumulative totals day by day
    for (final member in allMembers) {
      int cumulativeMinutes = 0;
      final memberLogs = logs.where((log) => log.performedBy == member).toList();

      // Create a map of date to total minutes for that day
      final Map<String, int> dailyTotals = {};
      for (final log in memberLogs) {
        final dateKey = _formatDateKey(log.date);
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + log.durationMinutes;
      }

      // Convert to cumulative totals
      DateTime currentDate = start;
      while (currentDate.isBefore(end.add(const Duration(days: 1)))) {
        final dateKey = _formatDateKey(currentDate);
        cumulativeMinutes += dailyTotals[dateKey] ?? 0;

        // Only add data points where there's activity or cumulative value
        if (cumulativeMinutes > 0) {
          dailyMinutes[member]![dateKey] = cumulativeMinutes;
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    return dailyMinutes;
  }

  /// Get leaderboard entries sorted by total minutes (descending)
  Future<List<LeaderboardEntry>> getLeaderboard(
    String householdId,
    DateTime start,
    DateTime end, {
    String? categoryId,
    String? taskNameFr,
    TaskDifficulty? difficulty,
  }) async {
    final logs = await _fetchTaskLogs(householdId, start, end,
        categoryId: categoryId, taskNameFr: taskNameFr, difficulty: difficulty);

    // Group by user
    final Map<String, List<TaskLog>> logsByUser = {};
    for (final log in logs) {
      logsByUser.putIfAbsent(log.performedBy, () => []).add(log);
    }

    // Build leaderboard entries
    final List<LeaderboardEntry> entries = [];

    for (final entry in logsByUser.entries) {
      final userId = entry.key;
      final userLogs = entry.value;

      final totalMinutes = userLogs.fold<int>(
        0,
        (sum, log) => sum + log.durationMinutes,
      );

      final difficultyBreakdown = <TaskDifficulty, int>{};
      for (final log in userLogs) {
        difficultyBreakdown[log.difficulty] =
            (difficultyBreakdown[log.difficulty] ?? 0) + 1;
      }

      entries.add(LeaderboardEntry(
        userId: userId,
        displayName: userLogs.first.performedByName,
        totalMinutes: totalMinutes,
        taskCount: userLogs.length,
        difficultyBreakdown: difficultyBreakdown,
      ));
    }

    // Sort by total minutes (descending)
    entries.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

    return entries;
  }

  /// Get per-category breakdown for each member
  Future<List<CategoryBreakdownEntry>> getCategoryBreakdown(
    String householdId,
    DateTime start,
    DateTime end, {
    String? categoryId,
    String? taskNameFr,
    TaskDifficulty? difficulty,
  }) async {
    final logs = await _fetchTaskLogs(
      householdId,
      start,
      end,
      categoryId: categoryId,
      taskNameFr: taskNameFr,
      difficulty: difficulty,
    );

    final Map<String, List<TaskLog>> logsByUser = {};
    for (final log in logs) {
      logsByUser.putIfAbsent(log.performedBy, () => []).add(log);
    }

    final List<CategoryBreakdownEntry> entries = [];
    for (final entry in logsByUser.entries) {
      final userId = entry.key;
      final userLogs = entry.value;

      final minutesPerCategory = <String, int>{};
      final countPerCategory = <String, int>{};

      for (final log in userLogs) {
        minutesPerCategory[log.categoryId] =
            (minutesPerCategory[log.categoryId] ?? 0) + log.durationMinutes;
        countPerCategory[log.categoryId] =
            (countPerCategory[log.categoryId] ?? 0) + 1;
      }

      entries.add(CategoryBreakdownEntry(
        userId: userId,
        displayName: userLogs.first.performedByName,
        minutesPerCategory: minutesPerCategory,
        countPerCategory: countPerCategory,
      ));
    }

    // Sort by total minutes descending
    entries.sort((a, b) {
      final totalA = a.minutesPerCategory.values.fold<int>(0, (acc, v) => acc + v);
      final totalB = b.minutesPerCategory.values.fold<int>(0, (acc, v) => acc + v);
      return totalB.compareTo(totalA);
    });

    return entries;
  }

  /// Format date as YYYY-MM-DD for consistent keys
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
