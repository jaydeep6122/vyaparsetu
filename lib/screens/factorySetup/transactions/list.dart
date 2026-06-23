import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/factorySetup/transactionLog.dart';
import 'package:vyaparsetu/components/searchBar.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/core/Core.dart';

class TransactionListScreen extends StatefulWidget {
  final String factoryId;
  final String? workerId;
  const TransactionListScreen({
    super.key,
    required this.factoryId,
    this.workerId,
  });

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String _searchQuery = '';
  String _activeTab = 'wages'; // 'wages' or 'payments'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<Core>().factory.fetchTransactions(
      widget.factoryId,
      workerId: widget.workerId,
    );
  }

  Widget _buildTabSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = context.select<Core, bool>(
      (c) => c.factory.isLoadingTransactions,
    );
    final transactions = context.select<Core, List<TransactionLog>>(
      (c) => c.factory.transactions,
    );
    final error = context.select<Core, String?>(
      (c) => c.factory.transactionsError,
    );

    return Scaffold(
      appBar: widget.workerId != null
          ? AppBar(
              title: Text(
                'factory.transactions'.tr(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Column(
        children: [
          if (widget.workerId != null) _buildTabSelector(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: AppSearchBar(
              hintText: 'factory.search_transactions'.tr(),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          if (isLoading && transactions.isNotEmpty)
            const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              color: isDark ? Colors.white : AppTheme.primary,
              onRefresh: () async => _loadData(),
              child: _buildBody(isDark, isLoading, transactions, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    bool isDark, bool isLoading, List<TransactionLog> transactions, String? error,
  ) {
    if (isLoading && transactions.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: LoadingIndicator(
            message: 'factory.loading_transactions'.tr(), isShimmer: true,
          ),
        ),
      );
    }

    if (error != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: AppErrorWidget(errorMessage: error, onRetry: _loadData),
        ),
      );
    }

    final filtered = transactions.where((t) {
      if (widget.workerId != null) {
        final isWages = t.transactionType != TransactionType.money_given;
        if (_activeTab == 'wages' && !isWages) return false;
        if (_activeTab == 'payments' && isWages) return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return t.transactionType.displayName.toLowerCase().contains(q) ||
          (t.notes?.toLowerCase().contains(q) ?? false);
    }).toList();

    if (filtered.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: widget.workerId != null
                ? (_activeTab == 'wages'
                    ? 'factory.no_wages_found'.tr()
                    : 'factory.no_payments_found'.tr())
                : 'factory.no_transactions'.tr(),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final t = filtered[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isDark ? AppTheme.gray800 : AppTheme.slate50,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    _getTypeIcon(t.transactionType),
                    color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.transactionType.displayName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        Formatters.formatDate(t.date),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (t.quantity != null && t.quantity! > 0) ...[
                  Text(
                    '${t.quantity} ${'factory.bricks'.tr()}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppTheme.gray700,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      t.transactionType == TransactionType.money_given
                          ? '-${Formatters.formatCurrency(t.amount)}'
                          : Formatters.formatCurrency(t.amount),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: t.transactionType == TransactionType.money_given
                            ? AppTheme.error
                            : AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.handoff:
        return Icons.compare_arrows_rounded;
      case TransactionType.direct:
        return Icons.edit_note_rounded;
      case TransactionType.truck_dist:
        return Icons.local_shipping_rounded;
      case TransactionType.money_given:
        return Icons.payments_rounded;
    }
  }
}
