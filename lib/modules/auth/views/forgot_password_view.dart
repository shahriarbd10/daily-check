import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordView extends GetView<AuthController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final isSent = false.obs;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: Get.back,
        ),
        title: const Text('Password Reset'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Obx(
            () => isSent.value
                ? _buildSuccessView(context)
                : _buildInputView(context, emailController, isSent),
          ),
        ),
      ),
    );
  }

  Widget _buildInputView(
    BuildContext context,
    TextEditingController emailController,
    RxBool isSent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forgot Password?',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Enter your email and we will send a reset token.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 30),
        const Text(
          'Email Address',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(hintText: 'example@mail.com'),
        ),
        const SizedBox(height: 22),
        Obx(
          () => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: () async {
                    await controller.forgotPassword(emailController.text);
                    isSent.value = true;
                  },
                  child: const Text('Send Reset Link'),
                ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.panelSoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: AppTheme.accentYellow,
              size: 42,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Check Your Email',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Reset instructions have been sent to your inbox.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: Get.back,
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }
}
