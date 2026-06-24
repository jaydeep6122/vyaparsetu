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
import 'package:vyaparsetu/screens/auth/signup.dart';
import 'package:vyaparsetu/screens/business/form.dart';
import 'package:vyaparsetu/screens/home/home.dart';
import 'package:vyaparsetu/screens/business/list.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/core/Core.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<Core>().auth;
    final businessProvider = context.read<Core>().business;

    final success = await authProvider.login(
      _emailController.text.trim().toLowerCase(),
      _passwordController.text,
    );

    if (success && mounted) {
      await businessProvider.fetchBusinesses();
      if (!mounted) return;

      final count = businessProvider.businesses.length;
      if (count == 0) {
        Navigator.of(
          context,
        ).pushReplacement(getPageRoute(const BusinessFormScreen()));
      } else if (count == 1) {
        await businessProvider.selectBusiness(
          businessProvider.businesses.first,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(getPageRoute(const HomeScreen()));
      } else {
        if (businessProvider.selectedBusiness != null) {
          Navigator.of(
            context,
          ).pushReplacement(getPageRoute(const HomeScreen()));
        } else {
          Navigator.of(
            context,
          ).pushReplacement(getPageRoute(const BusinessListScreen()));
        }
      }
    } else if (!success && mounted) {
      showErrorToast(authProvider.error ?? 'login_failed'.tr());
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
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 24, 0),
                  child: _buildLanguagePicker(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      const _AnimatedLogo(),
                      Text(
                        'VyaparSetu',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.gray900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'smart_business_invoicing'.tr(),
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
                                'sign_in_to_account'.tr(),
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.gray800,
                                ),
                              ),
                              const SizedBox(height: 20),
                              AppTextField(
                                controller: _emailController,
                                labelText: 'email'.tr(),
                                hintText: 'enter_email_hint'.tr(),
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: Validators.validateEmail,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _passwordController,
                                labelText: 'password'.tr(),
                                hintText: 'enter_password_hint'.tr(),
                                isPassword: true,
                                prefixIcon: Icons.lock_outline_rounded,
                                validator: Validators.validatePassword,
                              ),
                              const SizedBox(height: 24),
                              AppButton(
                                text: 'login'.tr(),
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
                            "${'dont_have_account'.tr()} ",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: isDark
                                  ? AppTheme.gray400
                                  : AppTheme.gray500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(
                                context,
                              ).push(getPageRoute(const SignupScreen()));
                            },
                            child: Text(
                              'sign_up_btn'.tr(),
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

  Widget _buildLanguagePicker(BuildContext context) {
    final currentLocale =
        EasyLocalization.of(context)?.currentLocale ?? const Locale('en');
    final localeName = currentLocale.languageCode == 'hi'
        ? 'हिंदी'
        : currentLocale.languageCode == 'gu'
        ? 'ગુજરાતી'
        : 'English';

    final flag = currentLocale.languageCode == 'hi'
        ? '🇮🇳'
        : currentLocale.languageCode == 'gu'
        ? '🇮🇳'
        : '🇺🇸';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showLanguageSelector(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.gray100,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isDark ? AppTheme.gray700 : AppTheme.gray200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              localeName,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.gray800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale =
        EasyLocalization.of(context)?.currentLocale ?? const Locale('en');

    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'select_language'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                context,
                'English',
                '🇺🇸',
                const Locale('en'),
                currentLocale,
              ),
              _buildLanguageOption(
                context,
                'हिंदी (Hindi)',
                '🇮🇳',
                const Locale('hi'),
                currentLocale,
              ),
              _buildLanguageOption(
                context,
                'ગુજરાતી (Gujarati)',
                '🇮🇳',
                const Locale('gu'),
                currentLocale,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String name,
    String flag,
    Locale locale,
    Locale currentLocale,
  ) {
    final isSelected = locale == currentLocale;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        context.read<Core>().settings.changeLocale(context, locale);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppTheme.primary.withValues(alpha: 0.08))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : AppTheme.primary)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isDark ? Colors.white : AppTheme.gray800,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: isDark ? Colors.white : AppTheme.primary,
                size: 20,
              ),
          ],
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
          child: Container(color: isDark ? AppTheme.gray950 : AppTheme.gray50),
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
                  (isDark ? Colors.white : AppTheme.primary).withValues(
                    alpha: 0.08,
                  ),
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
                  (isDark ? AppTheme.accentDark : AppTheme.accent).withValues(
                    alpha: 0.15,
                  ),
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

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
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
