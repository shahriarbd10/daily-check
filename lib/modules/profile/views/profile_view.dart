import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, this.embeddedInHome = false});

  final bool embeddedInHome;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final AuthController _authController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _officeStartController = TextEditingController();
  final TextEditingController _officeEndController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    }
    _authController = Get.find<AuthController>();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      await _authController.fetchProfile();
    } catch (_) {
      // Controller already exposes user-friendly failures via snackbar.
    }
    if (!mounted) return;
    final profile = _authController.user.value;
    if (profile == null) return;

    _nameController.text = (profile['name'] ?? '').toString();
    _emailController.text = (profile['email'] ?? '').toString();
    _companyController.text = (profile['company'] ?? '').toString();
    _designationController.text = (profile['designation'] ?? '').toString();
    _officeStartController.text =
        (profile['officeStartTime'] ?? '08:15').toString();
    _officeEndController.text = (profile['officeEndTime'] ?? '18:00').toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _designationController.dispose();
    _officeStartController.dispose();
    _officeEndController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String value, TimeOfDay fallback) {
    final parts = value.split(':');
    if (parts.length != 2) return fallback;
    final hour = int.tryParse(parts[0]) ?? fallback.hour;
    final minute = int.tryParse(parts[1]) ?? fallback.minute;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return fallback;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _toHm(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({
    required BuildContext context,
    required TextEditingController controller,
    required TimeOfDay fallback,
  }) async {
    final initial = _parseTime(controller.text, fallback);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    setState(() {
      controller.text = _toHm(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Obx(() {
      if (_authController.isProfileLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          widget.embeddedInHome ? 16 : 20,
          20,
          widget.embeddedInHome ? 112 : 20,
        ),
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
            const SizedBox(height: 16),
            const Text(
              'Office Timing',
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Daily statistics and commute advice use these times. Default commute recommendation assumes 75 minutes before office start.',
              style: TextStyle(
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    context: context,
                    label: 'Office Start',
                    controller: _officeStartController,
                    fallback: const TimeOfDay(hour: 8, minute: 15),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeField(
                    context: context,
                    label: 'Office End',
                    controller: _officeEndController,
                    fallback: const TimeOfDay(hour: 18, minute: 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _authController.isProfileSaving.value
                    ? null
                    : () async {
                        await _authController.updateProfile(
                          name: _nameController.text,
                          company: _companyController.text,
                          designation: _designationController.text,
                          officeStartTime: _officeStartController.text,
                          officeEndTime: _officeEndController.text,
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
            ),
          ],
        ),
      );
    });

    if (widget.embeddedInHome) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(child: content),
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

  Widget _buildTimeField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required TimeOfDay fallback,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: () => _pickTime(
            context: context,
            controller: controller,
            fallback: fallback,
          ),
          decoration: const InputDecoration(
            hintText: 'HH:mm',
            suffixIcon: Icon(Icons.schedule_rounded),
          ),
        ),
      ],
    );
  }
}
