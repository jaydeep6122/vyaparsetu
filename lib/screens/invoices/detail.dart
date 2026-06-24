import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/screens/invoices/form.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/services/invoicePdfService.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/invoices/pdfPreview.dart';
import 'package:vyaparsetu/screens/payments/form.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/storage/hive/preferences.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  Invoice? _invoice;
  bool _isLoading = true;
  String? _error;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInvoiceDetail(widget.invoiceId);
      });
    }
  }

  Future<void> _loadInvoiceDetail(String id) async {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<Core>().invoice;
    final detail = await provider.fetchInvoiceDetail(businessId, id);

    if (mounted) {
      setState(() {
        _invoice = detail;
        _isLoading = false;
        if (detail == null) {
          _error = 'failed_load_invoice'.tr();
        }
      });
    }
  }

  void _deleteInvoice() async {
    if (_invoice == null) return;
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'delete_invoice'.tr(),
        content: 'delete_invoice_confirm'.tr(),
        confirmText: 'Delete',
        isDestructive: true,
        icon: Icons.delete_outline_rounded,
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<Core>().invoice;
      final success = await provider.deleteInvoice(businessId, _invoice!.id);
      if (success && mounted) {
        Navigator.of(context).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showSuccessToast('invoice_deleted'.tr());
        });
      }
    }
  }

  BillDesign _preferredDesign() {
    final inv = _invoice;
    if (inv == null) return BillDesign.gstClassic;
    final billType = InvoicePdfService.billTypeFromNotes(inv);
    return PreferencesBox.getPreferredDesign(billType) ??
        PreferencesBox.defaultDesignFor(billType);
  }

  Future<void> _viewPdf() async {
    if (_invoice == null) return;
    final party = _resolveParty(_invoice!.partyId);
    final items = context.read<Core>().item.items;
    Navigator.of(context).push(
      getPageRoute(
        InvoicePdfScreen(
          invoice: _invoice!,
          party: party,
          catalogItems: items,
          design: _preferredDesign(),
        ),
      ),
    );
  }

  Party? _resolveParty(String? partyId) {
    if (partyId == null) return null;
    final parties = context.read<Core>().party.parties;
    try {
      return parties.firstWhere((p) => p.id == partyId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareInvoice() async {
    if (_invoice == null) return;
    final business = context.read<Core>().business.selectedBusiness;
    if (business == null) return;

    try {
      showInfoToast('generating_pdf_share'.tr());
      final party = _resolveParty(_invoice!.partyId);
      final items = context.read<Core>().item.items;
      final pdf = await InvoicePdfService.generatePdfByDesign(
        invoice: _invoice!,
        business: business,
        party: party,
        catalogItems: items,
        design: _preferredDesign(),
      );
      await InvoicePdfService.sharePdf(
        pdf,
        'Invoice-${_invoice!.invoiceNumber}',
      );
    } catch (e) {
      showErrorToast('share_failed'.tr());
    }
  }

  Future<void> _printInvoice() async {
    if (_invoice == null) return;
    final business = context.read<Core>().business.selectedBusiness;
    if (business == null) return;

    try {
      showInfoToast('opening_print'.tr());
      final party = _resolveParty(_invoice!.partyId);
      final items = context.read<Core>().item.items;
      final pdf = await InvoicePdfService.generatePdfByDesign(
        invoice: _invoice!,
        business: business,
        party: party,
        catalogItems: items,
        design: _preferredDesign(),
      );
      await InvoicePdfService.printPdf(pdf);
    } catch (e) {
      showErrorToast('print_failed'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: LoadingIndicator(message: 'loading_invoice'.tr()),
      );
    }

    if (_error != null || _invoice == null) {
      return Scaffold(
        appBar: AppBar(title: Text('invoice_detail'.tr())),
        body: AppErrorWidget(
          errorMessage: _error ?? 'error_occurred'.tr(),
          onRetry: () {
            _loadInvoiceDetail(widget.invoiceId);
          },
        ),
      );
    }

    final inv = _invoice!;
    final isSale = inv.invoiceType == InvoiceType.sale;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'invoice_detail'.tr(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : AppTheme.gray900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                getPageRoute(
                  inv.invoiceType == InvoiceType.sale
                      ? InvoiceFormScreen.sale(existingInvoice: inv)
                      : InvoiceFormScreen.purchase(existingInvoice: inv),
                ),
              ).then((_) => _loadInvoiceDetail(inv.id));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _deleteInvoice,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(inv, isDark),
            if (isSale) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAction(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'generate_pdf'.tr(),
                    color: Colors.redAccent,
                    isDark: isDark,
                    onTap: _viewPdf,
                  ),
                  _buildQuickAction(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: Colors.blueAccent,
                    isDark: isDark,
                    onTap: _shareInvoice,
                  ),
                  _buildQuickAction(
                    icon: Icons.print_outlined,
                    label: 'Print',
                    color: Colors.purpleAccent,
                    isDark: isDark,
                    onTap: _printInvoice,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            _buildMetadataCard(inv, isDark),
            const SizedBox(height: 24),
            _buildAddressesCard(inv, isDark),
            const SizedBox(height: 24),
            _buildModernItemsList(isDark),
            const SizedBox(height: 24),
            _buildModernTotalsBreakdown(isDark),
            const SizedBox(height: 24),
            _buildNotesCard(inv, isDark),
            const SizedBox(height: 80), // bottom padding for FAB space
          ],
        ),
      ),
      floatingActionButton: (inv.paymentStatus != PaymentStatus.paid &&
              inv.partyId != null &&
              (inv.invoiceType == InvoiceType.sale ||
                  inv.invoiceType == InvoiceType.purchase))
          ? FloatingActionButton.extended(
              heroTag: 'invoice_detail_fab',
              onPressed: () {
                Navigator.of(context)
                    .push(
                      getPageRoute(PaymentFormScreen.fromInvoice(invoice: inv)),
                    )
                    .then((_) {
                  _loadInvoiceDetail(inv.id);
                });
              },
              label: Text(
                'record_payment'.tr(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              icon: const Icon(Icons.payment_rounded, size: 20),
              backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            )
          : null,
    );
  }

  Widget _buildHeroSection(Invoice inv, bool isDark) {
    final balanceDue = inv.totalAmount - inv.paidAmount;
    final isOverdue = inv.dueDate != null &&
        inv.dueDate!.isBefore(DateTime.now()) &&
        inv.paymentStatus != PaymentStatus.paid;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.primaryDark, AppTheme.primaryDark.withValues(alpha: 0.75)]
              : [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppTheme.primaryDark : AppTheme.primary)
                .withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${inv.invoiceType.displayName} #${inv.invoiceNumber}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      inv.partyName ?? 'walkin_cash_customer'.tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildModernStatusBadge(inv.paymentStatus),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'total_amount'.tr(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatCurrency(inv.totalAmount),
                    style: GoogleFonts.outfit(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'paid_amount'.tr(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatCurrency(inv.paidAmount),
                    style: GoogleFonts.outfit(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'balance_due'.tr(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatCurrency(balanceDue),
                    style: GoogleFonts.outfit(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: balanceDue > 0
                          ? (isOverdue ? Colors.redAccent : Colors.orangeAccent)
                          : Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatusBadge(PaymentStatus status) {
    Color bg;
    Color text;

    switch (status) {
      case PaymentStatus.paid:
        bg = Colors.greenAccent.withValues(alpha: 0.25);
        text = Colors.greenAccent;
        break;
      case PaymentStatus.partially_paid:
        bg = Colors.orangeAccent.withValues(alpha: 0.25);
        text = Colors.orangeAccent;
        break;
      case PaymentStatus.unpaid:
        bg = Colors.redAccent.withValues(alpha: 0.25);
        text = Colors.redAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: text.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: text,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: text,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.gray300 : AppTheme.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(Invoice inv, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.gray800 : AppTheme.gray100,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildMetadataRow(
            icon: Icons.calendar_today_rounded,
            label: 'date_label'.tr(),
            value: Formatters.formatDate(inv.invoiceDate),
            isDark: isDark,
          ),
          const Divider(height: 24),
          _buildMetadataRow(
            icon: Icons.event_busy_rounded,
            label: 'due_date_label'.tr(),
            value: inv.dueDate != null ? Formatters.formatDate(inv.dueDate!) : 'N/A',
            isDark: isDark,
          ),
          const Divider(height: 24),
          _buildMetadataRow(
            icon: Icons.payments_rounded,
            label: 'payment_mode_label'.tr(),
            value: inv.paymentMode.displayName,
            isDark: isDark,
          ),
          if (inv.deliveryDate != null) ...[
            const Divider(height: 24),
            _buildMetadataRow(
              icon: Icons.local_shipping_rounded,
              label: 'delivery_date_label'.tr(),
              value: Formatters.formatDate(inv.deliveryDate!),
              isDark: isDark,
            ),
          ],
          if (inv.chalanNo != null && inv.chalanNo!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildMetadataRow(
              icon: Icons.receipt_long_rounded,
              label: 'chalan_number_label'.tr(),
              value: inv.chalanNo!,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.primaryDark : AppTheme.primary)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppTheme.primaryDark : AppTheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.gray800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressesCard(Invoice inv, bool isDark) {
    final hasBilling = inv.billingAddress != null && inv.billingAddress!.isNotEmpty;
    final hasShipping = inv.shippingAddress != null && inv.shippingAddress!.isNotEmpty;

    if (!hasBilling && !hasShipping) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.gray800 : AppTheme.gray100,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 20,
                color: isDark ? AppTheme.primaryDark : AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'addresses'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasBilling) ...[
            Text(
              'bill_to'.tr().toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              inv.billingAddress!,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                color: isDark ? Colors.white70 : AppTheme.gray700,
              ),
            ),
          ],
          if (hasBilling && hasShipping) ...[
            const Divider(height: 24),
          ],
          if (hasShipping) ...[
            Text(
              'ship_to'.tr().toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              inv.shippingAddress!,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                color: isDark ? Colors.white70 : AppTheme.gray700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernItemsList(bool isDark) {
    final items = _invoice?.items ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shopping_bag_rounded,
              size: 20,
              color: isDark ? AppTheme.primaryDark : AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'items_details'.tr(),
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.gray900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: isDark ? Colors.white : AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.gray800 : AppTheme.gray50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                              ),
                            ),
                            child: Text(
                              '${item.quantity} Qty',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : AppTheme.gray600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Formatters.formatCurrency(item.unitPrice),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (item.discountPercentage > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '-${item.discountPercentage}%',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          if (item.taxRate > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '+${item.taxRate}% Tax',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.formatCurrency(item.totalAmount),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppTheme.gray900,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildModernTotalsBreakdown(bool isDark) {
    final inv = _invoice!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.gray800 : AppTheme.gray100,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTotalRow(
            'sub_total_label'.tr(),
            Formatters.formatCurrency(inv.subTotal),
            isDark: isDark,
          ),
          if (inv.discountAmount > 0) ...[
            const SizedBox(height: 12),
            _buildTotalRow(
              'discount_negative'.tr(),
              '-${Formatters.formatCurrency(inv.discountAmount)}',
              color: Colors.green,
              isDark: isDark,
            ),
          ],
          if (inv.taxAmount > 0) ...[
            const SizedBox(height: 12),
            _buildTotalRow(
              'tax_positive'.tr(),
              Formatters.formatCurrency(inv.taxAmount),
              color: Colors.orange,
              isDark: isDark,
            ),
          ],
          if (inv.transportCost > 0) ...[
            const SizedBox(height: 12),
            _buildTotalRow(
              'transport_cost'.tr(),
              Formatters.formatCurrency(inv.transportCost),
              color: Colors.blueGrey,
              isDark: isDark,
            ),
          ],
          const Divider(height: 24),
          _buildTotalRow(
            'Total Bill Amount',
            Formatters.formatCurrency(inv.totalAmount),
            isBold: true,
            fontSize: 16,
            color: isDark ? Colors.white : AppTheme.primary,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildTotalRow(
            'Paid Amount',
            Formatters.formatCurrency(inv.paidAmount),
            isDark: isDark,
          ),
          const Divider(height: 24),
          _buildTotalRow(
            'Balance Due',
            Formatters.formatCurrency(inv.totalAmount - inv.paidAmount),
            isBold: true,
            color: Colors.redAccent,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String val, {
    bool isBold = false,
    Color? color,
    double? fontSize,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: fontSize ?? 13.5,
            color: isBold
                ? (isDark ? Colors.white : AppTheme.gray900)
                : Colors.grey,
          ),
        ),
        Text(
          val,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: fontSize ?? 14,
            color: color ?? (isDark ? Colors.white : AppTheme.gray900),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(Invoice inv, bool isDark) {
    if (inv.visibleNotes == null || inv.visibleNotes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.gray800 : AppTheme.gray100,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sticky_note_2_rounded,
                size: 20,
                color: isDark ? AppTheme.primaryDark : AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'notes'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            inv.visibleNotes!,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              color: isDark ? Colors.white70 : AppTheme.gray700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
