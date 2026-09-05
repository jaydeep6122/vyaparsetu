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
import 'package:vyaparsetu/screens/business/form.dart';
import 'package:vyaparsetu/types/dashboardSummary.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/core/Core.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

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
      context.read<Core>().invoice.fetchInvoices(businessId);
    }
  }

  Widget _buildTopStatusRow(bool isDark, int lowStockCount) {
    if (lowStockCount == 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(
            context,
          ).push(getPageRoute(const ItemListScreen())).then((_) => _loadData());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Warning: $lowStockCount items are running low on stock",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFEF4444),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarginSemicircle(bool isDark, DashboardSummary s) {
    final netProfit = s.totalSales.total - s.totalPurchases.total;
    final isProfit = netProfit >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? AppTheme.gray700.withValues(alpha: 0.3)
                  : AppTheme.gray200.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.04 : 0.01),
            blurRadius: 12,
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
              Text(
                'net_balance'.tr().toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isProfit
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (isProfit ? 'profit' : 'loss').tr().toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color:
                        isProfit
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Formatters.formatCurrency(netProfit),
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : AppTheme.gray100,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'total_sales'.tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(s.totalSales.total),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.gray900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : AppTheme.gray100,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'total_purchases'.tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(s.totalPurchases.total),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.gray900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlidingTabs(bool isDark) {
    return Container(
      width: double.infinity,
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.gray100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Background capsule slider
          LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 2;
              return AnimatedAlign(
                alignment:
                    _selectedTab == 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Tab texts and triggers
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedTab = 0;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'sales_and_collection'.tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color:
                            _selectedTab == 0
                                ? (isDark ? Colors.white : AppTheme.primary)
                                : AppTheme.gray500,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedTab = 1;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'purchase_metrics_title'.tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color:
                            _selectedTab == 1
                                ? (isDark ? Colors.white : AppTheme.primary)
                                : AppTheme.gray500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    final invoices = context.select<Core, List<Invoice>>(
      (c) => c.invoice.invoices,
    );
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
      return Scaffold(body: Center(child: Text('no_dashboard_summary'.tr())));
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.background,
      body: RefreshIndicator(
        color: isDark ? Colors.white : AppTheme.primary,
        onRefresh: () async {
          if (businessId != null) {
            await Future.wait([
              context.read<Core>().dashboard.fetchSummary(
                businessId,
                forceRefresh: true,
              ),
              context.read<Core>().invoice.fetchInvoices(
                businessId,
                forceRefresh: true,
              ),
            ]);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact top status warning pill (if any items low)
              _buildTopStatusRow(isDark, s.lowStockItemsCount),

              // Net Margin Semicircle Visualizer Card
              _buildMarginSemicircle(isDark, s),
              const SizedBox(height: 16),

              // Sliding Tab switcher
              _buildSlidingTabs(isDark),
              const SizedBox(height: 14),

              // Animated Card Switcher (Sales Overview / Purchase Overview)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child:
                    _selectedTab == 0
                        ? _buildSalesHubCard(isDark, s, invoices)
                        : _buildPurchasesHubCard(isDark, s),
              ),
              const SizedBox(height: 20),

              // Quick Actions Section Header
              _buildSectionHeader(
                title: 'quick_actions'.tr(),
                actionLabel: null,
                onActionTap: null,
              ),
              const SizedBox(height: 12),
              _buildQuickActionsDock(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesHubCard(
    bool isDark,
    DashboardSummary s,
    List<Invoice> invoices,
  ) {
    final totalSales = s.totalSales.total;
    final totalReceived = s.received.total;
    final totalPending = s.totalReceivables.total;

    final miscSales = invoices
        .where(
          (inv) =>
              inv.invoiceType == InvoiceType.sale &&
              inv.billType == BillType.normal,
        )
        .fold<double>(0.0, (sum, inv) => sum + inv.totalAmount);

    final gstBase = (s.totalSales.base - miscSales).clamp(0.0, double.infinity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? AppTheme.gray700.withValues(alpha: 0.3)
                  : AppTheme.gray200.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF10B981),
                size: 16,
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'total_sales'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.gray300 : AppTheme.gray600,
                ),
              ),
              Text(
                Formatters.formatCurrency(totalSales),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            isDark,
            'base_amount'.tr(),
            Formatters.formatCurrency(gstBase),
            isDark ? AppTheme.gray400 : AppTheme.gray700,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            isDark,
            'tax_amount'.tr(),
            Formatters.formatCurrency(s.totalSales.tax),
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            isDark,
            'misc_sale'.tr(),
            Formatters.formatCurrency(miscSales),
            const Color(0xFF7C3AED), // purple/accent
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : AppTheme.gray100,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            isDark,
            'payments_received'.tr(),
            Formatters.formatCurrency(totalReceived),
            const Color(0xFF10B981),
            showBullet: true,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            isDark,
            'outstanding'.tr(),
            Formatters.formatCurrency(totalPending),
            const Color(0xFFEF4444),
            showBullet: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasesHubCard(bool isDark, DashboardSummary s) {
    final totalPurchases = s.totalPurchases.total;
    final totalPaid = s.totalPaid.total;
    final totalPayables = s.totalPayables.total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? AppTheme.gray700.withValues(alpha: 0.3)
                  : AppTheme.gray200.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                color: Color(0xFF3B82F6),
                size: 16,
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'total_purchases'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.gray300 : AppTheme.gray600,
                ),
              ),
              Text(
                Formatters.formatCurrency(totalPurchases),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            isDark,
            'base_amount'.tr(),
            Formatters.formatCurrency(s.totalPurchases.base),
            isDark ? AppTheme.gray400 : AppTheme.gray700,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            isDark,
            'tax_amount'.tr(),
            Formatters.formatCurrency(s.totalPurchases.tax),
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : AppTheme.gray100,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            isDark,
            'paid'.tr(),
            Formatters.formatCurrency(totalPaid),
            const Color(0xFF10B981),
            showBullet: true,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            isDark,
            'payables'.tr(),
            Formatters.formatCurrency(totalPayables),
            const Color(0xFFEF4444),
            showBullet: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    bool isDark,
    String label,
    String value,
    Color statusColor, {
    bool showBullet = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (showBullet) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.primary,
          ),
        ),
      ],
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
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Select Invoice Type',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
                      builder:
                          (ctx) => AlertDialog(
                            title: Text('gst_number_required'.tr()),
                            content: Text('gst_number_required_msg'.tr()),
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
                  Navigator.of(this.context)
                      .push(
                        getPageRoute(
                          const InvoiceFormScreen.sale(billType: BillType.gst),
                        ),
                      )
                      .then((_) => _loadData());
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
                  Navigator.of(this.context)
                      .push(
                        getPageRoute(
                          const InvoiceFormScreen.sale(
                            billType: BillType.normal,
                          ),
                        ),
                      )
                      .then((_) => _loadData());
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
                color:
                    isDark
                        ? AppTheme.primaryDark.withValues(alpha: 0.2)
                        : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppTheme.gray500 : AppTheme.gray400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsDock(bool isDark) {
    final iconColor = isDark ? Colors.white70 : AppTheme.primary;
    final iconBgColor = (isDark ? Colors.white : AppTheme.primary).withValues(
      alpha: 0.08,
    );

    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _buildSecondaryActionTile(
              isDark: isDark,
              icon: Icons.add_shopping_cart_rounded,
              label: 'new_sale'.tr(),
              iconColor: iconColor,
              iconBgColor: iconBgColor,
              onTap: _onNewSale,
            ),
            _buildSecondaryActionTile(
              isDark: isDark,
              icon: Icons.shopping_bag_outlined,
              label: 'new_purchase'.tr(),
              iconColor: iconColor,
              iconBgColor: iconBgColor,
              onTap:
                  () => Navigator.of(context)
                      .push(getPageRoute(const InvoiceFormScreen.purchase()))
                      .then((_) => _loadData()),
            ),
            _buildSecondaryActionTile(
              isDark: isDark,
              icon: Icons.payments_rounded,
              label: 'payment_in'.tr(),
              iconColor: iconColor,
              iconBgColor: iconBgColor,
              onTap:
                  () => Navigator.of(context)
                      .push(getPageRoute(const PaymentFormScreen.paymentIn()))
                      .then((_) => _loadData()),
            ),
            _buildSecondaryActionTile(
              isDark: isDark,
              icon: Icons.payments_outlined,
              label: 'payment_out'.tr(),
              iconColor: iconColor,
              iconBgColor: iconBgColor,
              onTap:
                  () => Navigator.of(context)
                      .push(getPageRoute(const PaymentFormScreen.paymentOut()))
                      .then((_) => _loadData()),
            ),
            _buildSecondaryActionTile(
              isDark: isDark,
              icon: Icons.money_off_csred_rounded,
              label: 'add_expense'.tr(),
              iconColor: iconColor,
              iconBgColor: iconBgColor,
              onTap:
                  () => Navigator.of(context)
                      .push(getPageRoute(const ExpenseFormScreen()))
                      .then((_) => _loadData()),
            ),
            _buildSecondaryActionTile(
              isDark: isDark,
              icon: Icons.inventory_2_outlined,
              label: 'items_appbar'.tr(),
              iconColor: iconColor,
              iconBgColor: iconBgColor,
              onTap:
                  () => Navigator.of(context)
                      .push(getPageRoute(const ItemListScreen()))
                      .then((_) => _loadData()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildWideActionTile(
          isDark: isDark,
          icon: Icons.assessment_rounded,
          label: 'reports'.tr(),
          subtitle: 'view_ledger_report'.tr(),
          color: isDark ? Colors.white70 : AppTheme.primary,
          onTap:
              () => Navigator.of(
                context,
              ).push(getPageRoute(const ReportCenterScreen())),
        ),
      ],
    );
  }

  Widget _buildSecondaryActionTile({
    required bool isDark,
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return _DashboardInteractiveScale(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark
                    ? AppTheme.gray700.withValues(alpha: 0.3)
                    : AppTheme.gray200.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isDark
                    ? AppTheme.gray700.withValues(alpha: 0.3)
                    : AppTheme.gray200.withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.06 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
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
                      fontSize: 15,
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : AppTheme.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                size: 10,
              ),
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
