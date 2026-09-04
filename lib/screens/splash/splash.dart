import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/auth/login.dart';
import 'package:vyaparsetu/screens/business/form.dart';
import 'package:vyaparsetu/screens/business/list.dart';
import 'package:vyaparsetu/screens/home/home.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/storage/hive/preferences.dart';
import 'package:vyaparsetu/screens/splash/forceUpdate.dart';

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
    final shouldProceed = await _checkAppVersion();
    if (!shouldProceed || !mounted) return;

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
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
      ),
    );
  }

  Future<bool> _checkAppVersion() async {
    final lastCheck = PreferencesBox.getLastVersionCheck();
    if (lastCheck != null) {
      final diff = DateTime.now().difference(lastCheck);
      if (diff < const Duration(days: 1)) {
        return true;
      }
    }

    try {
      final latestVersion = await Api.instance.appConfig.getLatestVersion();
      if (latestVersion != null) {
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

        if (_isUpdateRequired(currentVersion, latestVersion)) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              getPageRoute(const ForceUpdateScreen()),
            );
          }
          return false;
        }
      }
      await PreferencesBox.setLastVersionCheck(DateTime.now());
    } catch (_) {}
    return true;
  }

  bool _isUpdateRequired(String current, String latest) {
    try {
      final currentParts = current.split('+');
      final latestParts = latest.split('+');

      final currentVer = currentParts[0].split('.').map(int.parse).toList();
      final latestVer = latestParts[0].split('.').map(int.parse).toList();

      while (currentVer.length < 3) {
        currentVer.add(0);
      }
      while (latestVer.length < 3) {
        latestVer.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (latestVer[i] > currentVer[i]) return true;
        if (currentVer[i] > latestVer[i]) return false;
      }

      if (latestParts.length > 1 && currentParts.length > 1) {
        final currentBuild = int.tryParse(currentParts[1]) ?? 0;
        final latestBuild = int.tryParse(latestParts[1]) ?? 0;
        if (latestBuild > currentBuild) return true;
      }
    } catch (_) {}
    return false;
  }
}
