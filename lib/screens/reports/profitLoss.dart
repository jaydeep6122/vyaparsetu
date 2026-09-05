import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/helpers/datePicker.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/types/profitLoss.dart';
import 'package:vyaparsetu/core/Core.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

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
      final from = _fromDate != null
          ? DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day, 0, 0, 0)
          : null;
      final to = _toDate != null
          ? DateTime(
              _toDate!.year,
              _toDate!.month,
              _toDate!.day,
              23,
              59,
              59,
              999,
            )
          : null;
      context.read<Core>().dashboard.fetchProfitLoss(
        businessId,
        fromDate: from?.toUtc().toIso8601String(),
        toDate: to?.toUtc().toIso8601String(),
      );
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await pickAppDateRange(
      context: context,
      initialRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadData();
    }
  }

  void _clearFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoadingProfitLoss = context.select<Core, bool>(
      (c) => c.dashboard.isLoadingProfitLoss,
    );
    final profitLoss = context.select<Core, ProfitLoss?>(
      (c) => c.dashboard.profitLoss,
    );
    final profitLossError = context.select<Core, String?>(
      (c) => c.dashboard.profitLossError,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'profit_loss'.tr(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.gray900,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: Icon(
                      Icons.date_range,
                      size: 18,
                      color: isDark ? Colors.white : AppTheme.primary,
                    ),
                    label: Text(
                      _fromDate != null && _toDate != null
                          ? '${Formatters.formatDate(_fromDate!)} - ${Formatters.formatDate(_toDate!)}'
                          : 'select_date_range'.tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      side: BorderSide(
                        color: isDark ? AppTheme.gray700 : AppTheme.gray300,
                      ),
                    ),
                  ),
                ),
                if (_fromDate != null || _toDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: isDark ? AppTheme.gray400 : AppTheme.gray400,
                    ),
                    onPressed: _clearFilter,
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: _buildProfitLossBody(
              isDark,
              theme,
              isLoadingProfitLoss,
              profitLoss,
              profitLossError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLossBody(
    bool isDark,
    ThemeData theme,
    bool isLoadingProfitLoss,
    ProfitLoss? profitLoss,
    String? profitLossError,
  ) {
    if (isLoadingProfitLoss && profitLoss == null) {
      return LoadingIndicator(message: 'generating_pl'.tr());
    }

    if (profitLossError != null) {
      return AppErrorWidget(errorMessage: profitLossError, onRetry: _loadData);
    }

    final pl = profitLoss;
    if (pl == null) {
      return Center(
        child: Text(
          'no_report_generated'.tr(),
          style: GoogleFonts.outfit(
            color: isDark ? AppTheme.gray400 : AppTheme.gray500,
          ),
        ),
      );
    }

    final isProfit = pl.netProfit >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      child: Column(
        children: [
          // Net Profit Hero
          _buildProfitHero(isDark, pl, isProfit),
          const SizedBox(height: 24),

          // Section: Revenue / Sales
          _buildSectionHeader(isDark, 'revenue_sales'.tr()),
          const SizedBox(height: 12),
          _buildPlCard(isDark, [
            _plRow('gross_sales'.tr(), pl.grossSales, isDark, prefix: '+'),
            _plRow('sales_returns'.tr(), pl.salesReturns, isDark, prefix: '-'),
            const _PlDivider(),
            _plRow(
              'net_sales_revenue'.tr(),
              pl.netRevenue,
              isDark,
              isSubtotal: true,
            ),
          ]),
          const SizedBox(height: 16),

          // Section: Cost of Goods
          _buildSectionHeader(isDark, 'cost_of_goods'.tr()),
          const SizedBox(height: 12),
          _buildPlCard(isDark, [
            _plRow(
              'gross_purchases'.tr(),
              pl.grossPurchases,
              isDark,
              prefix: '+',
            ),
            _plRow(
              'purchase_returns'.tr(),
              pl.purchaseReturns,
              isDark,
              prefix: '-',
            ),
            const _PlDivider(),
            _plRow(
              'net_purchase_cost'.tr(),
              pl.netPurchases,
              isDark,
              isSubtotal: true,
            ),
          ]),
          const SizedBox(height: 16),

          // Section: Operating Expenses
          _buildSectionHeader(isDark, 'operating_expenses'.tr()),
          const SizedBox(height: 12),
          _buildPlCard(isDark, [
            _plRow(
              'total_expenses'.tr(),
              pl.operatingExpenses,
              isDark,
              prefix: '-',
              isSubtotal: true,
            ),
          ]),
        ],
      ),
    );
  }

  // --- Net Profit Hero ---
  Widget _buildProfitHero(bool isDark, ProfitLoss pl, bool isProfit) {
    final primaryColor = isProfit ? AppTheme.success : AppTheme.rose;
    final secondaryColor = isProfit ? AppTheme.successDark : AppTheme.roseDark;

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
              right: -20,
              child: Icon(
                isProfit
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 100,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isProfit ? 'net_profit'.tr() : 'net_loss'.tr(),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.formatCurrency(pl.netProfit.abs()),
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'for_selected_period'.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Section Header ---
  Widget _buildSectionHeader(bool isDark, String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.gray400 : AppTheme.gray500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? AppTheme.gray800 : AppTheme.gray200,
          ),
        ),
      ],
    );
  }

  // --- P&L Card ---
  Widget _buildPlCard(bool isDark, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppTheme.gray800 : AppTheme.slate50,
          width: 1.5,
        ),
      ),
      child: Column(children: children),
    );
  }

  // --- P&L Row ---
  Widget _plRow(
    String label,
    double amount,
    bool isDark, {
    String prefix = '',
    bool isSubtotal = false,
  }) {
    final sign = prefix == '-' ? '-' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$prefix $label',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: isSubtotal ? FontWeight.w700 : FontWeight.w500,
              color: isSubtotal
                  ? (isDark ? Colors.white : AppTheme.gray900)
                  : (isDark ? AppTheme.gray400 : AppTheme.gray600),
            ),
          ),
          Text(
            '$sign${Formatters.formatCurrency(amount)}',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: isSubtotal ? FontWeight.w700 : FontWeight.w600,
              color: isSubtotal
                  ? (isDark ? Colors.white : AppTheme.gray900)
                  : (isDark ? Colors.white : AppTheme.gray900),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlDivider extends StatelessWidget {
  const _PlDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        height: 1,
        color: isDark
            ? AppTheme.gray700.withValues(alpha: 0.5)
            : AppTheme.gray200,
      ),
    );
  }
}
