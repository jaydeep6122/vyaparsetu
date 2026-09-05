import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/screens/dashboard/dashboard.dart';
import 'package:vyaparsetu/storage/hive.dart';
import 'package:vyaparsetu/storage/hive/cache.dart';

/// Renders the dashboard with a seeded summary so the layout can be checked
/// without a login.
///
/// The summary is seeded through CacheBox because DashboardModule reads the
/// cached summary for the selected business in its constructor - no network
/// and no auth involved.
///
/// These assert that the screen lays out without throwing, across theme,
/// width and text scale. That is what caught the real bug here: an
/// IntrinsicHeight around the To Receive / To Pay row clipped the amounts.
///
/// They deliberately do NOT assert rendered strings. google_fonts cannot fetch
/// Outfit in the test sandbox and reports that failure asynchronously, after
/// the triggering test has finished, so it lands on whichever test runs next -
/// which makes assertion-heavy tests here order-dependent and flaky. Content
/// was verified on-device instead.
void main() {
  const businessId = 'b1';

  final summaryJson = <String, dynamic>{
    'total_sales': {'base': 694915.0, 'tax': 125085.0, 'total': 820000.0},
    'total_purchases': {'base': 423729.0, 'tax': 76271.0, 'total': 500000.0},
    'total_receivables': {'base': 0.0, 'tax': 0.0, 'total': 120000.0},
    'total_payables': {'base': 0.0, 'tax': 0.0, 'total': 45000.0},
    'received': {'base': 0.0, 'tax': 0.0, 'total': 700000.0},
    'total_paid': {'base': 0.0, 'tax': 0.0, 'total': 455000.0},
    'low_stock_items_count': 5,
    'low_stock_items': [
      {
        'id': 'i1',
        'name': 'Steel Rod 12mm',
        'current_stock': 4,
        'low_stock_warning': 20,
        'measuring_unit': 'pcs',
      },
      {
        'id': 'i2',
        'name': 'Cement Bag OPC 53 Grade Premium',
        'current_stock': 2.5,
        'low_stock_warning': 10,
        'measuring_unit': 'bag',
      },
      {
        'id': 'i3',
        'name': 'Paint Bucket',
        'current_stock': 0,
        'low_stock_warning': 5,
        'measuring_unit': 'ltr',
      },
    ],
    'cash_book': {
      'cash': 80000.0,
      'bank': 140000.0,
      'upi': 25000.0,
      'total_money': 245000.0,
    },
  };

  late Directory hiveDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // google_fonts would otherwise try to fetch Outfit over the network, which
    // the test sandbox blocks. Goldens render in the fallback face; they are
    // here to check layout, not typography.
    GoogleFonts.config.allowRuntimeFetching = false;

    // easy_localization persists the chosen locale via shared_preferences,
    // which has no implementation under flutter_test.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async => call.method == 'getAll' ? <String, Object>{} : null,
    );

    hiveDir = await Directory.systemTemp.createTemp('vyaparsetu_hive');
    Hive.init(hiveDir.path);
    await openAllBoxes();
    await EasyLocalization.ensureInitialized();

    await CacheBox.setSelectedBusinessId(businessId);
    await CacheBox.setCachedBusinessSummaries({businessId: summaryJson});
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir.existsSync()) hiveDir.deleteSync(recursive: true);
  });

  Widget harness({required ThemeMode mode}) {
    final core = Core();
    core.dashboard.loadCachedSummary(businessId);

    return EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('gu')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: Builder(
        builder: (context) => ChangeNotifierProvider.value(
          value: core,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: const DashboardScreen(),
          ),
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    // EasyLocalization loads its assets asynchronously on first frame.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('renders in light mode without overflow', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1500 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness(mode: ThemeMode.light));
    await settle(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in dark mode without overflow', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1500 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness(mode: ThemeMode.dark));
    await settle(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders at a narrow width without overflow', (tester) async {
    // 320dp is the narrowest phone the app realistically sees.
    tester.view.physicalSize = const Size(320 * 3, 1500 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness(mode: ThemeMode.light));
    await settle(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders at 1.6x text scale without overflow', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 2200 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: harness(mode: ThemeMode.light),
      ),
    );
    await settle(tester);

    expect(tester.takeException(), isNull);
  });
}
