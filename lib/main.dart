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

  // Avoid blocking startup forever on network/device-specific init.
  try {
    await MongoDBService.connect().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Mongo init skipped: $e');
  }

  try {
    await NotificationService.init().timeout(const Duration(seconds: 5));
    await NotificationService.scheduleDailyAlarm().timeout(
      const Duration(seconds: 5),
    );
  } catch (e) {
    debugPrint('Notification init skipped: $e');
  }

  final authService = AuthService();
  bool loggedIn = false;
  try {
    loggedIn = await authService.isLoggedIn().timeout(
      const Duration(seconds: 3),
    );
  } catch (e) {
    debugPrint('Auth bootstrap fallback to login: $e');
  }

  runApp(
    GetMaterialApp(
      title: 'Daily Check',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: loggedIn ? AppRoutes.HOME : AppRoutes.LOGIN,
      getPages: AppPages.pages,
      initialBinding: AuthBinding(),
    ),
  );
}
