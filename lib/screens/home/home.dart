import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/screens/dashboard/dashboard.dart';
import 'package:vyaparsetu/screens/invoices/list.dart';
import 'package:vyaparsetu/screens/parties/list.dart';
import 'package:vyaparsetu/screens/settings/settings.dart';
// import 'package:vyaparsetu/screens/factorySetup/workers/list.dart';
import 'package:vyaparsetu/screens/factorySetup/factory/list.dart';
// import 'package:vyaparsetu/screens/factorySetup/dashboard/dashboard.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/business/list.dart';
import 'package:vyaparsetu/components/premiumNavBar.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/modules/settingsModule.dart';
import 'package:vyaparsetu/types/factorySetup/factory.dart';
import 'package:vyaparsetu/screens/factorySetup/factory/form.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/types/user.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late List<bool> _visited;

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
      _visited[index] = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _visited = List.generate(5, (index) => index == _currentIndex);
  }

  void _switchToBusinessMode() {
    context.read<Core>().settings.switchAppMode();
    _resetToDashboard();
  }

  Future<void> _enterFactoryMode() async {
    final factory = context.read<Core>().factory;

    if (factory.factories.isNotEmpty) {
      // Instant switch!
      final factories = factory.factories;
      final hasSelection = factory.selectedFactory != null;

      if (factories.length == 1) {
        await factory.selectFactory(factories.first);
        if (!mounted) return;
        context.read<Core>().settings.switchAppMode();
        _resetToDashboard();
      } else if (hasSelection) {
        context.read<Core>().settings.switchAppMode();
        _resetToDashboard();
      } else {
        await Navigator.of(
          context,
        ).push(getPageRoute(const FactoryListScreen(selectionMode: true)));
        if (mounted && factory.selectedFactory != null) {
          context.read<Core>().settings.switchAppMode();
          _resetToDashboard();
        }
      }

      return;
    }

    // Fallback loading overlay dialog for first-time fetch (when cache is empty)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: LoadingIndicator(message: 'entering_factory_mode'.tr()),
        ),
      ),
    );


    try {
      await factory.fetchDashboardData();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pop(); // Dismiss loading overlay

    final factories = factory.factories;
    final hasSelection = factory.selectedFactory != null;

    if (factories.isEmpty) {
      context.read<Core>().settings.switchAppMode();
      _resetToDashboard();
    } else if (factories.length == 1) {
      await factory.selectFactory(factories.first);
      if (!mounted) return;
      context.read<Core>().settings.switchAppMode();
      _resetToDashboard();
    } else if (hasSelection) {
      context.read<Core>().settings.switchAppMode();
      _resetToDashboard();
    } else {
      await Navigator.of(
        context,
      ).push(getPageRoute(const FactoryListScreen(selectionMode: true)));
      if (mounted && factory.selectedFactory != null) {
        context.read<Core>().settings.switchAppMode();
        _resetToDashboard();
      }
    }
  }

  void _resetToDashboard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentIndex = 0;
          _visited = List.generate(5, (index) => index == 0);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedBusiness = context.select<Core, Business?>(
      (c) => c.business.selectedBusiness,
    );
    final hasMultiple = context.select<Core, bool>(
      (c) => c.business.businesses.length > 1,
    );
    final user = context.select<Core, User?>((c) => c.auth.user);
    final appMode = context.select<Core, AppMode>((c) => c.settings.appMode);
    final selectedFactoryName = context.select<Core, String?>(
      (c) => c.factory.selectedFactory?.name,
    );
    final factoryCount = context.select<Core, int>(
      (c) => c.factory.factories.length,
    );
    final userInitials = user?.name.isNotEmpty == true
        ? user!.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    final isBusinessMode = appMode == AppMode.business;
    final destinations = isBusinessMode
        ? _businessDestinations
        : _factoryDestinations;
    final tabs = isBusinessMode ? _businessTabs : _factoryTabs;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(
        isDark,
        selectedBusiness,
        hasMultiple,
        userInitials,
        isBusinessMode,
        selectedFactoryName,
        factoryCount,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 96),
            child: IndexedStack(
              key: ValueKey(appMode),
              index: _currentIndex,
              children: List.generate(tabs.length, (index) {
                return _visited[index] ? tabs[index] : const SizedBox.shrink();
              }),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PremiumNavBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                final label = destinations[index].label;
                if (isBusinessMode) {
                  if (label == 'factory'.tr()) {
                    _enterFactoryMode();
                  } else {
                    setState(() {
                      _currentIndex = index;
                      _visited[index] = true;
                    });
                  }
                } else {
                  if (label == 'business'.tr()) {
                    _switchToBusinessMode();
                  } else {
                    setState(() {
                      _currentIndex = index;
                      _visited[index] = true;
                    });
                  }
                }
              },
              destinations: destinations,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(
    bool isDark,
    Business? selectedBusiness,
    bool hasMultiple,
    String userInitials,
    bool isBusinessMode,
    String? selectedFactoryName,
    int factoryCount,
  ) {
    if (!isBusinessMode) {
      return _buildFactoryAppBar(isDark, selectedFactoryName, factoryCount);
    }

    if (_currentIndex == 0) return null;

    return _buildBusinessAppBar(
      isDark,
      selectedBusiness,
      hasMultiple,
      userInitials,
    );
  }

  PreferredSizeWidget _buildBusinessAppBar(
    bool isDark,
    Business? selectedBusiness,
    bool hasMultiple,
    String userInitials,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceDark.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.85),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppTheme.gray800.withValues(alpha: 0.4)
                      : AppTheme.gray200.withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
      title: GestureDetector(
        onTap: hasMultiple
            ? () {
                Navigator.of(
                  context,
                ).push(getPageRoute(const BusinessListScreen()));
              }
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                selectedBusiness?.name ?? 'VyaparSetu',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.white : AppTheme.gray900,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasMultiple) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.white : AppTheme.gray800,
                size: 20,
              ),
            ],
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = 3;
                _visited[3] = true;
              });
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: isDark
                  ? AppTheme.gray800
                  : AppTheme.primary.withValues(alpha: 0.08),
              child: Text(
                userInitials,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildFactoryAppBar(
    bool isDark,
    String? selectedFactoryName,
    int factoryCount,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceDark.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.85),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppTheme.gray800.withValues(alpha: 0.4)
                      : AppTheme.gray200.withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
      title: GestureDetector(
        onTap: () {
          Navigator.of(
            context,
          ).push(getPageRoute(const FactoryListScreen(selectionMode: true)));
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.factory_rounded,
              size: 20,
              color: isDark ? AppTheme.gray300 : AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                selectedFactoryName ?? 'select_factory'.tr(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.white : AppTheme.gray900,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white : AppTheme.gray800,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  List<PremiumNavDestination> get _businessDestinations => [
    PremiumNavDestination(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'dashboard'.tr(),
    ),
    PremiumNavDestination(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'invoices'.tr(),
    ),
    PremiumNavDestination(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_alt_rounded,
      label: 'parties'.tr(),
    ),
    PremiumNavDestination(
      icon: Icons.more_horiz_rounded,
      activeIcon: Icons.more_horiz_rounded,
      label: 'more'.tr(),
    ),
    // PremiumNavDestination(
    //   icon: Icons.factory_outlined,
    //   activeIcon: Icons.factory_rounded,
    //   label: 'Factory',
    // ),
  ];

  List<PremiumNavDestination> get _factoryDestinations => [
    // PremiumNavDestination(
    //   icon: Icons.dashboard_outlined,
    //   activeIcon: Icons.dashboard_rounded,
    //   label: 'Dashboard',
    // ),
    // PremiumNavDestination(
    //   icon: Icons.people_outline_rounded,
    //   activeIcon: Icons.people_alt_rounded,
    //   label: 'Workers',
    // ),
    PremiumNavDestination(
      icon: Icons.business_center_outlined,
      activeIcon: Icons.business_center_rounded,
      label: 'business'.tr(),
    ),
  ];

  List<Widget> get _businessTabs => const [
    DashboardScreen(),
    InvoiceListScreen(),
    PartyListScreen(),
    SettingsScreen(),
    // SizedBox.shrink(),
  ];

  List<Widget> get _factoryTabs => const [
    // FactoryDashboardScreen(),
    // _FactoryWorkersTab(),
    SizedBox.shrink(),
  ];
}

// class _FactoryWorkersTab extends StatelessWidget {
//   const _FactoryWorkersTab();
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final factoryId = context.select<Core, String?>(
//       (c) => c.factory.selectedFactory?.id,
//     );
//
//     if (factoryId == null) {
//       return _buildEmptyState(
//         context, isDark,
//         icon: Icons.people_outline_rounded,
//         message: 'Please select a factory to view workers',
//         actionLabel: 'Select Factory',
//         onActionPressed: () => showFactorySelectionBottomSheet(context),
//       );
//     }
//
//     return WorkerListScreen(factoryId: factoryId);
//   }
// }

void showFactorySelectionBottomSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    builder: (context) {
      final factories = context.select<Core, List<Factory>>(
        (c) => c.factory.factories,
      );
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'select_factory'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
            ),
            const Divider(indent: 0, endIndent: 0),
            if (factories.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'no_factories_found'.tr(),
                      style: GoogleFonts.outfit(color: AppTheme.gray500),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(
                          context,
                        ).push(getPageRoute(const FactoryFormScreen()));
                      },
                      child: Text('create_first_factory'.tr()),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: factories.length,
                  itemBuilder: (context, index) {
                    final f = factories[index];
                    return ListTile(
                      leading: const Icon(Icons.factory_rounded),
                      title: Text(
                        f.name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      subtitle: f.location != null && f.location!.isNotEmpty
                          ? Text(f.location!)
                          : null,
                      onTap: () {
                        context.read<Core>().factory.selectFactory(f);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}

// Widget _buildEmptyState(
//   BuildContext context,
//   bool isDark, {
//   required IconData icon,
//   required String message,
//   String? actionLabel,
//   VoidCallback? onActionPressed,
// }) {
//   return Center(
//     child: Padding(
//       padding: const EdgeInsets.all(32),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               icon,
//               size: 40,
//               color: isDark ? AppTheme.gray300 : AppTheme.primary,
//             ),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             message,
//             textAlign: TextAlign.center,
//             style: GoogleFonts.outfit(
//               fontSize: 15,
//               color: isDark ? AppTheme.gray400 : AppTheme.gray500,
//               height: 1.5,
//             ),
//           ),
//           const SizedBox(height: 24),
//           FilledButton.icon(
//             onPressed: onActionPressed ?? () {
//               final homeState = context.findAncestorStateOfType<HomeScreenState>();
//               homeState?.setTab(0);
//             },
//             icon: Icon(onActionPressed != null ? Icons.factory_rounded : Icons.dashboard_rounded, size: 18),
//             label: Text(actionLabel ?? 'Go to Dashboard'),
//             style: FilledButton.styleFrom(
//               backgroundColor: AppTheme.primary,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(AppTheme.radiusSm),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
