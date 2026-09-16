import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/screens/auth/login.dart';
import 'package:vyaparsetu/helpers/crashReporting.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/splash/splash.dart';
import 'package:vyaparsetu/storage/hive.dart';
import 'package:vyaparsetu/api/dio.dart';
import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/core/Core.dart';

void main() {
  // Everything runs inside the guarded zone so startup failures are reported
  // too, not just errors raised once the app is running.
  CrashReporting.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Hive.initFlutter();
    await openAllBoxes();
    await EasyLocalization.ensureInitialized();

    final dioInstance = await DioInstance.init(
      baseURL: AppConstants.apiBaseUrl,
    );
    Api.initialize(dioInstance.dio);

    final core = Core();
    core.settings.load();

    runApp(
      // English only for now; strings still go through translation keys so
      // more languages can be added later.
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: ChangeNotifierProvider.value(
          value: core,
          child: const VyaparSetuApp(),
        ),
      ),
    );
  });
}

class VyaparSetuApp extends StatefulWidget {
  const VyaparSetuApp({super.key});

  @override
  State<VyaparSetuApp> createState() => _VyaparSetuAppState();
}

class _VyaparSetuAppState extends State<VyaparSetuApp> {
  @override
  void initState() {
    super.initState();
    DioInstance.onSessionExpired = () {
      if (!mounted) return;
      context.read<Core>().auth.handleSessionExpired();
      // Clearing state rebuilds the screens that are open; navigating in the
      // same breath would run while Navigator is still busy with that frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          getPageRoute(const LoginScreen()),
          (route) => false,
        );
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<Core, ThemeMode>(
      (c) => c.settings.themeMode,
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const SplashScreen(),
    );
  }
}
