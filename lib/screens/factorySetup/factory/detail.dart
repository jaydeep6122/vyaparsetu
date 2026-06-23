import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/factorySetup/factory.dart';
import 'package:vyaparsetu/types/factorySetup/worker.dart';
import 'package:vyaparsetu/types/factorySetup/transactionLog.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/screens/factorySetup/factory/form.dart';
import 'package:vyaparsetu/screens/factorySetup/workers/list.dart';
import 'package:vyaparsetu/screens/factorySetup/workers/detail.dart';
import 'package:vyaparsetu/screens/factorySetup/workers/form.dart';
import 'package:vyaparsetu/screens/factorySetup/reports/factorySummary.dart';
import 'package:vyaparsetu/core/Core.dart';

class FactoryDetailScreen extends StatefulWidget {
  final String factoryId;
  const FactoryDetailScreen({super.key, required this.factoryId});

  @override
  State<FactoryDetailScreen> createState() => _FactoryDetailScreenState();
}

class _FactoryDetailScreenState extends State<FactoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<Core>().factory.fetchFactory(widget.factoryId);
    context.read<Core>().factory.fetchWorkers(widget.factoryId);
    context.read<Core>().factory.fetchTransactions(widget.factoryId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final factory = context.select<Core, Factory?>(
      (c) => c.factory.selectedFactory,
    );
    final isLoading = context.select<Core, bool>(
      (c) => c.factory.isLoadingFactory,
    );
    final workers = context.select<Core, List<Worker>>(
      (c) => c.factory.workers,
    );
    final isLoadingWorkers = context.select<Core, bool>(
      (c) => c.factory.isLoadingWorkers,
    );
    final transactions = context.select<Core, List<TransactionLog>>(
      (c) => c.factory.transactions,
    );

    if (isLoading && factory == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: LoadingIndicator()),
      );
    }

    final f = factory;
    if (f == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('factory.factory_not_found'.tr())),
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
                          child: Icon(
                            Icons.factory_outlined,
                            color: AppTheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          f.name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (f.location != null && f.location!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            f.location!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
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
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      getPageRoute(FactoryFormScreen(existingFactory: f)),
                    ).then((_) {
                      if (mounted) _loadData();
                    });
                  },
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow(isDark, f.workerCount),
                    const SizedBox(height: 20),
                    _buildQuickActions(isDark),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'factory.workers'.tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.gray900,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              getPageRoute(
                                WorkerListScreen(factoryId: widget.factoryId),
                              ),
                            ).then((_) {
                              if (mounted) _loadData();
                            });
                          },
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: Text('factory.view_all'.tr()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildWorkersPreview(isDark, workers, isLoadingWorkers),
                    const SizedBox(height: 24),

                    Text(
                      'factory.transactions'.tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionsPreview(
                      isDark, transactions, isLoadingWorkers,
                    ),
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

  Widget _buildSummaryRow(bool isDark, int workerCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('factory.worker_count'.tr(), '$workerCount', Icons.people_outlined, isDark),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.secondary, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.gray900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: AppTheme.gray500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.person_add_alt_1_rounded,
            label: 'factory.add_worker'.tr(),
            onTap: () {
              Navigator.of(context).push(
                getPageRoute(WorkerFormScreen(factoryId: widget.factoryId)),
              ).then((_) {
                if (mounted) _loadData();
              });
            },
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: Icons.summarize_rounded,
            label: 'factory.summary'.tr(),
            onTap: () {
              Navigator.of(context).push(
                getPageRoute(
                  FactorySummaryScreen(factoryId: widget.factoryId),
                ),
              );
            },
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkersPreview(
    bool isDark, List<Worker> workers, bool loading,
  ) {
    if (loading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (workers.isEmpty) {
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
            'factory.no_workers'.tr(),
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isDark ? AppTheme.gray500 : AppTheme.gray400,
            ),
          ),
        ),
      );
    }

    return Column(
      children: workers.take(3).map((w) {
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
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  getPageRoute(
                    WorkerDetailScreen(
                      factoryId: widget.factoryId,
                      workerId: w.id,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      w.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppTheme.gray900,
                      ),
                    ),
                  ),
                  Text(
                    '${w.workerType.displayName}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionsPreview(
    bool isDark, List<TransactionLog> transactions, bool loading,
  ) {
    if (loading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (transactions.isEmpty) {
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
            'factory.no_transactions'.tr(),
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isDark ? AppTheme.gray500 : AppTheme.gray400,
            ),
          ),
        ),
      );
    }

    return Column(
      children: transactions.take(3).map((t) {
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
                  child: Text(
                    t.transactionType.displayName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppTheme.gray900,
                    ),
                  ),
                ),
                Text(
                  Formatters.formatCurrency(t.amount),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primary,
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
