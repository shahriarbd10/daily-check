import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../controllers/home_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';

class HomeView extends GetView<HomeController> {
  HomeView({super.key});

  final GlobalKey _topKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _logKey = GlobalKey();
  final GlobalKey _scheduleKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      bottomNavigationBar: _buildSmartNavBar(context, authController),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _syncDashboard(authController, showToast: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is OverscrollNotification) {
                final atBottom =
                    notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent;
                if (atBottom && notification.overscroll > 0) {
                  controller.recordBottomOverscroll(notification.overscroll);
                }
              } else if (notification is ScrollEndNotification) {
                final shouldSync = controller.consumeBottomOverscrollSyncTrigger();
                if (shouldSync) {
                  _syncDashboard(authController, showToast: true);
                }
              } else if (notification is ScrollUpdateNotification) {
                final atBottom =
                    notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent;
                if (!atBottom) {
                  controller.resetBottomOverscrollSyncGesture();
                }
              }
              return false;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 112),
              child: Column(
                key: _topKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(authController),
                  const SizedBox(height: 18),
                  Text(
                    'Today Plan',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 6),
                  Obx(
                    () => Text(
                      'Welcome, ${authController.user.value?['name'] ?? 'User'}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _DigitalClockCard(),
                  const SizedBox(height: 18),
                  _buildHorizontalCalendar(),
                  const SizedBox(height: 18),
                  _buildCommuteRecommendationCard(context, authController),
                  const SizedBox(height: 18),
                  Container(key: _logKey, child: _buildConfirmationSection(context)),
                  const SizedBox(height: 18),
                  _buildWeeklyOffDaySelector(context),
                  const SizedBox(height: 18),
                  _buildDailyHabitChecklist(context),
                  const SizedBox(height: 18),
                  _buildProfessionalTipsSection(context),
                  const SizedBox(height: 18),
                  Container(
                    key: _statsKey,
                    child: _buildDailyStatsCurve(context, authController),
                  ),
                  const SizedBox(height: 18),
                  _buildMonthlyHabitAnalysisCard(context),
                  const SizedBox(height: 18),
                  Row(
                    key: _scheduleKey,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Schedules',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        DateFormat('MMM d, EEEE').format(DateTime.now()),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildScheduleList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AuthController authController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Daily Check',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        Row(
          children: [
            InkWell(
              onTap: () => Get.toNamed(AppRoutes.PROFILE),
              borderRadius: BorderRadius.circular(12),
              child: _roundIcon(Icons.person_outline_rounded),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: authController.logout,
              borderRadius: BorderRadius.circular(12),
              child: _roundIcon(Icons.logout_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmartNavBar(BuildContext context, AuthController authController) {
    const navItems = <Map<String, dynamic>>[
      {'index': 0, 'icon': Icons.home_rounded, 'label': 'Home'},
      {'index': 1, 'icon': Icons.insights_rounded, 'label': 'Stats'},
      {'index': 3, 'icon': Icons.notifications_none_rounded, 'label': 'Log'},
      {'index': 4, 'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return SafeArea(
      top: false,
      child: Obx(() {
        final selected = controller.navIndex.value;
        final dotAlignment = ((selected.clamp(0, 4) - 2) / 2).toDouble();

        return Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          height: 90,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF081D57),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _navItem(
                          item: navItems[0],
                          selected: selected == 0,
                          onTap: () => _onNavTap(
                            context: context,
                            authController: authController,
                            index: 0,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _navItem(
                          item: navItems[1],
                          selected: selected == 1,
                          onTap: () => _onNavTap(
                            context: context,
                            authController: authController,
                            index: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 58),
                      Expanded(
                        child: _navItem(
                          item: navItems[2],
                          selected: selected == 3,
                          onTap: () => _onNavTap(
                            context: context,
                            authController: authController,
                            index: 3,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _navItem(
                          item: navItems[3],
                          selected: selected == 4,
                          onTap: () => _onNavTap(
                            context: context,
                            authController: authController,
                            index: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -2,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _onNavTap(
                      context: context,
                      authController: authController,
                      index: 2,
                    ),
                    child: AnimatedScale(
                      scale: selected == 2 ? 1.06 : 1,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFB347), Color(0xFFFF4D8D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x44FF4D8D),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            selected == 2
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            key: ValueKey('center_$selected'),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 8,
                child: SizedBox(
                  height: 6,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment(dotAlignment, 0),
                        child: Container(
                          width: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _navItem({
    required Map<String, dynamic> item,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                item['icon'] as IconData,
                key: ValueKey('${item['label']}_$selected'),
                size: selected ? 23 : 21,
                color: selected
                    ? const Color(0xFF8CF2FF)
                    : Colors.white.withOpacity(0.70),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                color: selected
                    ? const Color(0xFF8CF2FF)
                    : Colors.white.withOpacity(0.56),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
              child: Text(item['label'] as String),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  Future<void> _syncDashboard(
    AuthController authController, {
    bool showToast = false,
  }) async {
    if (controller.isManualSyncing.value) return;
    controller.isManualSyncing.value = true;
    try {
      await authController.fetchProfile();
      await controller.fetchSchedules();
      await controller.loadConfirmations();
      await controller.loadDailyHabits();
      await controller.syncDailyStatistics(forceUploadToday: true);
      if (showToast) {
        Get.snackbar(
          'Synced',
          'Dashboard data refreshed successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (showToast) {
        Get.snackbar(
          'Sync Failed',
          'Could not refresh all data right now.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      controller.isManualSyncing.value = false;
    }
  }

  Future<void> _onNavTap({
    required BuildContext context,
    required AuthController authController,
    required int index,
  }) async {
    controller.setNavIndex(index);
    if (index == 2) {
      await _showQuickActionSheet(context);
      return;
    }
    if (index == 4) {
      Get.toNamed(AppRoutes.PROFILE);
      return;
    }
    if (index == 1) {
      await _scrollToSection(_statsKey);
      return;
    }
    if (index == 3) {
      await _scrollToSection(_logKey);
      return;
    }
    if (index == 0) {
      await _scrollToSection(_topKey);
      await _syncDashboard(authController, showToast: true);
    }
  }

  Future<void> _showQuickActionSheet(BuildContext context) async {
    final today = DateTime.now();
    final actions = const <Map<String, String>>[
      {'label': 'Leaving Home', 'note': 'Morning movement confirmed'},
      {'label': 'Reached Office', 'note': 'Arrival confirmed'},
      {'label': 'Start Focus', 'note': 'Deep work session started'},
      {'label': 'Workday Done', 'note': 'Office workday wrap-up completed'},
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Instantly record office timeline events.',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...actions.map((action) {
                  final label = action['label']!;
                  final note = action['note']!;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final marked = await controller.toggleConfirmationForDate(
                          type: label,
                          date: today,
                          note: note,
                        );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                        Get.snackbar(
                          marked ? 'Saved' : 'Removed',
                          marked ? '$label recorded.' : '$label unmarked.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      child: Text(label),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 78,
      child: ListView.builder(
        itemCount: 7,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 3));
          final isToday = index == 3;
          return Container(
            width: 58,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: isToday ? AppTheme.accentYellow : AppTheme.panel,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('d').format(date),
                  style: TextStyle(
                    color: isToday
                        ? const Color(0xFF102341)
                        : AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('E').format(date),
                  style: TextStyle(
                    color: isToday
                        ? const Color(0xFF314B6E)
                        : AppTheme.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommuteRecommendationCard(
    BuildContext context,
    AuthController authController,
  ) {
    return Obx(() {
      final user = authController.user.value ?? const <String, dynamic>{};
      final officeStart = (user['officeStartTime'] ?? '08:15').toString();
      final officeEnd = (user['officeEndTime'] ?? '18:00').toString();
      final recommendation = controller.getCommuteRecommendation(
        officeStartTime: officeStart,
        officeEndTime: officeEnd,
      );
      final isUrgent =
          recommendation.contains('running late') ||
          recommendation.contains('time to leave now') ||
          recommendation.contains('already started');

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.panelSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isUrgent
                    ? Icons.directions_car_filled_rounded
                    : Icons.directions_bus_filled_rounded,
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Commute Advice',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recommendation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildScheduleList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.schedules.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'No schedules for today.',
            style: TextStyle(color: AppTheme.textGrey),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.schedules.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final schedule = controller.schedules[index];

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.panelSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      schedule.icon,
                      style: const TextStyle(fontSize: 19),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.name,
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('hh:mm a').format(schedule.time),
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: schedule.isEnabled,
                  onChanged: (_) {},
                  activeThumbColor: AppTheme.accentYellow,
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildProfessionalTipsSection(BuildContext context) {
    final tips = controller.getTodayTips();
    final accents = <Color>[
      AppTheme.primaryTeal,
      AppTheme.accentYellow,
      AppTheme.accentOrange,
    ];
    final icons = <IconData>[
      Icons.self_improvement_rounded,
      Icons.workspace_premium_rounded,
      Icons.trending_up_rounded,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Growth Tips',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('Habit + Pro', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 186,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final tip = tips[index];
              final accent = accents[index % accents.length];
              final icon = icons[index % icons.length];

              return Container(
                width: 292,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF18325A), Color(0xFF112746)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: accent.withOpacity(0.48)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: accent, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tip['category'] ?? 'Tip',
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tip['title'] ?? 'Smart Tip',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip['subtitle'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.panelSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: AppTheme.textDark,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              tip['action'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyHabitChecklist(BuildContext context) {
    final habitIcons = <String, IconData>{
      'morning_plan': Icons.checklist_rtl_rounded,
      'inbox_batch': Icons.mail_outline_rounded,
      'deep_work': Icons.center_focus_strong_rounded,
      'status_update': Icons.groups_rounded,
      'day_review': Icons.fact_check_rounded,
    };

    return Obx(() {
      final habits = controller.getDailyHabits();
      final completed = controller.completedHabitCount;
      final total = habits.length;
      final progress = controller.habitCompletionRatio;
      final todayOffDay = controller.isTodayOffDay;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Habit Checklist',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: completed == 0
                      ? null
                      : () async {
                          await controller.clearDailyHabits();
                          Get.snackbar(
                            'Reset',
                            'Daily checklist reset for today.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$completed / $total completed',
              style: const TextStyle(
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress,
                backgroundColor: AppTheme.panelSoft,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryTeal,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (todayOffDay)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentOrange.withOpacity(0.7),
                  ),
                ),
                child: const Text(
                  'Today is marked as Off Day. Habit checklist is paused and excluded from normal scoring.',
                  style: TextStyle(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.3,
                  ),
                ),
              ),
            Column(
              children: habits.map((habit) {
                final id = habit['id'] ?? '';
                final checked = controller.habitChecks[id] == true;
                final note = controller.habitNotes[id] ?? '';
                final icon = habitIcons[id] ?? Icons.task_alt_rounded;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    if (todayOffDay) return;
                    if (id == 'morning_plan' && checked) {
                      await _editMorningPlanNote(context, id);
                      return;
                    }
                    await _handleHabitToggle(
                      context,
                      habitId: id,
                      nextValue: !checked,
                      habitTitle: habit['title'] ?? 'Habit',
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: checked
                          ? AppTheme.primaryTeal.withOpacity(0.16)
                          : AppTheme.panelSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: checked
                            ? AppTheme.primaryTeal.withOpacity(0.55)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: checked
                                ? AppTheme.primaryTeal.withOpacity(0.2)
                                : AppTheme.panel,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            icon,
                            size: 19,
                            color: checked
                                ? AppTheme.primaryTeal
                                : AppTheme.textGrey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit['title'] ?? 'Habit',
                                style: TextStyle(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  decoration: checked
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                habit['subtitle'] ?? '',
                                style: const TextStyle(
                                  color: AppTheme.textGrey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                              if (note.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'Saved: $note',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.accentYellow,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Checkbox(
                          value: checked,
                          onChanged: (value) async {
                            if (todayOffDay) return;
                            await _handleHabitToggle(
                              context,
                              habitId: id,
                              nextValue: value ?? false,
                              habitTitle: habit['title'] ?? 'Habit',
                            );
                          },
                          activeColor: AppTheme.primaryTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildWeeklyOffDaySelector(BuildContext context) {
    return Obx(() {
      final weekDays = controller.offDayWeekDates;
      final weekStart = weekDays.first;
      final weekEnd = weekDays.last;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Week Off-Day Planner',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _weekNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => controller.shiftOffDayWeek(-1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.panelSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${DateFormat('dd MMM').format(weekStart)} - ${DateFormat('dd MMM').format(weekEnd)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _weekNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => controller.shiftOffDayWeek(1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Mark/unmark off days. Off days are stored in database and excluded from normal habit scoring.',
              style: TextStyle(
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: weekDays.map((date) {
                final key = DateFormat('yyyy-MM-dd').format(date);
                final isOff = controller.offDayByDateKey[key] == true;
                final isToday = _isSameDay(date, DateTime.now());
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await controller.toggleOffDayForDate(date, !isOff);
                        Get.snackbar(
                          !isOff ? 'Off Day Added' : 'Off Day Removed',
                          '${DateFormat('EEE, dd MMM').format(date)} updated.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isOff
                              ? AppTheme.accentOrange.withOpacity(0.25)
                              : AppTheme.panelSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOff
                                ? AppTheme.accentOrange
                                : (isToday
                                      ? AppTheme.primaryTeal.withOpacity(0.6)
                                      : Colors.transparent),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('E').format(date),
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              DateFormat('d').format(date),
                              style: TextStyle(
                                color: isOff
                                    ? AppTheme.accentOrange
                                    : AppTheme.textDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isOff ? 'Off' : 'On',
                              style: TextStyle(
                                color: isOff
                                    ? AppTheme.accentOrange
                                    : AppTheme.textGrey,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDailyStatsCurve(BuildContext context, AuthController authController) {
    return Obx(() {
      final user = authController.user.value ?? const <String, dynamic>{};
      final stats = controller.getWeeklyStats(
        officeStartTime: (user['officeStartTime'] ?? '08:15').toString(),
        officeEndTime: (user['officeEndTime'] ?? '18:00').toString(),
      );
      final todayIsOffDay = stats.last['isOffDay'] == true;
      final todayScore = ((stats.last['score'] as double) * 100).round();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    todayIsOffDay ? 'Off Day' : '$todayScore% Today',
                    style: const TextStyle(
                      color: AppTheme.accentYellow,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Last 7 days synced habit + office timing score',
              style: TextStyle(
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 154,
              child: CustomPaint(
                painter: _StatsCurvePainter(
                  values: stats.map((e) => e['score'] as double).toList(),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: stats
                  .map(
                    (e) => Text(
                      DateFormat('E').format(e['date'] as DateTime),
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildConfirmationSection(BuildContext context) {
    const actions = [
      {
        'label': 'Leaving Home',
        'note': 'Morning movement confirmed',
        'icon': Icons.home_work_outlined,
      },
      {
        'label': 'Reached Office',
        'note': 'Arrival confirmed',
        'icon': Icons.business_center_outlined,
      },
      {
        'label': 'Start Focus',
        'note': 'Deep work session started',
        'icon': Icons.psychology_alt_outlined,
      },
      {
        'label': 'Workday Done',
        'note': 'Office workday wrap-up completed',
        'icon': Icons.verified_outlined,
      },
    ];

    return Obx(() {
      final allRecords = controller.confirmations;
      final selectedDate = controller.selectedLogDate.value;
      final records = controller.selectedDateConfirmations;
      final isSelectedToday = controller.isSelectedDateToday;
      final dates = controller.confirmationDates;
      final latestByTypeForSelectedDate = <String, DateTime>{};
      for (final record in records) {
        final type = record['type']?.toString() ?? '';
        final time = record['time'] as DateTime;
        if (type.isEmpty) continue;
        latestByTypeForSelectedDate.putIfAbsent(type, () => time);
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confirmation Log',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: allRecords.isEmpty
                      ? null
                      : () async {
                          await controller.clearConfirmations();
                          Get.snackbar(
                            'Cleared',
                            'Confirmation records removed.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final isSelected = _isSameDay(date, selectedDate);
                  final isToday = _isSameDay(date, DateTime.now());
                  final isOffDay = controller.isOffDayOn(date);
                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => controller.setSelectedLogDate(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryTeal.withOpacity(0.28)
                            : AppTheme.panelSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryTeal
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '${isToday ? 'Today' : DateFormat('dd MMM').format(date)}${isOffDay ? ' • Off' : ''}',
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            if (controller.isOffDayOn(selectedDate))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${DateFormat('dd MMM yyyy').format(selectedDate)} is marked as Off Day.',
                  style: const TextStyle(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (!isSelectedToday)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.panelSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Viewing logs for ${DateFormat('dd MMM yyyy').format(selectedDate)}. Action buttons record only today.',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actions.map((action) {
                final label = action['label']! as String;
                final markedTime = latestByTypeForSelectedDate[label];
                final isMarked = markedTime != null;
                final isJustMarked =
                    controller.recentConfirmationType.value == label;
                final pulseKey =
                    '${label}_${controller.recentConfirmationEpoch.value}';
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    if (controller.isOffDayOn(selectedDate)) {
                      Get.snackbar(
                        'Off Day',
                        'Selected date is marked off day. Unmark it first to add logs.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    final isMarkedNow = await controller
                        .toggleConfirmationForDate(
                          type: label,
                          date: selectedDate,
                          note: action['note']! as String,
                        );
                    Get.snackbar(
                      isMarkedNow ? 'Saved' : 'Removed',
                      isMarkedNow ? '$label recorded.' : '$label unmarked.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  onLongPress: () async {
                    if (controller.isOffDayOn(selectedDate)) {
                      Get.snackbar(
                        'Off Day',
                        'Selected date is marked off day. Unmark it first to edit logs.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    final selectedTime = await _pickLogTimeForDate(
                      context,
                      date: selectedDate,
                      initial: markedTime,
                    );
                    if (selectedTime == null) return;
                    await controller.upsertConfirmationForDate(
                      type: label,
                      date: selectedDate,
                      note: action['note']! as String,
                      at: selectedTime,
                    );
                    Get.snackbar(
                      'Updated',
                      '$label time updated.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(pulseKey),
                    tween: Tween(begin: isJustMarked ? 0.96 : 1.0, end: 1.0),
                    duration: const Duration(milliseconds: 340),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      width: 156,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMarked
                            ? AppTheme.primaryTeal.withOpacity(0.20)
                            : AppTheme.panelSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isMarked
                              ? AppTheme.primaryTeal
                              : AppTheme.primaryTeal.withOpacity(0.35),
                          width: isMarked ? 1.6 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              isMarked
                                  ? Icons.check_circle_rounded
                                  : action['icon']! as IconData,
                              key: ValueKey('${label}_$isMarked'),
                              color: isMarked
                                  ? AppTheme.accentYellow
                                  : AppTheme.primaryTeal,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    height: 1.2,
                                  ),
                                ),
                                if (isMarked) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('hh:mm a').format(markedTime),
                                    style: const TextStyle(
                                      color: AppTheme.textGrey,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            if (records.isEmpty)
              Text(
                isSelectedToday
                    ? 'No confirmations yet for today. Tap any action above to record activity.'
                    : 'No confirmation logs found for ${DateFormat('dd MMM yyyy').format(selectedDate)}.',
                style: const TextStyle(
                  color: AppTheme.textGrey,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Column(
                children: records.take(6).map((record) {
                  final time = record['time'] as DateTime;
                  final recordId = record['id']?.toString() ?? '';
                  final absoluteTime = DateFormat(
                    'dd MMM, hh:mm a',
                  ).format(time);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppTheme.panelSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            color: AppTheme.accentYellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record['type']?.toString() ?? 'Action',
                                style: const TextStyle(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                record['note']?.toString() ?? '',
                                style: const TextStyle(
                                  color: AppTheme.textGrey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Recorded: $absoluteTime (${_timeAgo(time)})',
                                style: const TextStyle(
                                  color: AppTheme.textGrey,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (controller.isOffDayOn(selectedDate)) {
                              Get.snackbar(
                                'Off Day',
                                'Selected date is marked off day. Unmark it first to edit logs.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }
                            final updated = await _pickLogTimeForDate(
                              context,
                              date: DateTime(time.year, time.month, time.day),
                              initial: time,
                            );
                            if (updated == null) return;
                            await controller.updateConfirmationTime(
                              recordId,
                              updated,
                            );
                            Get.snackbar(
                              'Updated',
                              'Log time updated.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          icon: const Icon(
                            Icons.schedule_rounded,
                            color: AppTheme.textGrey,
                            size: 18,
                          ),
                          tooltip: 'Update time',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildMonthlyHabitAnalysisCard(BuildContext context) {
    return Obx(() {
      final summary = controller.monthlyHabitSummary;
      final days = controller.monthlyHabitDays;
      final averageRate = controller.monthlyAverageRate;
      final level = controller.monthlyStandardLevel;
      final bestRate = (summary['bestRate'] as num?)?.toDouble() ?? 0;
      final reportedDays = (summary['daysReported'] as num?)?.toInt() ?? 0;
      final eliteDays = (summary['eliteDays'] as num?)?.toInt() ?? 0;
      final offDays = (summary['offDays'] as num?)?.toInt() ?? 0;

      Color levelColor;
      if (averageRate >= 0.85) {
        levelColor = AppTheme.accentYellow;
      } else if (averageRate >= 0.70) {
        levelColor = AppTheme.primaryTeal;
      } else if (averageRate >= 0.50) {
        levelColor = AppTheme.accentOrange;
      } else {
        levelColor = const Color(0xFFFF7E7E);
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 360;
                final badge = Container(
                  constraints: BoxConstraints(
                    maxWidth: isCompact ? constraints.maxWidth : 150,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    level,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Habit Analysis',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      badge,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Monthly Habit Analysis',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    badge,
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _analysisMetric(
                        label: 'Average',
                        value: '${(averageRate * 100).round()}%',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _analysisMetric(
                        label: 'Best Day',
                        value: '${(bestRate * 100).round()}%',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _analysisMetric(
                        label: 'Elite Days',
                        value: '$eliteDays',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _analysisMetric(
                        label: 'Off Days',
                        value: '$offDays',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (controller.isMonthlyAnalyticsLoading.value)
              const SizedBox(
                height: 42,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (days.isEmpty)
              const Text(
                'No monthly report yet. Start ticking habits to build analytics.',
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              SizedBox(
                height: 72,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: days.take(14).map((d) {
                    final rate = (d['completionRate'] as num?)?.toDouble() ?? 0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 16 + (rate * 52),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryTeal,
                                  AppTheme.accentYellow,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              'Normal days: $reportedDays | Off days: $offDays | Standards: Elite 85%+, Strong 70%+, Developing 50%+',
              softWrap: true,
              style: const TextStyle(
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _analysisMetric({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.panelSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekNavButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.panelSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.textDark, size: 19),
      ),
    );
  }

  Future<DateTime?> _pickLogTimeForDate(
    BuildContext context, {
    required DateTime date,
    DateTime? initial,
  }) async {
    final initialTime = TimeOfDay.fromDateTime(initial ?? DateTime.now());
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Set log time',
    );
    if (picked == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      picked.hour,
      picked.minute,
    );
  }

  Future<void> _handleHabitToggle(
    BuildContext context, {
    required String habitId,
    required bool nextValue,
    required String habitTitle,
  }) async {
    if (controller.isTodayOffDay) {
      Get.snackbar(
        'Off Day',
        'Today is marked as off day. Unmark off day to continue normal habits.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (habitId == 'morning_plan') {
      if (nextValue) {
        final result = await _showMorningPlanningDialog(
          context,
          initialValue: controller.habitNotes[habitId] ?? '',
        );
        if (result == null) {
          return;
        }

        await controller.toggleHabit(habitId, true);

        if (!result.skipped) {
          await controller.updateHabitNote(habitId, result.note);
        }

        await controller.addConfirmation(
          'Morning Planning',
          note: result.skipped
              ? 'Morning planning marked complete'
              : (result.note.isEmpty
                    ? 'Morning planning marked complete'
                    : result.note),
        );
      } else {
        await controller.toggleHabit(habitId, false);
        await controller.updateHabitNote(habitId, '');
      }
      return;
    }

    await controller.toggleHabit(habitId, nextValue);

    if (nextValue) {
      await controller.addConfirmation(
        habitTitle,
        note: '$habitTitle marked complete',
      );
    }
  }

  Future<void> _editMorningPlanNote(
    BuildContext context,
    String habitId,
  ) async {
    final result = await _showMorningPlanningDialog(
      context,
      initialValue: controller.habitNotes[habitId] ?? '',
      title: 'Update Morning Plan',
      skipLabel: 'Keep Current',
    );
    if (result == null || result.skipped) return;

    await controller.updateHabitNote(habitId, result.note);
    await controller.addConfirmation(
      'Morning Planning',
      note: result.note.isEmpty
          ? 'Morning planning note updated'
          : 'Plan updated: ${result.note}',
    );
  }

  Future<_MorningPlanDialogResult?> _showMorningPlanningDialog(
    BuildContext context, {
    String initialValue = '',
    String title = 'Morning Planning',
    String skipLabel = 'Skip',
  }) async {
    if (Get.isDialogOpen == true) return null;
    final customController = TextEditingController(text: initialValue);
    final selected = <String>{};
    final quickOptions = <String>[
      'Finish critical backend task',
      'Share team status update',
      'Complete one deep-focus block',
      'Review and close pending items',
      'Prepare meeting priorities',
    ];

    final result = await showDialog<_MorningPlanDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.panel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pick your priorities and add custom notes. This will be saved for today.',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickOptions.map((option) {
                        final isSelected = selected.contains(option);
                        return ChoiceChip(
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                selected.add(option);
                              } else {
                                selected.remove(option);
                              }
                            });
                          },
                          selectedColor: AppTheme.primaryTeal.withOpacity(0.3),
                          backgroundColor: AppTheme.panelSoft,
                          labelStyle: const TextStyle(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: customController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Custom plan',
                        hintText: 'Example: API fixes, test run, client update',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(const _MorningPlanDialogResult.skipped()),
                  child: Text(skipLabel),
                ),
                FilledButton(
                  onPressed: () {
                    final parts = <String>[
                      if (selected.isNotEmpty) selected.join(', '),
                      if (customController.text.trim().isNotEmpty)
                        customController.text.trim(),
                    ];
                    Navigator.of(
                      dialogContext,
                    ).pop(_MorningPlanDialogResult.saved(parts.join(' | ')));
                  },
                  child: const Text('Save Plan'),
                ),
              ],
            );
          },
        );
      },
    );

    customController.dispose();
    return result;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day ago';
  }

  Widget _roundIcon(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppTheme.textDark, size: 20),
    );
  }
}

class _MorningPlanDialogResult {
  const _MorningPlanDialogResult._({required this.skipped, required this.note});

  const _MorningPlanDialogResult.skipped() : this._(skipped: true, note: '');

  const _MorningPlanDialogResult.saved(String note)
    : this._(skipped: false, note: note);

  final bool skipped;
  final String note;
}

class _StatsCurvePainter extends CustomPainter {
  _StatsCurvePainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final gridPaint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height - (values[i].clamp(0.0, 1.0) * size.height);
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final control = Offset((prev.dx + curr.dx) / 2, prev.dy);
      final control2 = Offset((prev.dx + curr.dx) / 2, curr.dy);
      linePath.cubicTo(
        control.dx,
        control.dy,
        control2.dx,
        control2.dy,
        curr.dx,
        curr.dy,
      );
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x662FC6D3), Color(0x11000000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.primaryTeal, AppTheme.accentYellow],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = AppTheme.accentYellow;
    for (final point in points) {
      canvas.drawCircle(point, 3.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StatsCurvePainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}

class _DigitalClockCard extends StatefulWidget {
  const _DigitalClockCard();

  @override
  State<_DigitalClockCard> createState() => _DigitalClockCardState();
}

class _DigitalClockCardState extends State<_DigitalClockCard> {
  late DateTime _now;
  Timer? _timer;
  final DateFormat _dateFormat = DateFormat('EEEE, MMM d');

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    WidgetsBinding.instance.addObserver(_clockLifecycleObserver);
    _startTicker();
  }

  late final WidgetsBindingObserver _clockLifecycleObserver =
      _ClockLifecycleObserver(
        onInactive: () => _timer?.cancel(),
        onResume: () {
          if (!mounted) return;
          setState(() => _now = DateTime.now());
          _startTicker();
        },
      );

  String _two(int value) => value.toString().padLeft(2, '0');

  String _formattedTime(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '${_two(hour12)}:${_two(dt.minute)}:${_two(dt.second)} $suffix';
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(_clockLifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _formattedTime(_now);
    final dateText = _dateFormat.format(_now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F3F6E), Color(0xFF102A4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x442FC6D3),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Time',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              timeText,
              style: const TextStyle(
                color: AppTheme.accentYellow,
                fontWeight: FontWeight.w900,
                fontSize: 30,
                letterSpacing: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateText,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockLifecycleObserver with WidgetsBindingObserver {
  _ClockLifecycleObserver({required this.onInactive, required this.onResume});

  final VoidCallback onInactive;
  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      onInactive();
    }
  }
}
