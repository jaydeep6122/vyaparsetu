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
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/invoices/form.dart';
import 'package:vyaparsetu/screens/payments/form.dart';
import 'package:vyaparsetu/screens/expenses/form.dart';
import 'package:vyaparsetu/screens/items/list.dart';
import 'package:vyaparsetu/screens/reports/reportCenter.dart';
import 'package:vyaparsetu/screens/home/home.dart';
import 'package:vyaparsetu/screens/business/list.dart';
import 'package:vyaparsetu/screens/business/form.dart';
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
      return Scaffold(
        body: LoadingIndicator(message: 'loading_dashboard'.tr()),
      );
    }

    if (summaryError != null && summary == null) {
      return Scaffold(
        body: AppErrorWidget(errorMessage: summaryError, onRetry: _loadData),
      );
    }

    final s = summary;
    if (s == null) {
      return Scaffold(
        body: Center(child: Text('no_dashboard_summary'.tr())),
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
                  await context.read<Core>().dashboard.fetchSummary(businessId, forceRefresh: true);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Low stock notification alert banner
                    if (s.lowStockItemsCount > 0)
                      _buildLowStockAlert(isDark, s.lowStockItemsCount),

                    // Financial Hero Card
                    _buildProfitHero(isDark, s),
                    const SizedBox(height: 24),

                    // Sales Overview Card
                    _buildSalesHubCard(isDark, s),
                    const SizedBox(height: 20),

                    // Purchase Overview Card
                    _buildPurchasesHubCard(isDark, s),
                    const SizedBox(height: 28),

                    // Quick Actions Section
                    _buildSectionHeader(
                      title: 'quick_actions'.tr(),
                      actionLabel: null,
                      onActionTap: null,
                    ),
                    const SizedBox(height: 16),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.warning.withValues(alpha: isDark ? 0.25 : 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.warning.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'low_stock_alert'.tr(),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amber[200] : AppTheme.warning,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'low_stock_items_alert'.tr(
                      args: [count.toString()],
                    ),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.gray300 : AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.amber[200] : AppTheme.warning,
              size: 22,
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

    final primaryColor = isProfit ? AppTheme.success : AppTheme.rose;
    final secondaryColor = isProfit ? AppTheme.successDark : AppTheme.roseDark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [secondaryColor, primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Icon(
                isProfit ? Icons.auto_graph_rounded : Icons.trending_down_rounded,
                size: 110,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (isProfit ? 'profit' : 'loss').tr().toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Formatters.formatCurrency(netProfit.abs()),
                          style: GoogleFonts.outfit(
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
                    child: Text(
                      'overall_health'.tr(),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
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

  Widget _buildCompactTextChip(String label, double value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.slate50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "$label${Formatters.formatCurrency(value)}",
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isDark ? AppTheme.gray300 : AppTheme.gray600,
        ),
      ),
    );
  }

  Widget _buildMetricColumn({
    required String label,
    required double value,
    required double base,
    required double tax,
    required Color color,
    required IconData icon,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: isPrimary ? 16 : 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: isPrimary ? 12 : 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Formatters.formatCurrency(value),
              style: GoogleFonts.outfit(
                fontSize: isPrimary ? 28 : 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${'base_amount'.tr()}: ${Formatters.formatCurrency(base)}",
            style: GoogleFonts.outfit(
              fontSize: isPrimary ? 12 : 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.gray400 : AppTheme.slate500,
            ),
          ),
          Text(
            "${'tax_amount'.tr()}: ${Formatters.formatCurrency(tax)}",
            style: GoogleFonts.outfit(
              fontSize: isPrimary ? 12 : 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.gray400 : AppTheme.slate500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Sales & Collection Card ---
  Widget _buildSalesHubCard(bool isDark, DashboardSummary s) {
    final totalSales = s.totalSales.total;
    final totalReceived = s.received.total;
    final totalPending = s.totalReceivables.total;

    final collectionRatio = totalSales == 0 ? 0.0 : (totalReceived / totalSales);

    final statusColor = collectionRatio > 0.8
        ? const Color(0xFF16A34A)
        : (collectionRatio > 0.4
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
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
          // Header: Title and Collection Ratio indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.analytics_outlined, color: isDark ? Colors.white70 : AppTheme.primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'sales_and_collection'.tr().toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              _RadialCollectionGauge(
                progress: collectionRatio,
                color: statusColor,
                backgroundColor: isDark ? AppTheme.gray800 : AppTheme.slate50,
                size: 44,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Primary Metric: Total Sales (laid out like Paid/Received sub-metrics)
          _buildMetricColumn(
            label: 'total_sales'.tr(),
            value: totalSales,
            base: s.totalSales.base,
            tax: s.totalSales.tax,
            color: isDark ? Colors.white70 : AppTheme.primary,
            icon: Icons.auto_graph_rounded,
            isDark: isDark,
            isPrimary: true,
          ),
          const SizedBox(height: 20),

          Divider(height: 1, color: isDark ? AppTheme.gray700 : AppTheme.gray100),
          const SizedBox(height: 20),

          // Bottom row: Collected vs Pending columns
          Row(
            children: [
              Expanded(
                child: _buildMetricColumn(
                  label: 'payments_received'.tr(),
                  value: totalReceived,
                  base: s.received.base,
                  tax: s.received.tax,
                  color: const Color(0xFF16A34A),
                  icon: Icons.check_circle_rounded,
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 80,
                color: isDark ? AppTheme.gray700 : AppTheme.gray100,
              ),
              Expanded(
                child: _buildMetricColumn(
                  label: 'outstanding'.tr(),
                  value: totalPending,
                  base: s.totalReceivables.base,
                  tax: s.totalReceivables.tax,
                  color: const Color(0xFFEA580C),
                  icon: Icons.pending_actions_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Purchase Metrics Card ---
  Widget _buildPurchasesHubCard(bool isDark, DashboardSummary s) {
    final totalPurchases = s.totalPurchases.total;
    final totalPaid = s.totalPaid.total;
    final totalPayables = s.totalPayables.total;

    final payRatio = totalPurchases == 0 ? 0.0 : (totalPaid / totalPurchases);
    final statusColor = const Color(0xFFEA580C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
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
          // Header: Title and Paid Ratio indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shopping_cart_outlined, color: isDark ? Colors.white70 : AppTheme.primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'purchase_metrics_title'.tr().toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              _RadialCollectionGauge(
                progress: payRatio,
                color: statusColor,
                backgroundColor: isDark ? AppTheme.gray800 : AppTheme.slate50,
                size: 44,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Primary Metric: Total Purchases (laid out like Paid/Received sub-metrics)
          _buildMetricColumn(
            label: 'total_purchases'.tr(),
            value: totalPurchases,
            base: s.totalPurchases.base,
            tax: s.totalPurchases.tax,
            color: isDark ? Colors.white70 : AppTheme.primary,
            icon: Icons.shopping_bag_rounded,
            isDark: isDark,
            isPrimary: true,
          ),
          const SizedBox(height: 20),

          Divider(height: 1, color: isDark ? AppTheme.gray700 : AppTheme.gray100),
          const SizedBox(height: 20),

          // Bottom row: Paid vs Payables columns
          Row(
            children: [
              Expanded(
                child: _buildMetricColumn(
                  label: 'paid'.tr(),
                  value: totalPaid,
                  base: s.totalPaid.base,
                  tax: s.totalPaid.tax,
                  color: const Color(0xFF16A34A),
                  icon: Icons.check_circle_rounded,
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 80,
                color: isDark ? AppTheme.gray700 : AppTheme.gray100,
              ),
              Expanded(
                child: _buildMetricColumn(
                  label: 'payables'.tr(),
                  value: totalPayables,
                  base: s.totalPayables.base,
                  tax: s.totalPayables.tax,
                  color: const Color(0xFFDC2626),
                  icon: Icons.pending_actions_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onNewSale() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Select Invoice Type',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 20,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'choose_invoice_type'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                ),
              ),
              const SizedBox(height: 24),
              _billTypeOption(
                icon: Icons.receipt_long_rounded,
                title: 'GST Invoice',
                subtitle: 'gst_invoice_subtitle'.tr(),
                isDark: isDark,
                onTap: () {
                  final business =
                      context.read<Core>().business.selectedBusiness;
                  final hasGstin =
                      business?.gstin != null && business!.gstin!.isNotEmpty;
                  if (!hasGstin) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('gst_number_required'.tr()),
                        content: Text(
                          'gst_number_required_msg'.tr(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text('cancel'.tr()),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).pop();
                              Navigator.of(this.context).push(
                                getPageRoute(const BusinessFormScreen()),
                              );
                            },
                            child: Text('go_to_settings'.tr()),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  Navigator.of(this.context).push(
                    getPageRoute(const InvoiceFormScreen.sale(billType: BillType.gst)),
                  ).then((_) => _loadData());
                },
              ),
              const SizedBox(height: 12),
              _billTypeOption(
                icon: Icons.receipt_rounded,
                title: 'normal_invoice'.tr(),
                subtitle: 'normal_invoice_subtitle'.tr(),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(this.context).push(
                    getPageRoute(const InvoiceFormScreen.sale(billType: BillType.normal)),
                  ).then((_) => _loadData());
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _billTypeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.gray800 : AppTheme.gray50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.primaryDark.withValues(alpha: 0.2) : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isDark ? Colors.white : AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 16,
                      color: isDark ? Colors.white : AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                    style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? AppTheme.gray500 : AppTheme.gray400),
          ],
        ),
      ),
    );
  }

  // --- Quick Actions Hub Component ---
  Widget _buildQuickActionsDock(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid for Secondary Actions (6 actions in total, 3 rows of 2 columns)
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _buildSecondaryActionTile(
              isDark: isDark,
              icon: Icons.add_shopping_cart_rounded,
              label: 'new_sale'.tr(),
              color: const Color(0xFF10B981),
              onTap: _onNewSale,
            ),
            _buildSecondaryActionTile(
              isDark: isDark,
              icon: Icons.shopping_bag_outlined,
              label: 'new_purchase'.tr(),
              color: const Color(0xFFEF4444),
              onTap: () => Navigator.of(context)
                  .push(getPageRoute(const InvoiceFormScreen.purchase()))
                  .then((_) => _loadData()),
            ),
            _buildSecondaryActionTile(
              isDark: isDark,
              icon: Icons.payments_rounded,
              label: 'payment_in'.tr(),
              color: const Color(0xFF10B981),
              onTap: () => Navigator.of(context)
                  .push(getPageRoute(const PaymentFormScreen.paymentIn()))
                  .then((_) => _loadData()),
            ),
            _buildSecondaryActionTile(
              isDark: isDark,
              icon: Icons.payments_outlined,
              label: 'payment_out'.tr(),
              color: const Color(0xFFEF4444),
              onTap: () => Navigator.of(context)
                  .push(getPageRoute(const PaymentFormScreen.paymentOut()))
                  .then((_) => _loadData()),
            ),
            _buildSecondaryActionTile(
              isDark: isDark,
              icon: Icons.inventory_2_outlined,
              label: 'items_appbar'.tr(),
              color: const Color(0xFF3B82F6),
              onTap: () => Navigator.of(context)
                  .push(getPageRoute(const ItemListScreen()))
                  .then((_) => _loadData()),
            ),
            _buildSecondaryActionTile(
              isDark: isDark,
              icon: Icons.money_off_csred_rounded,
              label: 'add_expense'.tr(),
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.of(context)
                  .push(getPageRoute(const ExpenseFormScreen()))
                  .then((_) => _loadData()),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Wide Report Action Card at the bottom
        _buildWideActionTile(
          isDark: isDark,
          icon: Icons.assessment_rounded,
          label: 'reports'.tr(),
          subtitle: 'view_ledger_report'.tr(),
          color: const Color(0xFF8B5CF6),
          onTap: () => Navigator.of(context).push(getPageRoute(const ReportCenterScreen())),
        ),
      ],
    );
  }

  Widget _buildSecondaryActionTile({
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _DashboardInteractiveScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? AppTheme.gray700.withValues(alpha: 0.3)
                : AppTheme.gray200.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.04 : 0.01),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.gray200 : AppTheme.gray800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppTheme.gray500 : AppTheme.gray400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideActionTile({
    required bool isDark,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _DashboardInteractiveScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppTheme.gray700.withValues(alpha: 0.3)
                : AppTheme.gray200.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? AppTheme.gray500 : AppTheme.gray400,
              size: 14,
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

class _RadialCollectionGauge extends StatelessWidget {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double size;

  const _RadialCollectionGauge({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final strokeWidth = size * 0.08;
    final fontSize = size * 0.22;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size - 4,
            height: size - 4,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              backgroundColor: backgroundColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

