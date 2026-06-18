import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/auth/login.dart';
import 'package:vyaparsetu/screens/business/form.dart';
import 'package:vyaparsetu/screens/business/list.dart';
import 'package:vyaparsetu/screens/home/home.dart';
import 'package:vyaparsetu/core/Core.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<Core>().auth;
    final businessProvider = context.read<Core>().business;

    bool isLoggedIn = false;
    try {
      isLoggedIn = await authProvider.tryAutoLogin();
    } catch (_) {}

    if (!mounted) return;

    if (isLoggedIn) {
      await businessProvider.fetchBusinesses();
      if (!mounted) return;

      final count = businessProvider.businesses.length;
      if (count == 0) {
        Navigator.of(context).pushReplacement(
          getPageRoute(const BusinessFormScreen()),
        );
      } else if (count == 1) {
        await businessProvider.selectBusiness(businessProvider.businesses.first);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          getPageRoute(const HomeScreen()),
        );
      } else {
        if (businessProvider.selectedBusiness != null) {
          Navigator.of(context).pushReplacement(
            getPageRoute(const HomeScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            getPageRoute(const BusinessListScreen()),
          );
        }
      }
    } else {
      Navigator.of(context).pushReplacement(
        getPageRoute(const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.gray950, AppTheme.gray900],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.gray100, Colors.white],
                ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'VyaparSetu',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white : AppTheme.gray800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bridge to Smart Business Invoicing',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: (isDark ? Colors.white : AppTheme.gray800).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
