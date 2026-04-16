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

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      final result = await _authService.login(email, password);
      if (result['token'] != null) {
        user.value = result['user'];
        Get.offAllNamed(AppRoutes.HOME);
      } else {
        Get.snackbar("Error", result['message'] ?? "Login failed");
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
  }) async {
    try {
      isProfileSaving.value = true;
      final result = await _authService.updateProfile(
        name: name,
        company: company,
        designation: designation,
      );
      if (result['user'] != null) {
        user.value = Map<String, dynamic>.from(result['user']);
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
