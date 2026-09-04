import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/partyLedger.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/core/Core.dart';

class TransactionScreen extends StatefulWidget {
  final String partyId;
  const TransactionScreen({super.key, required this.partyId});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  void _refresh() {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId != null) {
      context.read<Core>().party.fetchPartyLedger(businessId, widget.partyId);
    }
  }

  Color _typeColor(String type, bool isDark) {
    if (type.contains('sale')) return isDark ? AppTheme.accentDark : AppTheme.primary;
    if (type.contains('purchase')) return isDark ? AppTheme.secondaryDark : AppTheme.secondary;
    if (type.contains('payment')) return isDark ? AppTheme.successDark : AppTheme.success;
    return isDark ? AppTheme.gray400 : AppTheme.slate500;
  }

  IconData _typeIcon(String type) {
    if (type.contains('sale')) return Icons.receipt_long_rounded;
    if (type.contains('purchase')) return Icons.shopping_cart_outlined;
    if (type.contains('payment')) return Icons.account_balance_wallet_rounded;
    return Icons.article_outlined;
  }

  String _typeLabel(String type) {
    if (type.contains('sale')) return 'sale_label'.tr();
    if (type.contains('purchase')) return 'purchase_label'.tr();
    if (type.contains('payment')) return 'payment_label'.tr();
    return type;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final partyLedger = context.select<Core, PartyLedger?>(
      (c) => c.party.partyLedger,
    );
    final isLoading = context.select<Core, bool>(
      (c) => c.party.isLoadingPartyLedger,
    );
    final entries = (partyLedger?.ledger ?? <LedgerEntry>[])
        .where((e) => !e.type.contains('sale') && !e.type.contains('purchase'))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'transaction_history'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child:
            isLoading && entries.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : entries.isEmpty
                    ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.gray700.withValues(alpha: 0.3)
                                        : AppTheme.gray100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: isDark
                                        ? AppTheme.gray500
                                        : AppTheme.gray400,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'no_transactions_yet'.tr(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppTheme.gray500
                                        : AppTheme.gray400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'transactions_appear_hint'.tr(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppTheme.gray600
                                        : AppTheme.gray400,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                    : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildTransactionCard(
                                    isDark,
                                    entries[index],
                                    index,
                                  ),
                              childCount: entries.length,
                            ),
                          ),
                        ),
                      ],
                    ),
      ),
    );
  }


  Widget _buildTransactionCard(
    bool isDark,
    LedgerEntry entry,
    int index,
  ) {
    final color = _typeColor(entry.type, isDark);
    final icon = _typeIcon(entry.type);
    final label = _typeLabel(entry.type);

    return Padding(
      padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 20),
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
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark ? Colors.white : AppTheme.gray900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 11,
                                  color: isDark
                                      ? AppTheme.gray400
                                      : AppTheme.slate500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  Formatters.formatDate(entry.date),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppTheme.gray400
                                        : AppTheme.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        Formatters.formatCurrency(entry.totalAmount),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }
