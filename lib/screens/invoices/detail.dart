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
          _error = 'Failed to load invoice details';
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
      builder: (context) => const ConfirmationDialog(
        title: 'Delete Invoice',
        content:
            'Are you sure you want to delete this invoice? Stock counts and party balances will be automatically adjusted back.',
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
          if (mounted) showSuccessToast('Invoice deleted successfully');
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
      showInfoToast('Generating PDF to share...');
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
      showErrorToast('Failed to share PDF: $e');
    }
  }

  Future<void> _printInvoice() async {
    if (_invoice == null) return;
    final business = context.read<Core>().business.selectedBusiness;
    if (business == null) return;

    try {
      showInfoToast('Opening print preview...');
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
      showErrorToast('Failed to print PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Loading invoice details...'),
      );
    }

    if (_error != null || _invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Detail')),
        body: AppErrorWidget(
          errorMessage: _error ?? 'Error occurred',
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
          inv.invoiceNumber,
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with PDF Actions (Sale invoices only)
            if (isSale) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _viewPdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(
                        'generate_pdf'.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareInvoice,
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: Text(
                        'Share',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _printInvoice,
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: Text(
                        'Print',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Bill Summary Header Card
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inv.partyName ?? 'Walk-in / Cash Customer',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDark ? Colors.white : AppTheme.gray900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Type: ${inv.invoiceType.displayName}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.gray400
                                    : AppTheme.gray600,
                              ),
                            ),
                          ],
                        ),
                        _buildStatusBadge(inv.paymentStatus),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildHeaderMeta(
                            'Date',
                            Formatters.formatDate(inv.invoiceDate),
                          ),
                        ),
                        Expanded(
                          child: _buildHeaderMeta(
                            'Due Date',
                            inv.dueDate != null
                                ? Formatters.formatDate(inv.dueDate!)
                                : 'N/A',
                          ),
                        ),
                        Expanded(
                          child: _buildHeaderMeta(
                            'Payment Mode',
                            inv.paymentMode.displayName,
                          ),
                        ),
                      ],
                    ),
                    if (inv.invoiceType == InvoiceType.sale &&
                        inv.deliveryDate != null) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildHeaderMeta(
                              'Delivery Date',
                              Formatters.formatDate(inv.deliveryDate!),
                            ),
                          ),
                          Expanded(
                            child: _buildHeaderMeta(
                              'Chalan Number',
                              inv.chalanNo ?? 'N/A',
                            ),
                          ),
                          const Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                    ],
                    if (inv.invoiceType == InvoiceType.purchase &&
                        inv.chalanNo != null &&
                        inv.chalanNo!.isNotEmpty) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildHeaderMeta(
                              'Chalan Number',
                              inv.chalanNo!,
                            ),
                          ),
                          const Expanded(child: SizedBox.shrink()),
                          const Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bill To / Ship To Addresses
            if (inv.billingAddress != null && inv.billingAddress!.isNotEmpty ||
                inv.shippingAddress != null && inv.shippingAddress!.isNotEmpty)
              _buildAddressSection(inv),
            const SizedBox(height: 24),

            // Items List
            Text(
              'Items Details',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 8),
            _buildItemsTable(),
            const SizedBox(height: 24),

            // Totals breakdown
            _buildTotalsBreakdown(),
            const SizedBox(height: 20),

            // Notes
            if (inv.visibleNotes != null && inv.visibleNotes!.isNotEmpty) ...[
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'notes'.tr(),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        inv.visibleNotes!,
                        style: GoogleFonts.outfit(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
      floatingActionButton:
          (inv.paymentStatus != PaymentStatus.paid &&
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
              label: Text('record_payment'.tr()),
              icon: const Icon(Icons.payment_rounded),
              backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildHeaderMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(PaymentStatus status) {
    Color bg;
    Color text;

    switch (status) {
      case PaymentStatus.paid:
        bg = Colors.green.withValues(alpha: 0.1);
        text = Colors.green;
        break;
      case PaymentStatus.partially_paid:
        bg = Colors.orange.withValues(alpha: 0.1);
        text = Colors.orange;
        break;
      case PaymentStatus.unpaid:
        bg = Colors.red.withValues(alpha: 0.1);
        text = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(
        status.displayName,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  Widget _buildAddressSection(Invoice inv) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasBilling =
        inv.billingAddress != null && inv.billingAddress!.isNotEmpty;
    final hasShipping =
        inv.shippingAddress != null && inv.shippingAddress!.isNotEmpty;

    return Row(
      children: [
        if (hasBilling)
          Expanded(child: _addressCard('Bill To', inv.billingAddress!, isDark)),
        if (hasBilling && hasShipping) const SizedBox(width: 12),
        if (hasShipping)
          Expanded(
            child: _addressCard('Ship To', inv.shippingAddress!, isDark),
          ),
        if (!hasBilling && hasShipping) const Spacer(),
      ],
    );
  }

  Widget _addressCard(String label, String address, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.gray400 : AppTheme.gray500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            address,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isDark ? Colors.white : AppTheme.gray900,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    final items = _invoice?.items ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: items.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            dense: true,
            title: Text(
              item.name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              '${item.quantity} qty x ${Formatters.formatCurrency(item.unitPrice)} | Disc: ${item.discountPercentage}% | Tax: ${item.taxRate}%',
              style: GoogleFonts.outfit(fontSize: 12),
            ),
            trailing: Text(
              Formatters.formatCurrency(item.totalAmount),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTotalsBreakdown() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inv = _invoice!;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTotalRow(
              'Sub Total',
              Formatters.formatCurrency(inv.subTotal),
            ),
            const SizedBox(height: 8),
            _buildTotalRow(
              'Discount (-)',
              Formatters.formatCurrency(inv.discountAmount),
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            _buildTotalRow(
              'Tax (+)',
              Formatters.formatCurrency(inv.taxAmount),
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildTotalRow(
              'Transport Cost (+)',
              Formatters.formatCurrency(inv.transportCost),
              color: Colors.blueGrey,
            ),
            const Divider(height: 20),
            _buildTotalRow(
              'Total Bill Amount',
              Formatters.formatCurrency(inv.totalAmount),
              isBold: true,
              fontSize: 16,
              color: isDark ? Colors.white : AppTheme.primary,
            ),
            const SizedBox(height: 8),
            _buildTotalRow(
              'Paid Amount',
              Formatters.formatCurrency(inv.paidAmount),
            ),
            const Divider(height: 20),
            _buildTotalRow(
              'Balance Due',
              Formatters.formatCurrency(inv.totalAmount - inv.paidAmount),
              isBold: true,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String val, {
    bool isBold = false,
    Color? color,
    double? fontSize,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: fontSize ?? 14,
          ),
        ),
        Text(
          val,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: fontSize ?? 14,
            color: color,
          ),
        ),
      ],
    );
  }
}
