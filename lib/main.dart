import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'data/services/mongodb_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'modules/auth/bindings/auth_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialization
  await MongoDBService.connect();
  await NotificationService.init();
  await NotificationService.scheduleDailyAlarm();
  
  final authService = AuthService();
  final bool loggedIn = await authService.isLoggedIn();

  runApp(
    GetMaterialApp(
      title: 'Daily Check',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: loggedIn ? AppRoutes.HOME : AppRoutes.LOGIN,
      getPages: AppPages.pages,
      initialBinding: AuthBinding(), // Ensure AuthController is available globally
    ),
  );
}
