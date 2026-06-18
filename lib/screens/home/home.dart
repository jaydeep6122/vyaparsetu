import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vyaparsetu/screens/dashboard/dashboard.dart';
import 'package:vyaparsetu/screens/invoices/list.dart';
import 'package:vyaparsetu/screens/parties/list.dart';
import 'package:vyaparsetu/screens/settings/settings.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/business/list.dart';
import 'package:vyaparsetu/components/premiumNavBar.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/types/user.dart';

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

  static const _destinations = [
    PremiumNavDestination(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    PremiumNavDestination(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Invoices',
    ),
    PremiumNavDestination(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_alt_rounded,
      label: 'Parties',
    ),
    PremiumNavDestination(
      icon: Icons.more_horiz_rounded,
      activeIcon: Icons.more_horiz_rounded,
      label: 'More',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _visited = List.generate(4, (index) => index == _currentIndex);
  }

  final List<Widget> _tabs = [
    const DashboardScreen(),
    const InvoiceListScreen(),
    const PartyListScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedBusiness = context.select<Core, Business?>((c) => c.business.selectedBusiness);
    final hasMultiple = context.select<Core, bool>((c) => c.business.businesses.length > 1);
    final user = context.select<Core, User?>((c) => c.auth.user);
    final userInitials = user?.name.isNotEmpty == true
        ? user!.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _currentIndex == 0
          ? null
          : AppBar(
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
                        Navigator.of(context).push(
                          getPageRoute(const BusinessListScreen()),
                        );
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
            ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 96),
            child: IndexedStack(
              index: _currentIndex,
              children: List.generate(_tabs.length, (index) {
                return _visited[index] ? _tabs[index] : const SizedBox.shrink();
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
                setState(() {
                  _currentIndex = index;
                  _visited[index] = true;
                });
              },
              destinations: _destinations,
            ),
          ),
        ],
      ),
    );
  }
}
