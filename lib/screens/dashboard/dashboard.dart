import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/invoices/form.dart';
import 'package:vyaparsetu/screens/payments/form.dart';
import 'package:vyaparsetu/screens/expenses/form.dart';
import 'package:vyaparsetu/screens/items/list.dart';
import 'package:vyaparsetu/screens/reports/reportCenter.dart';
import 'package:vyaparsetu/screens/home/home.dart';
import 'package:vyaparsetu/screens/business/list.dart';
import 'package:vyaparsetu/types/dashboardSummary.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/types/user.dart';
import 'package:vyaparsetu/core/Core.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId != null) {
      context.read<Core>().dashboard.fetchSummary(businessId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final businessId = context.select<Core, String?>(
      (c) => c.business.selectedBusiness?.id,
    );
    final isLoadingSummary = context.select<Core, bool>(
      (c) => c.dashboard.isLoadingSummary,
    );
    final summary = context.select<Core, DashboardSummary?>(
      (c) => c.dashboard.summary,
    );
    final summaryError = context.select<Core, String?>(
      (c) => c.dashboard.summaryError,
    );
    final selectedBusiness = context.select<Core, Business?>(
      (c) => c.business.selectedBusiness,
    );
    final hasMultiple = context.select<Core, bool>(
      (c) => c.business.businesses.length > 1,
    );
    final user = context.select<Core, User?>((c) => c.auth.user);
    final userInitials =
        user?.name.isNotEmpty == true
            ? user!.name
                .split(' ')
                .map((e) => e[0])
                .take(2)
                .join()
                .toUpperCase()
            : 'U';

    if (isLoadingSummary && summary == null) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Loading dashboard summary...'),
      );
    }

    if (summaryError != null && summary == null) {
      return Scaffold(
        body: AppErrorWidget(errorMessage: summaryError, onRetry: _loadData),
      );
    }

    final s = summary;
    if (s == null) {
      return const Scaffold(
        body: Center(child: Text('No dashboard summary found')),
      );
    }

    // Set colors for background glows (Aurora Rose/Coral & Teal/Cyan)
    final glowColor1 =
        isDark
            ? AppTheme.rose.withValues(alpha: 0.16)
            : AppTheme.rose.withValues(alpha: 0.06);
    final glowColor2 =
        isDark
            ? AppTheme.accent.withValues(alpha: 0.14)
            : AppTheme.accent.withValues(alpha: 0.05);

    return Scaffold(
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [glowColor1, Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [glowColor2, Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
              child: const SizedBox.shrink(),
            ),
          ),

          // Main Scaffold Layout
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness:
                    isDark ? Brightness.dark : Brightness.light,
              ),
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppTheme.backgroundDark.withValues(alpha: 0.75)
                              : Colors.white.withValues(alpha: 0.8),
                      border: Border(
                        bottom: BorderSide(
                          color:
                              isDark
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
                onTap:
                    hasMultiple
                        ? () {
                          Navigator.of(context)
                              .push(getPageRoute(const BusinessListScreen()))
                              .then((_) {
                                if (mounted) _loadData();
                              });
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
                      final homeState =
                          context.findAncestorStateOfType<HomeScreenState>();
                      homeState?.setTab(3);
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          isDark
                              ? AppTheme.gray800
                              : AppTheme.primary.withValues(alpha: 0.08),
                      child: Text(
                        userInitials,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              color: isDark ? Colors.white : AppTheme.primary,
              onRefresh: () async {
                if (businessId != null) {
                  await context.read<Core>().dashboard.fetchSummary(businessId);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Low stock notification alert
                    if (s.lowStockItemsCount > 0)
                      _buildLowStockAlert(isDark, s.lowStockItemsCount),

                    _buildProfitHero(isDark, s),
                    const SizedBox(height: 20),

                    // Financial stats comparison panels
                    _buildWidescreenStats(isDark, s),
                    const SizedBox(height: 28),

                    // Quick Actions Section
                    _buildSectionHeader(
                      title: 'quick_actions'.tr(),
                      actionLabel: null,
                      onActionTap: null,
                    ),
                    const SizedBox(height: 14),
                    _buildQuickActionsDock(isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Low Stock Alert Component ---
  Widget _buildLowStockAlert(bool isDark, int count) {
    return _DashboardInteractiveScale(
      onTap: () {
        Navigator.of(context).push(
          getPageRoute(const ItemListScreen()),
        ).then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.warning.withValues(alpha: isDark ? 0.25 : 0.15),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.warning,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'low_stock_items_alert'.trWithDefault(
                  '$count items are running low on stock. Restock soon!',
                  args: [count.toString()],
                ),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.amber[200] : AppTheme.warning,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.amber[200] : AppTheme.warning,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // --- Profit Hero Banner ---
  Widget _buildProfitHero(bool isDark, DashboardSummary s) {
    final netProfit = s.totalSales.base - s.totalPurchases.base;
    final isProfit = netProfit >= 0;

    final primaryColor =
        isProfit ? AppTheme.success : AppTheme.rose;
    final secondaryColor =
        isProfit ? AppTheme.successDark : AppTheme.roseDark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [secondaryColor, primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Icon(
                isProfit ? Icons.auto_graph_rounded : Icons.trending_down,
                size: 80,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (isProfit ? 'PROFIT' : 'LOSS'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Formatters.formatCurrency(netProfit.abs()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'OVERALL HEALTH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Sales & Collection / Purchase Metrics Card ---
  Widget _buildWidescreenStats(bool isDark, DashboardSummary s) {
    final totalSales = s.totalSales.total;
    final totalReceived = s.received.total;
    final totalPending = s.totalReceivables.total;

    final collectionRatio =
        totalSales == 0 ? 0.0 : (totalReceived / totalSales);

    final statusColor =
        collectionRatio > 0.8
            ? const Color(0xFF16A34A)
            : (collectionRatio > 0.4
                ? const Color(0xFFD97706)
                : const Color(0xFFDC2626));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDark
                  ? AppTheme.gray700.withValues(alpha: 0.3)
                  : AppTheme.slate50,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SALES & COLLECTION SECTION
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SALES & COLLECTION',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(collectionRatio * 100).toStringAsFixed(0)}% Collected',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Sales Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color:
                          isDark
                              ? AppTheme.gray700.withValues(alpha: 0.3)
                              : AppTheme.gray100,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.1 : 0.03,
                        ),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL SALES',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.slate500,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0EA5E9,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_graph_rounded,
                              color: Color(0xFF0EA5E9),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Formatters.formatCurrency(totalSales),
                          style: GoogleFonts.outfit(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : AppTheme.primary,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPremiumValueChip(
                            label: 'Base',
                            value: s.totalSales.base,
                            color: Colors.grey.shade600,
                            isDark: isDark,
                          ),
                          _buildPremiumValueChip(
                            label: 'Tax',
                            value: s.totalSales.tax,
                            color: const Color(0xFF0EA5E9),
                            isDark: isDark,
                          ),
                          _buildPremiumValueChip(
                            label: 'Total',
                            value: totalSales,
                            color: const Color(0xFF0EA5E9),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Collected',
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? AppTheme.gray400
                                          : AppTheme.slate500,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${(collectionRatio * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: collectionRatio,
                              backgroundColor: AppTheme.slate50,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                statusColor,
                              ),
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Received & Outstanding sub-cards
                Row(
                  children: [
                    Expanded(
                      child: _buildGlassMetric(
                        isDark: isDark,
                        label: 'RECEIVED',
                        total: totalReceived,
                        base: s.received.base,
                        tax: s.received.tax,
                        color: const Color(0xFF16A34A),
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildGlassMetric(
                        isDark: isDark,
                        label: 'OUTSTANDING',
                        total: totalPending,
                        base: s.totalReceivables.base,
                        tax: s.totalReceivables.tax,
                        color: const Color(0xFFEA580C),
                        icon: Icons.hourglass_empty_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppTheme.gray700 : AppTheme.slate50,
          ),

          // PURCHASE METRICS SECTION
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PURCHASE METRICS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.gray500 : AppTheme.slate500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPurchaseMetricRow(
                  isDark: isDark,
                  items: [
                    _PurchaseMetricItem(
                      'Total Purchase',
                      s.totalPurchases.total,
                      Icons.shopping_cart_outlined,
                      const Color(0xFFF97316),
                    ),
                    _PurchaseMetricItem(
                      'Paid',
                      s.totalPaid.total,
                      Icons.payments_outlined,
                      const Color(0xFF16A34A),
                    ),
                    _PurchaseMetricItem(
                      'Payables',
                      s.totalPayables.total,
                      Icons.money_off_rounded,
                      const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper widgets ---

  Widget _buildGlassMetric({
    required bool isDark,
    required String label,
    required double total,
    required double base,
    required double tax,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDark
                  ? AppTheme.gray700.withValues(alpha: 0.3)
                  : AppTheme.slate50,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate500,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.formatCurrency(total),
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.primary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPremiumValueChip(
            label: 'Base',
            value: base,
            color: Colors.grey.shade600,
            isDark: isDark,
            compact: true,
          ),
          const SizedBox(height: 6),
          _buildPremiumValueChip(
            label: 'Tax',
            value: tax,
            color: color,
            isDark: isDark,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumValueChip({
    required String label,
    required double value,
    required Color color,
    bool isDark = false,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.08)
                : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : color.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          Text(
            Formatters.formatCurrency(value),
            style: TextStyle(
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseMetricRow({
    required bool isDark,
    required List<_PurchaseMetricItem> items,
  }) {
    return Column(
      children:
          items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark
                                    ? AppTheme.gray400
                                    : AppTheme.slate500,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Formatters.formatCurrency(item.amount),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark
                                      ? Colors.white
                                      : AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  // --- Quick Actions Hub Component ---
  Widget _buildQuickActionsDock(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildActionTile(
              isDark: isDark,
              icon: Icons.add_shopping_cart_rounded,
              label: 'new_sale'.tr(),
              color: AppTheme.success,
              onTap:
                  () => Navigator.of(context)
                      .push(getPageRoute(const InvoiceFormScreen.sale()))
                      .then((_) => _loadData()),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildActionTile(
              isDark: isDark,
              icon: Icons.shopping_bag_outlined,
              label: 'new_purchase'.tr(),
              color: AppTheme.error,
              onTap:
                  () => Navigator.of(context)
                      .push(getPageRoute(const InvoiceFormScreen.purchase()))
                      .then((_) => _loadData()),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionTile(
              isDark: isDark,
              icon: Icons.payments_rounded,
              label: 'payment_in'.tr(),
              color: AppTheme.success,
              onTap:
                  () => Navigator.of(context)
                      .push(getPageRoute(const PaymentFormScreen.paymentIn()))
                      .then((_) => _loadData()),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildActionTile(
              isDark: isDark,
              icon: Icons.payments_outlined,
              label: 'Payment Out',
              color: AppTheme.error,
              onTap:
                  () => Navigator.of(context)
                      .push(getPageRoute(const PaymentFormScreen.paymentOut()))
                      .then((_) => _loadData()),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionTile(
              isDark: isDark,
              icon: Icons.inventory_2_outlined,
              label: 'Items',
              color: AppTheme.info,
              onTap:
                  () => Navigator.of(context)
                      .push(getPageRoute(const ItemListScreen()))
                      .then((_) => _loadData()),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildActionTile(
              isDark: isDark,
              icon: Icons.money_off_csred_rounded,
              label: 'add_expense'.tr(),
              color: AppTheme.warning,
              onTap:
                  () => Navigator.of(context)
                      .push(getPageRoute(const ExpenseFormScreen()))
                      .then((_) => _loadData()),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionTile(
              isDark: isDark,
              icon: Icons.assessment_rounded,
              label: 'Reports',
              color: AppTheme.secondary,
              onTap:
                  () => Navigator.of(context)
                      .push(getPageRoute(const ReportCenterScreen())),
            )),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _DashboardInteractiveScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.gray300 : AppTheme.gray700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable Section Header ---
  Widget _buildSectionHeader({
    required String title,
    required String? actionLabel,
    required VoidCallback? onActionTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.gray900,
            letterSpacing: -0.2,
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _PurchaseMetricItem {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _PurchaseMetricItem(this.label, this.amount, this.icon, this.color);
}

// --- Dynamic Scale Motion Helper Widget ---
class _DashboardInteractiveScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _DashboardInteractiveScale({required this.child, this.onTap});

  @override
  State<_DashboardInteractiveScale> createState() =>
      _DashboardInteractiveScaleState();
}

class _DashboardInteractiveScaleState extends State<_DashboardInteractiveScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (widget.onTap != null) _controller.forward();
      },
      onPointerUp: (_) {
        if (widget.onTap != null) _controller.reverse();
      },
      onPointerCancel: (_) {
        if (widget.onTap != null) _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}

extension on String {
  String trWithDefault(String defaultValue, {List<String>? args}) {
    final translated = tr(this, args: args);
    return translated == this ? defaultValue : translated;
  }
}
