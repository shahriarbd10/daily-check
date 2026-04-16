import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/input/lower_case_text_formatter.dart';

class SignUpView extends GetView<AuthController> {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final companyController = TextEditingController();
    final designationController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: Get.back,
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Every Day Your\nTask Plan',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your profile to start using Daily Check.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              _label('Full Name'),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(hintText: 'John Doe'),
              ),
              const SizedBox(height: 14),
              _label('Email Address'),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  LowerCaseTextFormatter(),
                ],
                decoration: const InputDecoration(hintText: 'example@mail.com'),
              ),
              const SizedBox(height: 14),
              _label('Company'),
              const SizedBox(height: 8),
              TextField(
                controller: companyController,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(hintText: 'SM Technology'),
              ),
              const SizedBox(height: 14),
              _label('Designation'),
              const SizedBox(height: 8),
              TextField(
                controller: designationController,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  hintText: 'Backend Developer',
                ),
              ),
              const SizedBox(height: 14),
              _label('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(hintText: 'Enter password'),
              ),
              const SizedBox(height: 26),
              Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () => controller.signup(
                          nameController.text,
                          emailController.text,
                          companyController.text,
                          designationController.text,
                          passwordController.text,
                        ),
                        child: const Text('Sign Up'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textDark,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }
}
