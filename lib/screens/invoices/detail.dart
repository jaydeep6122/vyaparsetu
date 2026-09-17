import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/components/infoRow.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/sectionHeader.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/gst.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/screens/invoices/form.dart';
import 'package:vyaparsetu/screens/invoices/pdfPreview.dart';
import 'package:vyaparsetu/screens/parties/detail.dart';
import 'package:vyaparsetu/screens/payments/detail.dart';
import 'package:vyaparsetu/screens/payments/form.dart';
import 'package:vyaparsetu/services/invoicePdfService.dart';
import 'package:vyaparsetu/types/account.dart';
import 'package:vyaparsetu/types/address.dart';
import 'package:vyaparsetu/types/invoice.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _buildingPdf = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() =>
      context.read<Core>().invoice.getInvoice(widget.invoiceId, refresh: true);

  void _push(Widget screen) => Navigator.of(context).push(getPageRoute(screen));

  /// The bank account printed on the bill: the default bank account, if any.
  Account? _bankAccount(Core core) {
    final accounts = core.account.activeAccounts;
    return accounts.where((a) => a.accountType == AccountType.bank && a.isDefault).firstOrNull ??
        accounts.where((a) => a.accountType == AccountType.bank).firstOrNull;
  }

  Future<void> _openPdf(Invoice invoice, {required bool share}) async {
    final core = context.read<Core>();
    final business = core.business.selectedBusiness;
    if (business == null) return;

    setState(() => _buildingPdf = true);
    try {
      await core.account.fetchAccounts();
      if (!mounted) return;
      final bytes = await InvoicePdfService.generate(
        invoice: invoice,
        business: business,
        bankAccount: _bankAccount(core),
      );
      if (!mounted) return;
      final fileName = '${business.name}-${invoice.invoiceNumber}'.replaceAll(RegExp(r'[^\w\-]+'), '_');
      if (share) {
        await InvoicePdfService.share(
          bytes: bytes,
          fileName: fileName,
          message: 'bill_share_message'.tr(namedArgs: {
            'number': invoice.invoiceNumber,
            'amount': Formatters.formatCurrency(invoice.totalAmount),
            'business': business.name,
          }),
        );
      } else {
        _push(PdfPreviewScreen(bytes: bytes, fileName: fileName));
      }
    } catch (_) {
      if (mounted) showErrorToast('pdf_failed'.tr());
    } finally {
      if (mounted) setState(() => _buildingPdf = false);
    }
  }

  Future<void> _cancel(Invoice invoice) async {
    final reason = await showReasonDialog(
      context,
      title: 'cancel_bill_title'.tr(),
      message: 'cancel_bill_message'.tr(namedArgs: {'number': invoice.invoiceNumber}),
      confirmText: 'cancel_bill'.tr(),
    );
    if (reason == null || !mounted) return;
    final invoices = context.read<Core>().invoice;
    final saved = await invoices.cancelInvoice(invoice.id, reason: reason.isEmpty ? null : reason);
    if (saved == null) {
      showErrorToast(invoices.error ?? 'error_generic'.tr());
    } else {
      showSuccessToast('bill_cancelled'.tr());
    }
  }

  Future<void> _deleteDraft(Invoice invoice) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'delete_draft_title'.tr(),
      message: 'delete_draft_message'.tr(),
      confirmText: 'delete'.tr(),
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final invoices = context.read<Core>().invoice;
    final navigator = Navigator.of(context);
    if (await invoices.deleteDraft(invoice.id)) {
      showSuccessToast('draft_deleted'.tr());
      navigator.pop();
    } else {
      showErrorToast(invoices.error ?? 'error_generic'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final state = core.invoice.detail(widget.invoiceId);
    scheduleReload(state.needsReload, _refresh);
    final invoice = state.value;
    final canManage = invoice != null && !invoice.isCancelled && core.can(MemberRole.accountant);

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice?.invoiceNumber ?? 'bill'.tr()),
        actions: [
          if (invoice != null)
            IconButton(
              tooltip: 'share'.tr(),
              icon: _buildingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_rounded),
              onPressed: _buildingPdf ? null : () => _openPdf(invoice, share: true),
            ),
          if (invoice != null)
            PopupMenuButton<String>(
              onSelected: (action) => switch (action) {
                'edit' => _push(InvoiceFormScreen(invoice: invoice)),
                'cancel' => _cancel(invoice),
                'delete' => _deleteDraft(invoice),
                _ => _openPdf(invoice, share: false),
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'preview', child: Text('view_pdf'.tr())),
                if (canManage) PopupMenuItem(value: 'edit', child: Text('edit'.tr())),
                if (canManage && !invoice.isDraft)
                  PopupMenuItem(value: 'cancel', child: Text('cancel_bill'.tr())),
                if (invoice.isDraft) PopupMenuItem(value: 'delete', child: Text('delete_draft'.tr())),
              ],
            ),
        ],
      ),
      body: LoadStateBody<Invoice>(
        state: state,
        onRetry: _refresh,
        builder: (context, invoice) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceLg,
              AppTheme.spaceSm,
              AppTheme.spaceLg,
              AppTheme.space3xl,
            ),
            children: [
              _buildHeader(context, invoice),
              if (!(invoice.billingAddress?.isEmpty ?? true) ||
                  !((invoice.shipTo ?? invoice.shippingAddress)?.isEmpty ?? true)) ...[
                const SizedBox(height: AppTheme.spaceMd),
                _buildAddresses(context, invoice),
              ],
              const SizedBox(height: AppTheme.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'view_pdf'.tr(),
                      icon: Icons.picture_as_pdf_outlined,
                      variant: AppButtonVariant.outline,
                      compact: true,
                      isLoading: _buildingPdf,
                      onPressed: () => _openPdf(invoice, share: false),
                    ),
                  ),
                  if (!invoice.isCancelled && !invoice.isDraft && invoice.outstanding > 0.004) ...[
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: AppButton(
                        text: 'record_payment'.tr(),
                        icon: Icons.payments_outlined,
                        variant: AppButtonVariant.secondary,
                        compact: true,
                        onPressed: () => _push(InvoicePaymentEntry(invoice: invoice)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppTheme.spaceLg),
              SectionHeader(title: 'items'.tr()),
              _buildLines(context, invoice),
              if (invoice.charges.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceLg),
                SectionHeader(title: 'other_charges'.tr()),
                _buildCharges(context, invoice),
              ],
              const SizedBox(height: AppTheme.spaceLg),
              _buildTotals(context, invoice),
              if (invoice.hasTransportDetails) ...[
                const SizedBox(height: AppTheme.spaceLg),
                SectionHeader(title: 'transport_details'.tr()),
                _buildTransport(context, invoice),
              ],
              if (invoice.payments.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceLg),
                SectionHeader(title: 'payments'.tr()),
                _buildPayments(context, invoice),
              ],
              if (invoice.notes != null || invoice.terms != null) ...[
                const SizedBox(height: AppTheme.spaceLg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoRow(label: 'notes'.tr(), value: invoice.notes),
                      InfoRow(label: 'terms'.tr(), value: invoice.terms),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Invoice invoice) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${invoice.invoiceType.displayName} · ${invoice.taxMode.displayName}',
                  style: context.text.labelMedium,
                ),
              ),
              StatusChip.forInvoice(invoice),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXs),
          AmountDisplay(
            amount: invoice.totalAmount,
            style: context.text.headlineMedium?.copyWith(
              decoration: invoice.isCancelled ? TextDecoration.lineThrough : null,
            ),
          ),
          if (!invoice.isCancelled && invoice.outstanding > 0.004)
            Text(
              'due_amount'.tr(namedArgs: {
                'amount': Formatters.formatCurrency(invoice.outstanding),
              }),
              style: context.text.bodyMedium?.copyWith(color: context.colors.warning),
            ),
          const Divider(height: AppTheme.space2xl),
          InfoRow(
            label: invoice.invoiceType.isSaleSide ? 'customer'.tr() : 'supplier'.tr(),
            valueWidget: invoice.partyId == null
                ? Text(invoice.isWalkIn && invoice.partyName.isEmpty
                    ? 'walk_in_customer'.tr()
                    : invoice.partyName)
                : InkWell(
                    onTap: () => _push(PartyDetailScreen(partyId: invoice.partyId!)),
                    child: Text(
                      invoice.partyName,
                      style: context.text.titleSmall?.copyWith(color: context.colors.primary),
                    ),
                  ),
          ),
          InfoRow(label: 'date'.tr(), value: Formatters.formatDate(invoice.invoiceDate)),
          InfoRow(
            label: 'due_date'.tr(),
            value: invoice.dueDate == null ? null : Formatters.formatDate(invoice.dueDate!),
          ),
          InfoRow(label: 'gstin'.tr(), value: invoice.partyGstin),
          if (invoice.isGst)
            InfoRow(
              label: 'place_of_supply'.tr(),
              value: stateNameFromCode(invoice.placeOfSupply) ?? invoice.placeOfSupply,
            ),
          InfoRow(label: 'supplier_bill_number'.tr(), value: invoice.supplierInvoiceNumber),
          if (invoice.isCancelled)
            InfoRow(
              label: 'cancel_reason'.tr(),
              value: invoice.cancelReason ?? 'no_reason_given'.tr(),
            ),
        ],
      ),
    );
  }

  /// The billing and shipping addresses exactly as printed on this bill.
  Widget _buildAddresses(BuildContext context, Invoice invoice) {
    Widget block(String title, IconData icon, Address? address, String emptyText) {
      final lines = address == null || address.isEmpty ? null : address.lines;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: context.colors.muted),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.labelMedium),
                const SizedBox(height: 2),
                Text(
                  lines?.join('\n') ?? emptyText,
                  style: lines == null
                      ? context.text.bodySmall
                      : context.text.bodyMedium?.copyWith(color: context.colors.ink),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          block(
            'billing_address'.tr(),
            Icons.receipt_long_outlined,
            invoice.billingAddress,
            'no_address_on_bill'.tr(),
          ),
          const Divider(height: AppTheme.space2xl),
          block(
            'shipping_address'.tr(),
            Icons.local_shipping_outlined,
            invoice.shipTo ?? invoice.shippingAddress,
            'same_as_billing'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildLines(BuildContext context, Invoice invoice) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, line) in invoice.lines.indexed) ...[
            if (index > 0) const Divider(indent: AppTheme.spaceLg),
            ListTile(
              title: Text(line.description),
              subtitle: Text([
                '${Formatters.formatQuantity(line.quantity, line.unitCode)} × ${Formatters.formatCurrency(line.unitPrice)}',
                if (line.discountPct > 0)
                  'discount_value'.tr(namedArgs: {
                    'value': Formatters.formatPercent(line.discountPct),
                  }),
                if (invoice.isGst && line.taxRate > 0) Formatters.formatPercent(line.taxRate),
                if (line.hsnSac != null) 'HSN ${line.hsnSac}',
              ].join(' · ')),
              trailing: AmountDisplay(amount: line.lineTotal, style: context.text.titleSmall),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCharges(BuildContext context, Invoice invoice) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, charge) in invoice.charges.indexed) ...[
            if (index > 0) const Divider(indent: AppTheme.spaceLg),
            ListTile(
              title: Text([charge.chargeType.displayName, ?charge.description].join(' · ')),
              subtitle: Text([
                charge.billTo.displayName,
                ?charge.payeeName,
                ?charge.vehicleNo,
                if (charge.outstanding > 0.004)
                  'due_amount'.tr(namedArgs: {
                    'amount': Formatters.formatCurrency(charge.outstanding),
                  }),
              ].join(' · ')),
              trailing: AmountDisplay(amount: charge.total, style: context.text.titleSmall),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotals(BuildContext context, Invoice invoice) {
    return AppCard(
      child: Column(
        children: [
          InfoRow(label: 'taxable_value'.tr(), value: Formatters.formatCurrency(invoice.taxableTotal)),
          if (invoice.discountTotal > 0)
            InfoRow(label: 'discount'.tr(), value: Formatters.formatCurrency(invoice.discountTotal)),
          if (invoice.cgstTotal > 0)
            InfoRow(label: 'cgst'.tr(), value: Formatters.formatCurrency(invoice.cgstTotal)),
          if (invoice.sgstTotal > 0)
            InfoRow(label: 'sgst'.tr(), value: Formatters.formatCurrency(invoice.sgstTotal)),
          if (invoice.igstTotal > 0)
            InfoRow(label: 'igst'.tr(), value: Formatters.formatCurrency(invoice.igstTotal)),
          if (invoice.cessTotal > 0)
            InfoRow(label: 'cess'.tr(), value: Formatters.formatCurrency(invoice.cessTotal)),
          if (invoice.chargesTotal > 0)
            InfoRow(label: 'other_charges'.tr(), value: Formatters.formatCurrency(invoice.chargesTotal)),
          if (invoice.roundOff != 0)
            InfoRow(label: 'round_off'.tr(), value: Formatters.formatCurrency(invoice.roundOff)),
          const Divider(),
          InfoRow(
            label: 'total'.tr(),
            emphasize: true,
            valueWidget: AmountDisplay(amount: invoice.totalAmount, style: context.text.titleMedium),
          ),
          if (invoice.amountSettled > 0)
            InfoRow(label: 'paid'.tr(), value: Formatters.formatCurrency(invoice.amountSettled)),
          if (invoice.outstanding > 0.004)
            InfoRow(
              label: 'balance_due'.tr(),
              emphasize: true,
              valueWidget: AmountDisplay(
                amount: invoice.outstanding,
                tone: AmountTone.negative,
                style: context.text.titleMedium,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransport(BuildContext context, Invoice invoice) {
    return AppCard(
      child: Column(
        children: [
          InfoRow(label: 'vehicle_number'.tr(), value: invoice.vehicleNo),
          InfoRow(label: 'driver_name'.tr(), value: invoice.driverName),
          InfoRow(label: 'driver_phone'.tr(), value: invoice.driverPhone),
          InfoRow(label: 'transport_mode'.tr(), value: invoice.transportMode?.displayName),
          InfoRow(label: 'lr_number'.tr(), value: invoice.lrNo),
          InfoRow(
            label: 'lr_date'.tr(),
            value: invoice.lrDate == null ? null : Formatters.formatDate(invoice.lrDate!),
          ),
          InfoRow(label: 'eway_bill_number'.tr(), value: invoice.ewayBillNo),
          InfoRow(
            label: 'eway_bill_date'.tr(),
            value: invoice.ewayBillDate == null ? null : Formatters.formatDate(invoice.ewayBillDate!),
          ),
          InfoRow(label: 'challan_number'.tr(), value: invoice.chalanNo),
          InfoRow(
            label: 'delivery_date'.tr(),
            value: invoice.deliveryDate == null ? null : Formatters.formatDate(invoice.deliveryDate!),
          ),
        ],
      ),
    );
  }

  Widget _buildPayments(BuildContext context, Invoice invoice) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, link) in invoice.payments.indexed) ...[
            if (index > 0) const Divider(indent: AppTheme.spaceLg),
            ListTile(
              title: Text(link.paymentNumber),
              subtitle: Text([
                if (link.paymentDate != null) Formatters.formatDate(link.paymentDate!),
                link.mode.displayName,
                if (link.invoiceChargeId != null) 'for_charge'.tr(),
              ].join(' · ')),
              trailing: AmountDisplay(amount: link.amount, style: context.text.titleSmall),
              onTap: () => _push(PaymentDetailScreen(paymentId: link.paymentId)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens the payment form pre-filled to settle [invoice].
class InvoicePaymentEntry extends StatelessWidget {
  final Invoice invoice;

  const InvoicePaymentEntry({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return PaymentFormScreen(
      direction: invoice.invoiceType.paymentDirection,
      invoice: invoice,
    );
  }
}
