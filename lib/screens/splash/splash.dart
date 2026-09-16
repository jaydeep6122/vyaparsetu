import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/auth/login.dart';
import 'package:vyaparsetu/screens/auth/sessionRouter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final auth = context.read<Core>().auth;

    var signedIn = false;
    try {
      signedIn = await auth.tryAutoLogin();
    } catch (_) {}
    if (!mounted) return;

    if (signedIn) {
      await openAfterSignIn(context);
    } else {
      Navigator.of(context).pushReplacement(getPageRoute(const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              child: Image.asset(
                context.isDark
                    ? 'assets/images/app_logo_foreground.png'
                    : 'assets/images/app_logo.png',
                width: 112,
                height: 112,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppTheme.space3xl),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
