import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/factorySetup/workerSummary.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/core/Core.dart';

class WorkerSummaryScreen extends StatefulWidget {
  final String factoryId;
  final String workerId;
  final String workerName;
  const WorkerSummaryScreen({
    super.key,
    required this.factoryId,
    required this.workerId,
    required this.workerName,
  });

  @override
  State<WorkerSummaryScreen> createState() => _WorkerSummaryScreenState();
}

class _WorkerSummaryScreenState extends State<WorkerSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<Core>().factory.fetchWorkerSummary(
      widget.factoryId, widget.workerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = context.select<Core, WorkerSummary?>(
      (c) => c.factory.workerSummary,
    );
    final isLoading = context.select<Core, bool>(
      (c) => c.factory.isLoadingWorkerSummary,
    );
    final error = context.select<Core, String?>(
      (c) => c.factory.workerSummaryError,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workerName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async => _loadData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingIndicator(),
              )
            else if (error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppErrorWidget(errorMessage: error, onRetry: _loadData),
              )
            else ...[
              if (summary != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Container(
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
                              '${summary.totalBricks}',
                              AppTheme.secondary,
                              isDark,
                            ),
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: isDark
                                  ? AppTheme.gray700
                                  : AppTheme.gray200,
                            ),
                            _buildCol(
                              'factory.total_amount'.tr(),
                              Formatters.formatCurrency(summary.totalAmount),
                              AppTheme.primary,
                              isDark,
                            ),
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: isDark
                                  ? AppTheme.gray700
                                  : AppTheme.gray200,
                            ),
                            _buildCol(
                              'factory.balance_due'.tr(),
                              Formatters.formatCurrency(summary.balanceDue),
                              summary.balanceDue > 0
                                  ? AppTheme.success
                                  : (summary.balanceDue < 0 ? AppTheme.error : (isDark ? Colors.white : AppTheme.gray900)),
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Text(
                      'factory.payments'.tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.gray900,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (summary.moneyTransactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'factory.no_payments_found'.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppTheme.gray500,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = summary.moneyTransactions[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.cardDark : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.gray700
                                      : AppTheme.gray200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          Formatters.formatDate(item.date),
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.gray900,
                                          ),
                                        ),
                                        if (item.notes != null &&
                                            item.notes!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.notes!,
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: AppTheme.gray500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(item.amount),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: summary.moneyTransactions.length,
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCol(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
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
