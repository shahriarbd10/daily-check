import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/home_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(authController),
              const SizedBox(height: 22),
              Obx(
                () => Text(
                  'Every Day Your\nTask Plan',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              const SizedBox(height: 6),
              Obx(
                () => Text(
                  'Welcome, ${authController.user.value?['name'] ?? 'User'}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 20),
              _buildPriorityGrid(),
              const SizedBox(height: 22),
              Text('This Week', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _buildHorizontalCalendar(),
              const SizedBox(height: 22),
              _buildCommuteRecommendationCard(context),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'On Going Task',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    DateFormat('MMM d, EEEE').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildScheduleList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.FORGOT_PASSWORD),
        backgroundColor: AppTheme.accentYellow,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Color(0xFF12263F)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTopBar(AuthController authController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _roundIcon(Icons.menu_rounded),
        const Text(
          'Task Management App',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        InkWell(
          onTap: authController.logout,
          borderRadius: BorderRadius.circular(12),
          child: _roundIcon(Icons.logout_rounded),
        ),
      ],
    );
  }

  Widget _buildPriorityGrid() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 176,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.checklist_rounded,
                  color: Color(0xFF102341),
                  size: 32,
                ),
                SizedBox(height: 10),
                Text(
                  'First Priority',
                  style: TextStyle(
                    color: Color(0xFF102341),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '10 task',
                  style: TextStyle(
                    color: Color(0xFF2F476C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 176,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.timelapse_rounded, color: Color(0xFF102341)),
                        SizedBox(height: 8),
                        Text(
                          'Second Priority',
                          style: TextStyle(
                            color: Color(0xFF102341),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '12 task',
                          style: TextStyle(
                            color: Color(0xFF244067),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4C2E8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.pending_actions_rounded,
                          color: Color(0xFF102341),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Third Priority',
                          style: TextStyle(
                            color: Color(0xFF102341),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '28 task',
                          style: TextStyle(
                            color: Color(0xFF244067),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildCommuteRecommendationCard(BuildContext context) {
    final recommendation = controller.getCommuteRecommendation();
    final isLate = recommendation.contains('Uber');

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
              isLate
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
          final progress = _progressByIndex(index);
          final cardColor = _cardByIndex(index);

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0x1A0D1E3A),
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
                              color: Color(0xFF102341),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            DateFormat('hh:mm a').format(schedule.time),
                            style: const TextStyle(
                              color: Color(0xFF3E5678),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF314B6E),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: progress,
                          backgroundColor: const Color(0x552B4568),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF102341),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Color(0xFF102341),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      color: const Color(0xFF0B1730),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.home_rounded,
                color: AppTheme.accentYellow,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.calendar_today_rounded,
                color: AppTheme.textGrey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.checklist_rounded,
                color: AppTheme.textGrey,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.person_outline_rounded,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
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

  double _progressByIndex(int index) {
    const values = [0.5, 0.8, 0.72, 0.36, 0.91];
    return values[index % values.length];
  }

  Color _cardByIndex(int index) {
    const colors = [
      Color(0xFFBFEA92),
      Color(0xFF52D8EE),
      Color(0xFFD8C8EA),
      Color(0xFFF2C986),
      Color(0xFFC9D9FA),
    ];
    return colors[index % colors.length];
  }
}
