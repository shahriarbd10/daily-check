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
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
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
              const SizedBox(height: 18),
              _buildHorizontalCalendar(),
              const SizedBox(height: 18),
              _buildCommuteRecommendationCard(context),
              const SizedBox(height: 18),
              Row(
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
