import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/screens/business/form.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/components/appBackButton.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<Core>().auth;
    final businessProvider = context.read<Core>().business;

    final success = await authProvider.signup(
      _nameController.text.trim(),
      _emailController.text.trim().toLowerCase(),
      _passwordController.text,
      _confirmPasswordController.text,
    );

    if (success && mounted) {
      await businessProvider.clearSelectedBusiness();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        getPageRoute(const BusinessFormScreen()),
        (route) => false,
      );
    } else if (!success && mounted) {
      showErrorToast(authProvider.error ?? 'Signup failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = context.select<Core, bool>((c) => c.auth.isLoading);

    return Scaffold(
      body: _AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: const Padding(
                  padding: EdgeInsets.only(left: 20, top: 12),
                  child: AppBackButton(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      const _AnimatedLogo(),
                      Text(
                        'create_account'.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.gray900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start managing your business smartly',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: _GlassmorphicCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fill in your details',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppTheme.gray800,
                                ),
                              ),
                              const SizedBox(height: 20),
                              AppTextField(
                                controller: _nameController,
                                labelText: 'name'.tr(),
                                hintText: 'Enter your full name',
                                prefixIcon: Icons.person_outline,
                                validator: (val) => Validators.validateRequired(val, 'Name'),
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _emailController,
                                labelText: 'email'.tr(),
                                hintText: 'Enter your email address',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: Validators.validateEmail,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _passwordController,
                                labelText: 'password'.tr(),
                                hintText: 'Enter password (min 6 characters)',
                                isPassword: true,
                                prefixIcon: Icons.lock_outline_rounded,
                                validator: Validators.validatePassword,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _confirmPasswordController,
                                labelText: 'confirm_password'.tr(),
                                hintText: 'Re-enter your password',
                                isPassword: true,
                                prefixIcon: Icons.lock_clock_outlined,
                                validator: (val) => Validators.validateConfirmPassword(val, _passwordController.text),
                              ),
                              const SizedBox(height: 24),
                              AppButton(
                                text: 'signup'.tr(),
                                isLoading: isLoading,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${'already_have_account'.tr().split('?').first}? ",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  final Widget child;

  const _AmbientBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: isDark ? AppTheme.gray950 : AppTheme.gray50,
          ),
        ),
        Positioned(
          top: -size.height * 0.15,
          left: -size.width * 0.2,
          width: size.width * 0.7,
          height: size.width * 0.7,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? Colors.white : AppTheme.primary).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.35,
          right: -size.width * 0.25,
          width: size.width * 0.8,
          height: size.width * 0.8,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? AppTheme.accentDark : AppTheme.accent).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: const SizedBox.shrink(),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo();

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_controller);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SizedBox(
          width: 80,
          height: 80,
          child: Image.asset(
            'assets/images/app_logo_foreground.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _GlassmorphicCard extends StatelessWidget {
  final Widget child;

  const _GlassmorphicCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.surfaceDark.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppTheme.glassBorderDark : AppTheme.glassBorderLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      ),
    );
  }
}
