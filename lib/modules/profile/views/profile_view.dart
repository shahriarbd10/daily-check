import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await _authController.fetchProfile();
    final profile = _authController.user.value;
    if (profile == null) return;

    _nameController.text = (profile['name'] ?? '').toString();
    _emailController.text = (profile['email'] ?? '').toString();
    _companyController.text = (profile['company'] ?? '').toString();
    _designationController.text = (profile['designation'] ?? '').toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Obx(() {
          if (_authController.isProfileLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Information',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _label('Name'),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 12),
                _label('Email'),
                TextField(controller: _emailController, enabled: false),
                const SizedBox(height: 12),
                _label('Company'),
                TextField(
                  controller: _companyController,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 12),
                _label('Designation'),
                TextField(
                  controller: _designationController,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _authController.isProfileSaving.value
                      ? null
                      : () async {
                          await _authController.updateProfile(
                            name: _nameController.text,
                            company: _companyController.text,
                            designation: _designationController.text,
                          );
                        },
                  child: _authController.isProfileSaving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
