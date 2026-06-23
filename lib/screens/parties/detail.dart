import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/types/partyLedger.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/types/partyQuantitySummary.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/parties/form.dart';
import 'package:vyaparsetu/screens/reports/partyLedger.dart';
import 'package:vyaparsetu/screens/payments/form.dart';
import 'package:vyaparsetu/screens/invoices/detail.dart';
import 'package:vyaparsetu/core/Core.dart';

class PartyDetailScreen extends StatefulWidget {
  final Party party;
  const PartyDetailScreen({super.key, required this.party});

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData({bool forceRefresh = false}) {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId != null) {
      context.read<Core>().party.fetchPartyLedger(businessId, widget.party.id, forceRefresh: forceRefresh);
      context.read<Core>().invoice.fetchPartyInvoices(businessId, widget.party.id, forceRefresh: forceRefresh);
      context.read<Core>().party.fetchPartyQuantitySummary(businessId, widget.party.id, forceRefresh: forceRefresh);
    }
  }

  void _deleteParty(Party party) async {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => const ConfirmationDialog(
            title: 'Delete Contact',
            content:
                'Are you sure you want to delete this party contact? '
                'All transactions associated with this party will lose their reference.',
            confirmText: 'Delete',
            isDestructive: true,
            icon: Icons.delete_outline_rounded,
          ),
    );

    if (confirm == true && context.mounted) {
      final success = await context.read<Core>().party.deleteParty(
        businessId,
        party.id,
      );
      if (success && context.mounted) {
        Navigator.of(context).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) showSuccessToast('Party deleted successfully');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parties = context.select<Core, List<Party>>((c) => c.party.parties);
    final matchedParty = parties.firstWhere(
      (p) => p.id == widget.party.id,
      orElse: () => widget.party,
    );

    final partyLedger = context.select<Core, PartyLedger?>(
      (c) => c.party.getPartyLedgerFor(widget.party.id),
    );
    final isLoading = context.select<Core, bool>(
      (c) => c.party.isLoadingPartyLedger,
    );

    final isCustomer =
        matchedParty.partyType == PartyType.customer ||
        matchedParty.partyType == PartyType.both;

    final entries = partyLedger?.ledger ?? <LedgerEntry>[];
    final totalInvoiceAmount = entries
        .where(
          (e) =>
              isCustomer
                  ? e.type.contains('sale')
                  : e.type.contains('purchase'),
        )
        .fold(0.0, (s, e) => s + e.totalAmount);
    final totalPaid = entries
        .where((e) => e.type.contains('payment'))
        .fold(0.0, (s, e) => s + e.totalAmount);
    final outstanding = totalInvoiceAmount - totalPaid;

    final partyQuantitySummary = context.select<Core, PartyQuantitySummary?>(
      (c) => c.party.getPartyQuantitySummaryFor(widget.party.id),
    );
    final isLoadingPartyQuantity = context.select<Core, bool>(
      (c) => c.party.isLoadingPartyQuantitySummary,
    );

    final partyInvoices = context.select<Core, List<Invoice>>(
      (c) => c.invoice.getPartyInvoicesFor(widget.party.id),
    );

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async => _loadData(forceRefresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
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
                      backgroundColor: AppTheme.secondary.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Hero(
                        tag: 'party_${matchedParty.id}',
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Text(
                            matchedParty.name.isNotEmpty
                                ? matchedParty.name
                                    .substring(0, 1)
                                    .toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        matchedParty.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        matchedParty.phone ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
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
                    getPageRoute(PartyFormScreen(existingParty: matchedParty)),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                ),
                onPressed: () => _deleteParty(matchedParty),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactCard(matchedParty),
                  const SizedBox(height: 20),

                  _buildSectionHeader('Lifetime Summary'),
                  const SizedBox(height: 12),

                  _buildPremiumSummary(
                    isCustomer,
                    totalInvoiceAmount,
                    totalPaid,
                    outstanding,
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Item Quantities'),
                  const SizedBox(height: 12),

                  if (isLoadingPartyQuantity)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (partyQuantitySummary != null && partyQuantitySummary.items.isNotEmpty)
                    ...partyQuantitySummary.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildItemQuantityCard(context, item),
                      ),
                    )
                  else if (partyQuantitySummary != null && partyQuantitySummary.items.isEmpty)
                    _buildEmptyItems(context),

                  const SizedBox(height: 24),

                  _buildActionTier(isCustomer, matchedParty, outstanding),
                  const SizedBox(height: 32),

                  _buildInvoiceHeader(partyInvoices.length),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          if (partyInvoices.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyInvoices(isLoading),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildInvoiceCard(partyInvoices[index]),
                  childCount: partyInvoices.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Party party) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.phone_in_talk_rounded,
            party.phone ?? 'Not provided',
          ),
          if (party.gstin != null && party.gstin!.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                color: isDark ? AppTheme.gray700 : AppTheme.gray200,
              ),
            ),
            _buildInfoRow(Icons.badge_rounded, 'GSTIN: ${party.gstin}'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.white : AppTheme.gray600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: isDark ? Colors.white : AppTheme.gray900,
      ),
    );
  }

  Widget _buildPremiumSummary(
    bool isCustomer,
    double total,
    double paid,
    double pending,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.gray700 : AppTheme.gray200;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildSummaryColumn(
              isCustomer ? 'Total Sales' : 'Lifetime Trade',
              total,
              isDark ? Colors.white : AppTheme.primary,
            ),
            VerticalDivider(width: 1, thickness: 1, color: borderColor),
            _buildSummaryColumn(
              isCustomer ? 'Payments Received' : 'Total Settled',
              paid,
              AppTheme.success,
            ),
            VerticalDivider(width: 1, thickness: 1, color: borderColor),
            _buildSummaryColumn(
              isCustomer ? 'Outstanding' : 'Current Dues',
              pending,
              AppTheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(String label, double value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Column(
          children: [
            SizedBox(
              height: 32,
              child: Center(
                child: Text(
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
              ),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                Formatters.formatCurrency(value),
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

  Widget _buildActionTier(bool isCustomer, Party party, double pending) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    pending > 0
                        ? () {
                          Navigator.of(context).push(
                            getPageRoute(
                              isCustomer
                                  ? PaymentFormScreen.paymentIn(
                                    partyId: party.id,
                                    initialAmount: pending,
                                  )
                                  : PaymentFormScreen.paymentOut(
                                    partyId: party.id,
                                    initialAmount: pending,
                                  ),
                            ),
                          );
                        }
                        : null,
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_card_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCustomer ? 'RECORD PAYMENT' : 'REGISTER SETTLEMENT',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.gray700 : AppTheme.gray200,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    getPageRoute(TransactionScreen(partyId: party.id)),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceHeader(int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Invoices',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: isDark ? Colors.white : AppTheme.gray900,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count Invoices',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPaid = invoice.paymentStatus == PaymentStatus.paid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              getPageRoute(InvoiceDetailScreen(invoiceId: invoice.id)),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.gray700 : AppTheme.gray200,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(
                      alpha: isDark ? 0.15 : 0.05,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatDate(invoice.invoiceDate),
                        style: GoogleFonts.outfit(
                          color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(invoice.totalAmount),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isPaid
                                ? AppTheme.success.withValues(
                                  alpha: isDark ? 0.2 : 0.1,
                                )
                                : invoice.paymentStatus == PaymentStatus.partially_paid
                                    ? AppTheme.warning.withValues(
                                      alpha: isDark ? 0.2 : 0.1,
                                    )
                                    : AppTheme.error.withValues(
                                      alpha: isDark ? 0.2 : 0.1,
                                    ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        invoice.paymentStatus.displayName.toUpperCase(),
                        style: TextStyle(
                          color:
                              isPaid
                                  ? AppTheme.success
                                  : invoice.paymentStatus ==
                                          PaymentStatus.partially_paid
                                      ? AppTheme.warning
                                      : AppTheme.error,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemQuantityCard(BuildContext context, ItemQuantityBreakdown item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.gray700 : AppTheme.gray200;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_rounded, size: 16, color: AppTheme.warning),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.itemName,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.gray900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SOLD',
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warning,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.sold.toStringAsFixed(2),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyItems(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
      ),
      child: Center(
        child: Text(
          'No item transactions recorded',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: isDark ? AppTheme.gray500 : AppTheme.gray400,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInvoices(bool loading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            Icon(
              Icons.receipt_long_outlined,
              size: 70,
              color: isDark ? AppTheme.gray500 : AppTheme.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              'No invoices yet',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.gray500 : AppTheme.gray400,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }
}
