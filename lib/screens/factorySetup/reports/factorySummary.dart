import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/factorySetup/factorySummary.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/core/Core.dart';

class FactorySummaryScreen extends StatefulWidget {
  final String factoryId;
  const FactorySummaryScreen({super.key, required this.factoryId});

  @override
  State<FactorySummaryScreen> createState() => _FactorySummaryScreenState();
}

class _FactorySummaryScreenState extends State<FactorySummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<Core>().factory.fetchFactorySummary(widget.factoryId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = context.select<Core, FactorySummary?>(
      (c) => c.factory.factorySummary,
    );
    final isLoading = context.select<Core, bool>(
      (c) => c.factory.isLoadingFactorySummary,
    );
    final error = context.select<Core, String?>(
      (c) => c.factory.factorySummaryError,
    );

    return Scaffold(
      body: Center(
        child: isLoading
            ? const LoadingIndicator()
            : error != null
                ? AppErrorWidget(errorMessage: error, onRetry: _loadData)
                : summary == null
                    ? const SizedBox.shrink()
                    : _buildSummary(isDark, summary),
      ),
    );
  }

  Widget _buildSummary(bool isDark, FactorySummary s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.gray700 : AppTheme.gray200,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _buildCol(
                    'factory.total_bricks'.tr(),
                    '${s.totalBricks}',
                    AppTheme.secondary,
                    isDark,
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                  ),
                  _buildCol(
                    'factory.total_amount'.tr(),
                    Formatters.formatCurrency(s.totalAmount),
                    AppTheme.primary,
                    isDark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.gray700 : AppTheme.gray200,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _buildCol(
                    'factory.total_given'.tr(),
                    Formatters.formatCurrency(s.totalMoneyGiven),
                    AppTheme.warning,
                    isDark,
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                  ),
                  _buildCol(
                    'factory.balance_due'.tr(),
                    Formatters.formatCurrency(s.balanceDue),
                    s.balanceDue > 0
                        ? AppTheme.success
                        : (s.balanceDue < 0 ? AppTheme.error : (isDark ? Colors.white : AppTheme.gray900)),
                    isDark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.gray700 : AppTheme.gray200,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      color: AppTheme.secondary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${s.workerCount} ${'factory.worker_count'.tr()}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.gray900,
                      ),
                    ),
                  ],
                ),
                if (s.workersSummary.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  ...s.workersSummary.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                w.name,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppTheme.gray900,
                                ),
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(w.balanceDue),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: w.balanceDue > 0
                                    ? AppTheme.success
                                    : (w.balanceDue < 0 ? AppTheme.error : (isDark ? Colors.white : AppTheme.gray900)),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCol(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
