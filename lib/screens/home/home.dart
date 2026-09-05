import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    _visited = List.generate(_tabs.length, (index) => index == _currentIndex);
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
    final userInitials = user?.name.isNotEmpty == true
        ? user!.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    final tabs = _tabs;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _buildBusinessAppBar(
        isDark,
        selectedBusiness,
        hasMultiple,
        userInitials,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 96),
            child: IndexedStack(
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
                  ? AppTheme.backgroundDark.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.85),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppTheme.gray800.withValues(alpha: 0.3)
                      : AppTheme.gray200.withValues(alpha: 0.5),
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
                HapticFeedback.lightImpact();
                Navigator.of(
                  context,
                ).push(getPageRoute(const BusinessListScreen()));
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isDark
                  ? AppTheme.gray700.withValues(alpha: 0.3)
                  : AppTheme.gray200,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_rounded,
                color: isDark ? AppTheme.primaryDark : AppTheme.primary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  selectedBusiness?.name ?? 'VyaparSetu',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppTheme.gray900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasMultiple) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _currentIndex = 3;
              _visited[3] = true;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: _buildLogoWidget(
              selectedBusiness?.logoUrl,
              16,
              userInitials,
              isDark,
            ),
          ),
        ),
      ],
    );
  }

  List<PremiumNavDestination> get _destinations => [
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
  ];

  List<Widget> get _tabs => const [
    DashboardScreen(),
    InvoiceListScreen(),
    PartyListScreen(),
    SettingsScreen(),
  ];

  Widget _buildLogoWidget(
    String? logoUrl,
    double radius,
    String userInitials,
    bool isDark,
  ) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      if (logoUrl.startsWith('data:image')) {
        try {
          final base64Str = logoUrl.split(',')[1];
          return CircleAvatar(
            radius: radius,
            backgroundColor: isDark
                ? AppTheme.gray800
                : AppTheme.primary.withValues(alpha: 0.08),
            child: ClipOval(
              child: Image.memory(
                base64Decode(base64Str),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                    _buildFallbackAvatar(radius, userInitials, isDark),
              ),
            ),
          );
        } catch (_) {}
      } else {
        return CircleAvatar(
          radius: radius,
          backgroundColor: isDark
              ? AppTheme.gray800
              : AppTheme.primary.withValues(alpha: 0.08),
          child: ClipOval(
            child: Image.network(
              logoUrl,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) =>
                  _buildFallbackAvatar(radius, userInitials, isDark),
            ),
          ),
        );
      }
    }
    return _buildFallbackAvatar(radius, userInitials, isDark);
  }

  Widget _buildFallbackAvatar(double radius, String initials, bool isDark) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: isDark
          ? AppTheme.gray800
          : AppTheme.primary.withValues(alpha: 0.08),
      child: Text(
        initials,
        style: GoogleFonts.outfit(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : AppTheme.primary,
        ),
      ),
    );
  }
}
