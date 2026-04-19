import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final isLoading = false.obs;
  final isProfileLoading = false.obs;
  final isProfileSaving = false.obs;
  final user = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    bool loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      user.value = await _authService.getUser();
      await fetchProfile();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      final result = await _authService.login(email, password);
      if (result['token'] != null) {
        user.value = result['user'];
        Get.offAllNamed(AppRoutes.HOME);
        return true;
      } else {
        Get.snackbar("Error", result['message'] ?? "Login failed");
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signup(
    String name,
    String email,
    String company,
    String designation,
    String password,
  ) async {
    try {
      isLoading.value = true;
      final result = await _authService.signup(
        name: name,
        email: email,
        company: company,
        designation: designation,
        password: password,
      );
      if (result['token'] != null) {
        user.value = result['user'];
        Get.offAllNamed(AppRoutes.HOME);
      } else {
        Get.snackbar("Error", result['message'] ?? "Signup failed");
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      isLoading.value = true;
      final result = await _authService.forgotPassword(email);
      if (result['message'] != null && result['message'].contains('sent')) {
        Get.snackbar("Success", "Reset link sent to your email");
      } else {
        Get.snackbar("Error", result['message'] ?? "Failed to send reset link");
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchProfile() async {
    try {
      isProfileLoading.value = true;
      final result = await _authService.fetchProfile();
      if (result['user'] != null) {
        user.value = Map<String, dynamic>.from(result['user']);
      } else if (result['message'] != null) {
        Get.snackbar('Error', result['message']);
      }
    } finally {
      isProfileLoading.value = false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String company,
    required String designation,
    String? officeStartTime,
    String? officeEndTime,
  }) async {
    try {
      isProfileSaving.value = true;
      final result = await _authService.updateProfile(
        name: name,
        company: company,
        designation: designation,
        officeStartTime: officeStartTime,
        officeEndTime: officeEndTime,
      );
      if (result['user'] != null) {
        final merged = <String, dynamic>{
          ...(user.value ?? <String, dynamic>{}),
          ...Map<String, dynamic>.from(result['user']),
          if (officeStartTime != null && officeStartTime.trim().isNotEmpty)
            'officeStartTime': officeStartTime.trim(),
          if (officeEndTime != null && officeEndTime.trim().isNotEmpty)
            'officeEndTime': officeEndTime.trim(),
        };
        user.value = merged;
        Get.snackbar('Success', result['message'] ?? 'Profile updated');
        return true;
      }
      Get.snackbar('Error', result['message'] ?? 'Failed to update profile');
      return false;
    } finally {
      isProfileSaving.value = false;
    }
  }

  void logout() async {
    await _authService.logout();
    user.value = null;
    Get.offAllNamed(AppRoutes.LOGIN);
  }
}
