import 'package:bcreative_ems/app/theme/app_colors.dart';
import 'package:bcreative_ems/core/utils/responsive.dart';
import 'package:bcreative_ems/features/auth/viewmodels/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= Breakpoints.desktop;

    return Scaffold(
      body: Row(
        children: [
          if (isWide) Expanded(child: _BrandPanel()),
          Expanded(
            flex: isWide ? 1 : 2,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _LoginForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _LoginBrandLogo(size: 350),
              const SizedBox(height: 8),
              const Text(
                'B-Creative EMS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Employee Management System\nSecure access for your organization.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginBrandLogo extends StatelessWidget {
  const _LoginBrandLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    // The transparent source has generous clear padding. Cropping only that
    // padding keeps the enlarged artwork close to the text below it.
    return SizedBox(
      width: size,
      height: size * .62,
      child: ClipRect(
        child: OverflowBox(
          minWidth: size,
          maxWidth: size,
          minHeight: size,
          maxHeight: size,
          alignment: Alignment.center,
          child: Image.asset(
            'assets/branding/bcreative_logo_white.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel: 'BCreative',
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends GetView<LoginController> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isDesktop(context)) ...[
            Container(
              height: 64,
              width: 64,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                'assets/branding/bcreative_logo_white.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                semanticLabel: 'BCreative',
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('Sign in', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Use your company email and password.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: controller.validateEmail,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          Obx(
            () => TextFormField(
              controller: controller.passwordController,
              obscureText: controller.obscurePassword.value,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscurePassword.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => controller.obscurePassword.value =
                      !controller.obscurePassword.value,
                ),
              ),
              validator: controller.validatePassword,
              onFieldSubmitted: (_) => controller.signIn(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: controller.forgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => FilledButton(
              onPressed: controller.isLoading.value ? null : controller.signIn,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign in'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Accounts are created by your administrator. Self-registration is not available.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
