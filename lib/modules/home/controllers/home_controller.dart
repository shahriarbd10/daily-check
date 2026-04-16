import 'package:get/get.dart';
import '../../../data/models/schedule.dart';
import '../../../data/services/mongodb_service.dart';

class HomeController extends GetxController {
  final schedules = <Schedule>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSchedules();
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

  String getCommuteRecommendation() {
    final now = DateTime.now();
    final threshold = DateTime(now.year, now.month, now.day, 7, 10);
    final officeTime = DateTime(now.year, now.month, now.day, 8, 15);

    if (now.isBefore(threshold)) {
      return "You're good to go! Local bus or regular transport is perfect for today.";
    } else if (now.isBefore(officeTime)) {
      return "You're running a bit late! Recommendation: Use Uber or Pathao to reach office by 8:15 AM.";
    } else {
      return "Office has already started! Hurry up!";
    }
  }

  void addLocalSchedule(Schedule schedule) {
    schedules.add(schedule);
  }
}
