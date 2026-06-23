import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFFAFBF6),
      body: Center(
        child: SizedBox(
          width: 140,
          height: 140,
          child: Image.asset(
            isDark
                ? 'assets/images/app_logo_foreground.png'
                : 'assets/images/app_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
