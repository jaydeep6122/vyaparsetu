import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/factorySetup/worker.dart';
import 'package:vyaparsetu/types/factorySetup/transactionLog.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/screens/factorySetup/workers/form.dart';
import 'package:vyaparsetu/screens/factorySetup/workers/molderPdfPreview.dart';
import 'package:vyaparsetu/core/Core.dart';

class WorkerDetailScreen extends StatefulWidget {
  final String factoryId;
  final String workerId;
  const WorkerDetailScreen({
    super.key,
    required this.factoryId,
    required this.workerId,
  });

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  String _activeTab = 'wages'; // 'wages' or 'payments'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<Core>().factory.fetchWorker(widget.factoryId, widget.workerId);
    context.read<Core>().factory.fetchTransactions(
      widget.factoryId,
      workerId: widget.workerId,
    );
  }

  void _deleteWorker() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: 'factory.delete_worker_title'.tr(),
        content: 'factory.delete_worker_confirm'.tr(),
        confirmText: 'delete'.tr(),
        isDestructive: true,
        icon: Icons.delete_outline_rounded,
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await context.read<Core>().factory.deleteWorker(
        widget.factoryId,
        widget.workerId,
      );
      if (success && context.mounted) {
        Navigator.of(context).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showSuccessToast('factory.worker_deleted'.tr());
          }
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final worker = context.select<Core, Worker?>(
      (c) => c.factory.selectedWorker,
    );
    final isLoading = context.select<Core, bool>(
      (c) => c.factory.isLoadingWorker,
    );
    final transactions = context.select<Core, List<TransactionLog>>(
      (c) => c.factory.transactions,
    );
    final isLoadingTransactions = context.select<Core, bool>(
      (c) => c.factory.isLoadingTransactions,
    );

    if (isLoading && worker == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: LoadingIndicator()),
      );
    }

    final w = worker;
    if (w == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('factory.worker_not_found'.tr())),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async => _loadData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.primary,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.2),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                    ),
                    Positioned(
                      right: -50,
                      top: -50,
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor:
                            AppTheme.secondary.withValues(alpha: 0.1),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: Text(
                            w.name.isNotEmpty
                                ? w.name.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          w.name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          w.workerType.displayName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        if (w.ratePer1000 != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${'factory.rate_per_1000'.tr()}: ${Formatters.formatCurrency(w.ratePer1000!)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      getPageRoute(
                        MolderPdfPreviewScreen(
                          worker: w,
                          factoryId: widget.factoryId,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      getPageRoute(
                        WorkerFormScreen(
                          factoryId: widget.factoryId,
                          existingWorker: w,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) _loadData();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                  ),
                  onPressed: _deleteWorker,
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(isDark, w),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Text(
                          'factory.transactions'.tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.gray900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTabSelector(),
                    const SizedBox(height: 16),
                    _buildTransactionsSection(isDark, transactions, isLoadingTransactions, w),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isDark, Worker w) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildRedesignedCard(
                isDark: isDark,
                icon: Icons.layers_rounded,
                label: 'factory.total_bricks_caps'.tr(),
                value: '${w.totalBricks}',
                color: const Color(0xFF06B6D4), // Cyan
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRedesignedCard(
                isDark: isDark,
                icon: Icons.wallet_rounded,
                label: 'factory.total_wages_caps'.tr(),
                value: Formatters.formatCurrency(w.totalAmount),
                color: AppTheme.primary, // Indigo/Primary
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRedesignedCard(
                isDark: isDark,
                icon: Icons.paid_rounded,
                label: 'factory.money_taken_caps'.tr(),
                value: Formatters.formatCurrency(w.totalMoneyGiven),
                color: const Color(0xFFF97316), // Orange
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRedesignedCard(
                isDark: isDark,
                icon: Icons.pending_actions_rounded,
                label: 'factory.pending_caps'.tr(),
                value: Formatters.formatCurrency(w.balanceDue),
                color: w.balanceDue > 0
                    ? AppTheme.success
                    : (w.balanceDue < 0 ? AppTheme.error : AppTheme.gray500),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRedesignedCard({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppTheme.gray700.withValues(alpha: 0.3)
              : AppTheme.gray200.withValues(alpha: 0.5),
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
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray800 : AppTheme.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'wages'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 'wages'
                      ? (isDark ? AppTheme.primaryDark : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _activeTab == 'wages' ? AppTheme.shadowSm : null,
                ),
                child: Text(
                  'factory.wages'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _activeTab == 'wages'
                        ? (isDark ? Colors.white : AppTheme.primary)
                        : (isDark ? AppTheme.gray400 : AppTheme.gray600),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'payments'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 'payments'
                      ? (isDark ? AppTheme.primaryDark : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _activeTab == 'payments' ? AppTheme.shadowSm : null,
                ),
                child: Text(
                  'factory.payments'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _activeTab == 'payments'
                        ? (isDark ? Colors.white : AppTheme.primary)
                        : (isDark ? AppTheme.gray400 : AppTheme.gray600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(
    bool isDark,
    List<TransactionLog> transactions,
    bool isLoadingTransactions,
    Worker worker,
  ) {
    final filtered = transactions.where((t) {
      final isWages = t.transactionType != TransactionType.money_given;
      if (_activeTab == 'wages' && !isWages) return false;
      if (_activeTab == 'payments' && isWages) return false;
      return true;
    }).toList();

    if (isLoadingTransactions && filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: LoadingIndicator(),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          ),
        ),
        child: Center(
          child: Text(
            _activeTab == 'wages'
                ? 'factory.no_wages_found'.tr()
                : 'factory.no_payments_found'.tr(),
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isDark ? AppTheme.gray500 : AppTheme.gray400,
            ),
          ),
        ),
      );
    }

    return Column(
      children: filtered.map((t) {
        String qtyString = '';
        double displayAmount = t.amount;

        if (t.quantity != null) {
          if (t.transactionType == TransactionType.truck_dist) {
            final numWorkers = t.truckWorkerIds.isNotEmpty ? t.truckWorkerIds.length : 1;
            final share = t.quantity! / numWorkers;
            qtyString = share.round().toString();
            if (displayAmount == 0.0 && worker.ratePer1000 != null) {
              displayAmount = (share / 1000.0) * worker.ratePer1000!;
            }
          } else {
            qtyString = t.quantity.toString();
          }
        }

        final formattedAmount = NumberFormat.currency(
          locale: 'en_IN',
          symbol: '₹',
          decimalDigits: 0,
        ).format(displayAmount.round());

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppTheme.gray700 : AppTheme.gray200,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.transactionType.displayName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppTheme.gray900,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            Formatters.formatDate(t.date),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.gray500,
                            ),
                          ),
                          if (qtyString.isNotEmpty) ...[
                            Text(
                              '  •  ',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppTheme.gray500,
                              ),
                            ),
                            Text(
                              '$qtyString ${'factory.bricks_lowercase'.tr()}',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.gray400 : AppTheme.gray700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  t.transactionType == TransactionType.money_given
                      ? '-$formattedAmount'
                      : formattedAmount,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: t.transactionType == TransactionType.money_given
                        ? AppTheme.error
                        : AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
