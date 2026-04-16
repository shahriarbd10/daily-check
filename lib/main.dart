import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/mongodb_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'providers/schedule_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MongoDBService.connect();
  await NotificationService.init();
  await NotificationService.scheduleDailyAlarm();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScheduleProvider()..fetchSchedules()),
      ],
      child: const DailyCheckApp(),
    ),
  );
}

class DailyCheckApp extends StatelessWidget {
  const DailyCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Check',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
