import 'dart:convert';
import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/schedule.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/mongodb_service.dart';

class HomeController extends GetxController {
  final schedules = <Schedule>[].obs;
  final isLoading = false.obs;
  final confirmations = <Map<String, dynamic>>[].obs;
  final selectedLogDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).obs;
  final offDayWeekOffset = 0.obs;
  final recentConfirmationType = ''.obs;
  final recentConfirmationEpoch = 0.obs;
  final habitChecks = <String, bool>{}.obs;
  final habitNotes = <String, String>{}.obs;
  final monthlyHabitDays = <Map<String, dynamic>>[].obs;
  final previousMonthHabitDays = <Map<String, dynamic>>[].obs;
  final weeklyHabitStats = <Map<String, dynamic>>[].obs;
  final offDayByDateKey = <String, bool>{}.obs;
  final monthlyHabitSummary = <String, dynamic>{}.obs;
  final isMonthlyAnalyticsLoading = false.obs;
  final navIndex = 0.obs;
  final isManualSyncing = false.obs;
  final AuthService _authService = AuthService();
  Timer? _statsSyncTimer;
  bool _statsSyncInProgress = false;
  double _bottomOverscrollAccumulated = 0;
  static const String _confirmationStorageKey = 'daily_confirmations_v1';
  static const String _habitDateStorageKey = 'daily_habit_date_v1';
  static const String _habitCheckedStorageKey = 'daily_habit_checked_v1';
  static const String _habitNotesStorageKey = 'daily_habit_notes_v1';
  static const String _pendingHabitReportsStorageKey =
      'pending_habit_reports_v1';
  final List<Map<String, String>> _dailyHabits = const [
    {
      'id': 'morning_plan',
      'title': 'Morning Planning',
      'subtitle': 'Set top 3 priorities before starting work',
    },
    {
      'id': 'inbox_batch',
      'title': 'Inbox Batch',
      'subtitle': 'Check email/messages at fixed time windows only',
    },
    {
      'id': 'deep_work',
      'title': 'Deep Work Session',
      'subtitle': 'Complete at least one focused 45-minute block',
    },
    {
      'id': 'status_update',
      'title': 'Professional Update',
      'subtitle': 'Share concise progress + blocker update with team',
    },
    {
      'id': 'day_review',
      'title': 'End-of-Day Review',
      'subtitle': 'Review wins and set tomorrow top tasks',
    },
  ];
  final List<Map<String, String>> _tipsBank = const [
    {
      'title': 'Start With MIT',
      'subtitle': 'Pick 1 most important task before checking chats.',
      'category': 'Focus Habit',
      'action': 'Block 45 minutes of deep work now.',
    },
    {
      'title': '2-Minute Rule',
      'subtitle': 'If a task takes less than 2 minutes, do it immediately.',
      'category': 'Execution',
      'action': 'Clear 3 quick pending items.',
    },
    {
      'title': 'Professional Update',
      'subtitle': 'Share concise status before noon with blockers.',
      'category': 'Teamwork',
      'action': 'Post progress in your team channel.',
    },
    {
      'title': 'Meeting Discipline',
      'subtitle': 'Enter each meeting with agenda and expected outcome.',
      'category': 'Leadership',
      'action': 'Write 2 bullet goals before joining.',
    },
    {
      'title': 'Inbox Control',
      'subtitle': 'Process email in batches, not continuously.',
      'category': 'Time Management',
      'action': 'Set 2 fixed email windows today.',
    },
    {
      'title': 'Skill Upgrade',
      'subtitle': 'Invest 20 minutes in your core technical growth daily.',
      'category': 'Career',
      'action': 'Complete one short lesson or doc section.',
    },
    {
      'title': 'End-of-Day Review',
      'subtitle': 'Close your day with wins, misses, and next-day plan.',
      'category': 'Consistency',
      'action': "Write tomorrow's top 3 tasks before logout.",
    },
  ];

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
    _startStatsSyncTicker();
  }

  @override
  void onClose() {
    _statsSyncTimer?.cancel();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([fetchSchedules(), loadConfirmations()]);
    await loadDailyHabits();
    await syncDailyStatistics(forceUploadToday: true);
  }

  void _startStatsSyncTicker() {
    _statsSyncTimer?.cancel();
    _statsSyncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      syncDailyStatistics();
    });
  }

  Future<void> syncDailyStatistics({bool forceUploadToday = false}) async {
    if (_statsSyncInProgress) return;
    _statsSyncInProgress = true;
    try {
      final hasLocalTodayProgress = habitChecks.values.any((v) => v) || isTodayOffDay;
      if (forceUploadToday || hasLocalTodayProgress) {
        await _syncDailyHabitReport();
      }
      await _syncPendingHabitReports();
      await loadMonthlyHabitAnalytics();
    } finally {
      _statsSyncInProgress = false;
    }
  }

  Future<void> fetchSchedules() async {
    try {
      isLoading.value = true;
      final maps = await MongoDBService.getSchedules();
      schedules.assignAll(maps.map((m) => Schedule.fromMap(m)).toList());
    } finally {
      isLoading.value = false;
    }
  }

  String getCommuteRecommendation({
    String? officeStartTime,
    String? officeEndTime,
    int commuteLeadMinutes = 75,
  }) {
    final now = DateTime.now();
    final officeTime = _dateWithHm(now, officeStartTime ?? '08:15');
    final officeEnd = _dateWithHm(now, officeEndTime ?? '18:00');
    final leaveBy = officeTime.subtract(Duration(minutes: commuteLeadMinutes));
    final nearLateThreshold = leaveBy.add(const Duration(minutes: 12));
    final todayKey = _todayKey(now);

    DateTime? latestForType(String type) {
      DateTime? latest;
      for (final row in confirmations) {
        if ((row['type'] ?? '').toString() != type) continue;
        final when = row['time'];
        if (when is! DateTime) continue;
        if (_todayKey(when) != todayKey) continue;
        if (latest == null || when.isAfter(latest)) latest = when;
      }
      return latest;
    }

    final leftHomeAt = latestForType('Leaving Home');
    final reachedOfficeAt = latestForType('Reached Office');
    final workdayDoneAt =
        latestForType('Workday Done') ?? latestForType('Office Day Done');

    if (workdayDoneAt != null) {
      return 'Workday completed at ${_formatTime(workdayDoneAt)}. Great job. Review tomorrow plan before signing off.';
    }

    if (reachedOfficeAt != null) {
      if (now.isBefore(officeEnd)) {
        final minutesLeft = officeEnd.difference(now).inMinutes.clamp(0, 600);
        return 'You reached office at ${_formatTime(reachedOfficeAt)}. Stay focused, around $minutesLeft min left in today\'s office window.';
      }
      return 'You reached office at ${_formatTime(reachedOfficeAt)} and office window ended at ${_formatTime(officeEnd)}. Mark Workday Done when finished.';
    }

    if (leftHomeAt != null) {
      if (now.isBefore(officeTime)) {
        return 'You left home at ${_formatTime(leftHomeAt)}. If traffic is heavy, choose Uber/Pathao now to reach by ${_formatTime(officeTime)}.';
      }
      if (now.isBefore(officeEnd.subtract(const Duration(minutes: 60)))) {
        return 'You left home at ${_formatTime(leftHomeAt)} but arrival is not marked yet. Take the quickest route and confirm when you reach office.';
      }
      return 'Arrival is still not marked and office day is almost over. If commuting now is not useful, align with your manager and update today\'s status.';
    }

    if (now.isAfter(officeEnd)) {
      return 'Office window ended at ${_formatTime(officeEnd)}. No commute needed now. Close your day with a brief review and tomorrow priorities.';
    }

    if (now.isAfter(officeEnd.subtract(const Duration(minutes: 60)))) {
      return 'Office day is nearly over (ends ${_formatTime(officeEnd)}). Commute only if required; otherwise complete key updates and prepare tomorrow plan.';
    }

    if (now.isBefore(leaveBy)) {
      return "You're on track. Recommended leave-home time is ${_formatTime(leaveBy)} for office start at ${_formatTime(officeTime)}.";
    } else if (now.isBefore(nearLateThreshold)) {
      return "It's time to leave now. To reach by ${_formatTime(officeTime)}, start your commute immediately.";
    } else if (now.isBefore(officeTime)) {
      return "You're running late. Use Uber/Pathao or the quickest route now to reach office by ${_formatTime(officeTime)}.";
    } else {
      return "Office time started at ${_formatTime(officeTime)}. If you still need to go, take the quickest ride option and mark Reached Office immediately.";
    }
  }

  void addLocalSchedule(Schedule schedule) {
    schedules.add(schedule);
  }

  List<Map<String, String>> getTodayTips() {
    if (_tipsBank.length <= 3) return _tipsBank;

    final now = DateTime.now();
    final startIndex = (now.weekday + (now.hour ~/ 3)) % _tipsBank.length;
    return List.generate(
      3,
      (index) => _tipsBank[(startIndex + index) % _tipsBank.length],
    );
  }

  List<Map<String, dynamic>> getWeeklyStats({
    String? officeStartTime,
    String? officeEndTime,
  }) {
    if (weeklyHabitStats.isEmpty) {
      _rebuildWeeklyStats();
    }

    final timingByDate = _buildTimingScoreByDate(
      officeStartTime: officeStartTime ?? '08:15',
      officeEndTime: officeEndTime ?? '18:00',
    );

    return weeklyHabitStats.map((row) {
      final date = row['date'] as DateTime;
      final dateKey = _todayKey(date);
      final isOffDay = row['isOffDay'] == true;
      final habitScore = (row['habitScore'] as num?)?.toDouble() ?? 0.0;
      final timingScore = timingByDate[dateKey];
      final blended = isOffDay
          ? 0.0
          : (timingScore == null
                ? habitScore
                : (habitScore * 0.70 + timingScore * 0.30));
      return {
        'date': date,
        'isOffDay': isOffDay,
        'habitScore': habitScore,
        'timingScore': timingScore ?? -1.0,
        'score': blended.clamp(0.0, 1.0),
      };
    }).toList();
  }

  List<Map<String, String>> getDailyHabits() => _dailyHabits;

  void setNavIndex(int index) {
    navIndex.value = index;
  }

  void resetBottomOverscrollSyncGesture() {
    _bottomOverscrollAccumulated = 0;
  }

  void recordBottomOverscroll(double delta) {
    _bottomOverscrollAccumulated += delta;
  }

  bool consumeBottomOverscrollSyncTrigger({double threshold = 120}) {
    final ready = _bottomOverscrollAccumulated >= threshold;
    _bottomOverscrollAccumulated = 0;
    return ready;
  }

  double get habitCompletionRatio {
    if (_dailyHabits.isEmpty) return 0;
    final completed = _dailyHabits
        .where((habit) => habitChecks[habit['id']] == true)
        .length;
    return completed / _dailyHabits.length;
  }

  int get completedHabitCount =>
      _dailyHabits.where((habit) => habitChecks[habit['id']] == true).length;

  bool get isTodayOffDay => offDayByDateKey[_todayKey(DateTime.now())] == true;

  double get monthlyAverageRate =>
      (monthlyHabitSummary['averageRate'] as num?)?.toDouble() ?? 0;

  String get monthlyStandardLevel {
    final rate = monthlyAverageRate;
    if (rate >= 0.85) return 'Elite';
    if (rate >= 0.70) return 'Strong';
    if (rate >= 0.50) return 'Developing';
    return 'Needs Attention';
  }

  Future<void> loadDailyHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey(DateTime.now());
    final storedDate = prefs.getString(_habitDateStorageKey);
    final checkedIds = prefs.getStringList(_habitCheckedStorageKey) ?? [];

    if (storedDate != todayKey) {
      if (storedDate != null &&
          RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(storedDate) &&
          checkedIds.isNotEmpty) {
        await _queueHabitReportForDate(
          dateKey: storedDate,
          checkedHabitIds: checkedIds,
          isOffDay: false,
        );
        await _syncPendingHabitReports();
      }
      habitChecks.clear();
      habitNotes.clear();
      await prefs.setString(_habitDateStorageKey, todayKey);
      await prefs.remove(_habitCheckedStorageKey);
      await prefs.remove(_habitNotesStorageKey);
      return;
    }

    final map = <String, bool>{};
    for (final habit in _dailyHabits) {
      final id = habit['id'];
      if (id == null) continue;
      map[id] = checkedIds.contains(id);
    }
    habitChecks.assignAll(map);

    final noteEntries = prefs.getStringList(_habitNotesStorageKey) ?? [];
    final notesMap = <String, String>{};
    for (final item in noteEntries) {
      final parts = item.split('||');
      if (parts.length < 2) continue;
      final id = parts[0].trim();
      final note = parts.sublist(1).join('||').trim();
      if (id.isEmpty || note.isEmpty) continue;
      notesMap[id] = note;
    }
    habitNotes.assignAll(notesMap);
    _ensureTodayEntryFromLocal(replaceExisting: false);
    _rebuildWeeklyStats();
  }

  Future<void> toggleHabit(String habitId, bool value) async {
    if (isTodayOffDay) return;
    habitChecks[habitId] = value;
    _rebuildWeeklyStats();
    await _persistDailyHabits();
    await syncDailyStatistics(forceUploadToday: true);
  }

  Future<void> clearDailyHabits() async {
    habitChecks.clear();
    habitNotes.clear();
    _rebuildWeeklyStats();
    await _persistDailyHabits();
    await syncDailyStatistics(forceUploadToday: true);
  }

  Future<void> toggleOffDayForDate(DateTime date, bool isOffDay) async {
    final key = _todayKey(date);
    offDayByDateKey[key] = isOffDay;

    if (key == _todayKey(DateTime.now()) && isOffDay) {
      habitChecks.clear();
      habitNotes.clear();
      await _persistDailyHabits();
    }

    final checkedForDate = isOffDay
        ? <String>[]
        : (key == _todayKey(DateTime.now())
              ? habitChecks.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList()
              : <String>[]);
    await _queueHabitReportForDate(
      dateKey: key,
      checkedHabitIds: checkedForDate,
      isOffDay: isOffDay,
    );
    await _syncPendingHabitReports();

    _rebuildWeeklyStats();
    await syncDailyStatistics(forceUploadToday: key == _todayKey(DateTime.now()));
  }

  Future<void> updateHabitNote(String habitId, String note) async {
    final value = note.trim();
    if (value.isEmpty) {
      habitNotes.remove(habitId);
    } else {
      habitNotes[habitId] = value;
    }
    await _persistDailyHabits();
  }

  Future<void> loadMonthlyHabitAnalytics({String? monthKey}) async {
    try {
      isMonthlyAnalyticsLoading.value = true;
      final now = DateTime.now();
      final currentMonth = monthKey ?? _monthKey(now);
      final previousMonth = _monthKey(DateTime(now.year, now.month - 1, 1));

      final currentResponse = await _authService.fetchMonthlyHabitReport(
        month: currentMonth,
      );
      final previousResponse = await _authService.fetchMonthlyHabitReport(
        month: previousMonth,
      );
      final hasCurrentDays = currentResponse['days'] is List;
      if (currentResponse['days'] is List) {
        final days = (currentResponse['days'] as List)
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList();
        monthlyHabitDays.assignAll(days);
        _applyTodayHabitsFromServer(days);
      }

      if (previousResponse['days'] is List) {
        final days = (previousResponse['days'] as List)
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList();
        previousMonthHabitDays.assignAll(days);
      }

      // Keep local progress visible even if today's server row is missing
      // (e.g. network delay, cold start, intermittent sync).
      _ensureTodayEntryFromLocal(replaceExisting: !hasCurrentDays);

      _refreshOffDayMap();
      _rebuildWeeklyStats();

      if (currentResponse['summary'] is Map) {
        monthlyHabitSummary.assignAll(
          Map<String, dynamic>.from(currentResponse['summary'] as Map),
        );
      } else {
        monthlyHabitSummary.assignAll({
          'averageRate': 0.0,
          'bestRate': 0.0,
          'daysReported': 0,
          'offDays': 0,
          'eliteDays': 0,
          'currentStreak': 0,
        });
      }
    } finally {
      isMonthlyAnalyticsLoading.value = false;
    }
  }

  Future<void> loadConfirmations() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_confirmationStorageKey) ?? [];
    confirmations.assignAll(
      entries.map((entry) {
        try {
          final decoded = jsonDecode(entry);
          if (decoded is Map<String, dynamic>) {
            return {
              'id':
                  decoded['id']?.toString() ??
                  'legacy_${DateTime.now().microsecondsSinceEpoch}',
              'type': decoded['type']?.toString() ?? 'Action',
              'time':
                  DateTime.tryParse(decoded['time']?.toString() ?? '') ??
                  DateTime.now(),
              'note': decoded['note']?.toString() ?? '',
            };
          }
        } catch (_) {
          // fallback for legacy format
        }

        final parts = entry.split('||');
        if (parts.length >= 4) {
          return {
            'id': parts[0].isEmpty
                ? 'legacy_${DateTime.now().microsecondsSinceEpoch}'
                : parts[0],
            'type': parts[1],
            'time': DateTime.tryParse(parts[2]) ?? DateTime.now(),
            'note': parts.sublist(3).join('||'),
          };
        }
        return {
          'id':
              'legacy_${DateTime.now().microsecondsSinceEpoch}_${parts.isNotEmpty ? parts[0] : 'x'}',
          'type': parts.isNotEmpty ? parts[0] : 'Action',
          'time': parts.length > 1
              ? DateTime.tryParse(parts[1]) ?? DateTime.now()
              : DateTime.now(),
          'note': parts.length > 2 ? parts[2] : '',
        };
      }),
    );
    _sortConfirmations();
  }

  Future<void> addConfirmation(String type, {String note = ''}) async {
    final date = selectedLogDate.value;
    final now = DateTime.now();
    final eventTime = DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
    );
    await upsertConfirmationForDate(
      type: type,
      date: date,
      note: note,
      at: eventTime,
    );
  }

  Future<void> upsertConfirmationForDate({
    required String type,
    required DateTime date,
    String note = '',
    DateTime? at,
  }) async {
    final timestamp =
        at ??
        DateTime(
          date.year,
          date.month,
          date.day,
          DateTime.now().hour,
          DateTime.now().minute,
        );

    final existingIndex = confirmations.indexWhere(
      (item) =>
          (item['type']?.toString() ?? '') == type &&
          _isSameDay(item['time'] as DateTime? ?? DateTime.now(), date),
    );

    if (existingIndex >= 0) {
      final existing = Map<String, dynamic>.from(confirmations[existingIndex]);
      existing['time'] = timestamp;
      if (note.trim().isNotEmpty) {
        existing['note'] = note.trim();
      }
      confirmations[existingIndex] = existing;
    } else {
      confirmations.insert(0, {
        'id':
            '${type}_${date.millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}',
        'type': type,
        'time': timestamp,
        'note': note,
      });
    }

    recentConfirmationType.value = type;
    recentConfirmationEpoch.value = DateTime.now().millisecondsSinceEpoch;
    if (confirmations.length > 80) {
      confirmations.removeRange(80, confirmations.length);
    }
    _sortConfirmations();
    await _persistConfirmations();
  }

  Future<bool> toggleConfirmationForDate({
    required String type,
    required DateTime date,
    String note = '',
  }) async {
    final existingIndex = confirmations.indexWhere(
      (item) =>
          (item['type']?.toString() ?? '') == type &&
          _isSameDay(item['time'] as DateTime? ?? DateTime.now(), date),
    );

    if (existingIndex >= 0) {
      confirmations.removeAt(existingIndex);
      recentConfirmationType.value = '';
      recentConfirmationEpoch.value = DateTime.now().millisecondsSinceEpoch;
      _sortConfirmations();
      await _persistConfirmations();
      return false;
    }

    await upsertConfirmationForDate(type: type, date: date, note: note);
    return true;
  }

  Future<void> updateConfirmationTime(String id, DateTime newTime) async {
    final index = confirmations.indexWhere(
      (item) => (item['id']?.toString() ?? '') == id,
    );
    if (index < 0) return;
    final updated = Map<String, dynamic>.from(confirmations[index]);
    updated['time'] = newTime;
    confirmations[index] = updated;
    _sortConfirmations();
    await _persistConfirmations();
  }

  Future<void> updateConfirmationNote(String id, String note) async {
    final index = confirmations.indexWhere(
      (item) => (item['id']?.toString() ?? '') == id,
    );
    if (index < 0) return;
    final updated = Map<String, dynamic>.from(confirmations[index]);
    updated['note'] = note.trim();
    confirmations[index] = updated;
    _sortConfirmations();
    await _persistConfirmations();
  }

  Future<void> clearConfirmations() async {
    confirmations.clear();
    selectedLogDate.value = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_confirmationStorageKey);
  }

  List<DateTime> get confirmationDates {
    final set = <String, DateTime>{};
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    set[_todayKey(todayDate)] = todayDate;

    for (final record in confirmations) {
      final time = record['time'] as DateTime?;
      if (time == null) continue;
      final date = DateTime(time.year, time.month, time.day);
      set[_todayKey(date)] = date;
    }

    final values = set.values.toList();
    values.sort((a, b) => b.compareTo(a));
    return values;
  }

  List<Map<String, dynamic>> get selectedDateConfirmations {
    final selected = selectedLogDate.value;
    return confirmations.where((record) {
      final time = record['time'] as DateTime?;
      if (time == null) return false;
      return _isSameDay(time, selected);
    }).toList();
  }

  bool get isSelectedDateToday =>
      _isSameDay(selectedLogDate.value, DateTime.now());

  void setSelectedLogDate(DateTime date) {
    selectedLogDate.value = DateTime(date.year, date.month, date.day);
  }

  DateTime get offDayWeekStart {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final shifted = monday.add(Duration(days: offDayWeekOffset.value * 7));
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  List<DateTime> get offDayWeekDates {
    final start = offDayWeekStart;
    return List.generate(
      7,
      (index) => DateTime(start.year, start.month, start.day + index),
    );
  }

  void shiftOffDayWeek(int delta) {
    offDayWeekOffset.value += delta;
  }

  bool isOffDayOn(DateTime date) => offDayByDateKey[_todayKey(date)] == true;

  Future<void> _persistConfirmations() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = confirmations.map((item) {
      return jsonEncode({
        'id':
            item['id']?.toString() ??
            'legacy_${DateTime.now().microsecondsSinceEpoch}',
        'type': item['type']?.toString() ?? 'Action',
        'time': (item['time'] as DateTime?)?.toIso8601String() ?? '',
        'note': item['note']?.toString() ?? '',
      });
    }).toList();
    await prefs.setStringList(_confirmationStorageKey, serialized);
  }

  void _sortConfirmations() {
    confirmations.sort(
      (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime),
    );
  }

  Future<void> _persistDailyHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey(DateTime.now());
    final checkedIds = habitChecks.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    final noteEntries = habitNotes.entries
        .where((e) => e.value.trim().isNotEmpty)
        .map((e) => '${e.key}||${e.value.trim()}')
        .toList();

    await prefs.setString(_habitDateStorageKey, todayKey);
    await prefs.setStringList(_habitCheckedStorageKey, checkedIds);
    await prefs.setStringList(_habitNotesStorageKey, noteEntries);
  }

  Future<void> _syncDailyHabitReport() async {
    final todayKey = _todayKey(DateTime.now());
    final todayOffDay = offDayByDateKey[todayKey] == true;
    final checkedIds = habitChecks.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    await _queueHabitReportForDate(
      dateKey: todayKey,
      checkedHabitIds: todayOffDay ? [] : checkedIds,
      isOffDay: todayOffDay,
    );
  }

  Future<Map<String, Map<String, dynamic>>> _readPendingHabitReports() async {
    final prefs = await SharedPreferences.getInstance();
    final rows = prefs.getStringList(_pendingHabitReportsStorageKey) ?? [];
    final reports = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      try {
        final decoded = jsonDecode(row);
        if (decoded is! Map<String, dynamic>) continue;
        final dateKey = (decoded['dateKey'] ?? '').toString();
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateKey)) continue;
        final checkedHabitIds = ((decoded['checkedHabitIds'] as List?) ?? [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toSet()
            .toList();
        reports[dateKey] = {
          'dateKey': dateKey,
          'checkedHabitIds': checkedHabitIds,
          'isOffDay': decoded['isOffDay'] == true,
          'updatedAt':
              (decoded['updatedAt'] ?? DateTime.now().toIso8601String())
                  .toString(),
        };
      } catch (_) {
        // Ignore malformed pending rows.
      }
    }
    return reports;
  }

  Future<void> _writePendingHabitReports(
    Map<String, Map<String, dynamic>> reports,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final rows = reports.values
        .toList()
      ..sort(
        (a, b) =>
            (a['dateKey']?.toString() ?? '').compareTo(
              b['dateKey']?.toString() ?? '',
            ),
      );
    await prefs.setStringList(
      _pendingHabitReportsStorageKey,
      rows.map((row) => jsonEncode(row)).toList(),
    );
  }

  Future<void> _queueHabitReportForDate({
    required String dateKey,
    required List<String> checkedHabitIds,
    required bool isOffDay,
  }) async {
    final pending = await _readPendingHabitReports();
    pending[dateKey] = {
      'dateKey': dateKey,
      'checkedHabitIds': isOffDay
          ? <String>[]
          : checkedHabitIds
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList(),
      'isOffDay': isOffDay,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _writePendingHabitReports(pending);
  }

  Future<void> _syncPendingHabitReports() async {
    final pending = await _readPendingHabitReports();
    if (pending.isEmpty) return;

    final keys = pending.keys.toList()..sort();
    var changed = false;
    for (final key in keys) {
      final report = pending[key];
      if (report == null) continue;
      final result = await _authService.saveHabitReport(
        dateKey: key,
        checkedHabitIds: ((report['checkedHabitIds'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        totalHabits: _dailyHabits.length,
        isOffDay: report['isOffDay'] == true,
      );
      if (result['report'] != null) {
        pending.remove(key);
        changed = true;
      }
    }

    if (changed) {
      await _writePendingHabitReports(pending);
    }
  }

  void _ensureTodayEntryFromLocal({required bool replaceExisting}) {
    final today = DateTime.now();
    final dateKey = _todayKey(today);
    final isOffDay = offDayByDateKey[dateKey] == true;
    final checkedIds = habitChecks.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    final localTodayRow = <String, dynamic>{
      'dateKey': dateKey,
      'completionRate': isOffDay ? 0.0 : habitCompletionRatio,
      'checkedCount': isOffDay ? 0 : checkedIds.length,
      'checkedHabitIds': isOffDay ? <String>[] : checkedIds,
      'isOffDay': isOffDay,
    };

    final index = monthlyHabitDays.indexWhere(
      (row) => row['dateKey']?.toString() == dateKey,
    );
    if (index >= 0) {
      if (replaceExisting) {
        monthlyHabitDays[index] = localTodayRow;
      }
      return;
    }

    monthlyHabitDays.add(localTodayRow);
    monthlyHabitDays.sort(
      (a, b) => (a['dateKey']?.toString() ?? '').compareTo(
        b['dateKey']?.toString() ?? '',
      ),
    );
  }

  Future<void> _applyTodayHabitsFromServer(
    List<Map<String, dynamic>> serverDays,
  ) async {
    final today = _todayKey(DateTime.now());
    Map<String, dynamic>? todayReport;
    for (final day in serverDays) {
      if (day['dateKey'] == today) {
        todayReport = day;
        break;
      }
    }
    if (todayReport == null) return;

    if (todayReport['isOffDay'] == true) {
      habitChecks.clear();
      habitNotes.clear();
      _rebuildWeeklyStats();
      await _persistDailyHabits();
      return;
    }

    final checkedIds = ((todayReport['checkedHabitIds'] as List?) ?? [])
        .map((e) => e.toString())
        .toSet();
    if (checkedIds.isEmpty) {
      habitChecks.clear();
      _rebuildWeeklyStats();
      await _persistDailyHabits();
      return;
    }

    final map = <String, bool>{};
    for (final habit in _dailyHabits) {
      final id = habit['id'];
      if (id == null) continue;
      map[id] = checkedIds.contains(id);
    }
    habitChecks.assignAll(map);
    _rebuildWeeklyStats();
    await _persistDailyHabits();
  }

  void _rebuildWeeklyStats() {
    final today = DateTime.now();
    final mergedDays = [...monthlyHabitDays, ...previousMonthHabitDays];
    final rateByDateKey = <String, double>{};

    for (final day in mergedDays) {
      final key = day['dateKey'].toString();
      if (key.isEmpty || key == 'null') continue;
      final value = (day['completionRate'] as num?)?.toDouble() ?? 0.0;
      rateByDateKey[key] = value.clamp(0.0, 1.0);
    }

    final rows = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final key = _todayKey(date);
      final isOffDay = offDayByDateKey[key] == true;
      final score = key == _todayKey(today)
          ? (isOffDay ? 0.0 : habitCompletionRatio)
          : (rateByDateKey[key] ?? 0.0);
      return {
        'date': date,
        'habitScore': score,
        'score': score,
        'isOffDay': isOffDay,
      };
    });

    weeklyHabitStats.assignAll(rows);
  }

  void _refreshOffDayMap() {
    final mergedDays = [...monthlyHabitDays, ...previousMonthHabitDays];
    final map = <String, bool>{};
    for (final day in mergedDays) {
      final key = day['dateKey'].toString();
      if (key.isEmpty || key == 'null') continue;
      map[key] = day['isOffDay'] == true;
    }
    offDayByDateKey.assignAll(map);
  }

  String _todayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _monthKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _dateWithHm(DateTime date, String hm) {
    final parts = hm.split(':');
    if (parts.length != 2) {
      return DateTime(date.year, date.month, date.day, 8, 15);
    }
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 15;
    final safeHour = hour.clamp(0, 23);
    final safeMinute = minute.clamp(0, 59);
    return DateTime(date.year, date.month, date.day, safeHour, safeMinute);
  }

  String _formatTime(DateTime dt) {
    final h24 = dt.hour;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final mm = dt.minute.toString().padLeft(2, '0');
    final suffix = h24 >= 12 ? 'PM' : 'AM';
    return '$h12:$mm $suffix';
  }

  Map<String, double> _buildTimingScoreByDate({
    required String officeStartTime,
    required String officeEndTime,
  }) {
    final byDateType = <String, Map<String, DateTime>>{};
    for (final row in confirmations) {
      final type = (row['type'] ?? '').toString().trim();
      final when = row['time'];
      if (type.isEmpty || when is! DateTime) continue;
      final dateKey = _todayKey(when);
      final map = byDateType.putIfAbsent(dateKey, () => <String, DateTime>{});
      final existing = map[type];
      if (existing == null || when.isAfter(existing)) {
        map[type] = when;
      }
    }

    final scores = <String, double>{};
    byDateType.forEach((dateKey, events) {
      final date = DateTime.tryParse('${dateKey}T00:00:00');
      if (date == null) return;
      if (offDayByDateKey[dateKey] == true) {
        scores[dateKey] = 0.0;
        return;
      }

      final officeStart = _dateWithHm(date, officeStartTime);
      final officeEnd = _dateWithHm(date, officeEndTime);
      final leaveBy = officeStart.subtract(const Duration(minutes: 75));

      final leaveTime = events['Leaving Home'];
      final reachTime = events['Reached Office'];
      final doneTime = events['Workday Done'] ?? events['Office Day Done'];

      final parts = <double>[];
      if (leaveTime != null) {
        final mins = (leaveTime.difference(leaveBy).inMinutes).abs();
        parts.add(_scoreByDelta(mins, goodWithin: 10, maxLate: 120));
      }
      if (reachTime != null) {
        final minsLate = reachTime.difference(officeStart).inMinutes;
        if (minsLate <= 5) {
          parts.add(1.0);
        } else {
          parts.add(_scoreByDelta(minsLate, goodWithin: 10, maxLate: 120));
        }
      }
      if (doneTime != null) {
        final minsEarly = officeEnd.difference(doneTime).inMinutes;
        if (minsEarly <= 10) {
          parts.add(1.0);
        } else {
          parts.add(_scoreByDelta(minsEarly, goodWithin: 15, maxLate: 180));
        }
      }

      if (parts.isNotEmpty) {
        final avg = parts.reduce((a, b) => a + b) / parts.length;
        scores[dateKey] = avg.clamp(0.0, 1.0);
      }
    });

    return scores;
  }

  double _scoreByDelta(int deltaMinutes, {required int goodWithin, required int maxLate}) {
    if (deltaMinutes <= goodWithin) return 1.0;
    if (deltaMinutes >= maxLate) return 0.0;
    final span = (maxLate - goodWithin).toDouble();
    final penalty = (deltaMinutes - goodWithin) / span;
    return (1.0 - penalty).clamp(0.0, 1.0);
  }
}
