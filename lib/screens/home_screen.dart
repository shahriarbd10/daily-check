import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';
import '../theme/app_theme.dart';
import 'add_schedule_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                DateFormat('MMM d, EEEE').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "Tracking your\nroutine",
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 24),
              _buildHorizontalCalendar(),
              const SizedBox(height: 24),
              _buildCommuteRecommendationCard(context, scheduleProvider),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Your Schedule", style: Theme.of(context).textTheme.titleLarge),
                  GestureDetector(
                    onTap: () {},
                    child: const Text("See more", style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildScheduleList(scheduleProvider),
              const SizedBox(height: 100), // Space for bottom
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddScheduleScreen()),
          );
        },
        backgroundColor: AppTheme.primaryTeal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 3));
          final isToday = index == 3;
          return Container(
            width: 50,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isToday ? AppTheme.accentOrange : Colors.transparent,
              borderRadius: BorderRadius.circular(25),
              border: isToday ? null : Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('E').format(date)[0],
                  style: TextStyle(
                    color: isToday ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    color: isToday ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommuteRecommendationCard(BuildContext context, ScheduleProvider provider) {
    final recommendation = provider.getCommuteRecommendation();
    final isLate = recommendation.contains("Uber");

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLate ? Icons.directions_car : Icons.directions_bus,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Commute Advice",
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(ScheduleProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.schedules.isEmpty) {
      return const Center(child: Text("No schedules for today."));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.schedules.length,
      itemBuilder: (context, index) {
        final schedule = provider.schedules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
              child: Text(schedule.icon, style: const TextStyle(fontSize: 20)),
            ),
            title: Text(schedule.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('hh:mm a').format(schedule.time)),
            trailing: Switch(
              value: schedule.isEnabled,
              activeColor: AppTheme.primaryTeal,
              onChanged: (val) {},
            ),
          ),
        );
      },
    );
  }
}
