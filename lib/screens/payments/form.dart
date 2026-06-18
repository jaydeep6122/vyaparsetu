import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/types/payment.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/core/Core.dart';

class PaymentFormScreen extends StatefulWidget {
  final Payment? existingPayment;
  final Invoice? invoice;
  final String? partyId;
  final double? initialAmount;
  final PaymentType paymentType;

  const PaymentFormScreen({
    super.key,
    this.existingPayment,
    this.invoice,
    this.partyId,
    this.initialAmount,
    required this.paymentType,
  });

  const PaymentFormScreen.paymentIn({
    super.key,
    this.partyId,
    this.initialAmount,
  }) : existingPayment = null,
       invoice = null,
       paymentType = PaymentType.payment_in;

  const PaymentFormScreen.paymentOut({
    super.key,
    this.partyId,
    this.initialAmount,
  }) : existingPayment = null,
       invoice = null,
       paymentType = PaymentType.payment_out;

  PaymentFormScreen.edit({super.key, required this.existingPayment})
    : invoice = null,
      partyId = null,
      initialAmount = null,
      paymentType = existingPayment!.paymentType;

  PaymentFormScreen.fromInvoice({super.key, required this.invoice})
    : existingPayment = null,
      partyId = null,
      initialAmount = null,
      paymentType =
          invoice!.invoiceType == InvoiceType.sale
              ? PaymentType.payment_in
              : PaymentType.payment_out;

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPartyId;
  String? _selectedInvoiceId;
  final _amountController = TextEditingController();
  final _refNoController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  PaymentMode _paymentMode = PaymentMode.cash;

  Payment? _existingPayment;
  bool _isEdit = false;
  bool _isInitialized = false;

  List<Invoice> _unpaidInvoices = [];
  bool _isLoadingInvoices = false;
  bool _lockPartyAndInvoice = false;

  @override
  void dispose() {
    _amountController.dispose();
    _refNoController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;

    if (widget.existingPayment != null) {
      final arg = widget.existingPayment!;
      _existingPayment = arg;
      _isEdit = true;
      _paymentMode = arg.paymentMode;
      _paymentDate = arg.paymentDate;
      _amountController.text = arg.amount.toString();
      _refNoController.text = arg.referenceNumber ?? '';
      _descController.text = arg.description ?? '';
      _selectedPartyId = arg.partyId;
      _selectedInvoiceId = arg.invoiceId;
      _lockPartyAndInvoice = true;
      if (_selectedPartyId != null) {
        _loadUnpaidInvoices(_selectedPartyId!);
      }
    } else if (widget.invoice != null) {
      final arg = widget.invoice!;
      if (arg.partyId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showErrorToast(
            'Cannot record payment for a cash/walk-in customer invoice',
          );
          Navigator.of(context).pop();
        });
        return;
      }
      _selectedPartyId = arg.partyId;
      _selectedInvoiceId = arg.id;
      _lockPartyAndInvoice = true;
      _amountController.text = (arg.totalAmount - arg.paidAmount).toString();
      if (_selectedPartyId != null) {
        _loadUnpaidInvoices(_selectedPartyId!);
      }
    }
    if (widget.partyId != null) {
      _selectedPartyId = widget.partyId;
      _loadUnpaidInvoices(widget.partyId!);
    }
    if (widget.initialAmount != null && _selectedInvoiceId == null) {
      _amountController.text = widget.initialAmount.toString();
    }
    _loadParties();
  }

  void _loadParties() {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId != null) {
      context.read<Core>().party.fetchParties(businessId);
    }
  }

  Future<void> _loadUnpaidInvoices(String partyId) async {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId == null) return;

    if (mounted) setState(() => _isLoadingInvoices = true);

    try {
      final invoiceModule = context.read<Core>().invoice;
      await invoiceModule.fetchInvoices(businessId, partyId: partyId);

      if (!mounted) return;

      final targetType =
          widget.paymentType == PaymentType.payment_in
              ? InvoiceType.sale
              : InvoiceType.purchase;

      setState(() {
        _unpaidInvoices =
            invoiceModule.invoices
                .where(
                  (inv) =>
                      inv.invoiceType == targetType &&
                      inv.paymentStatus != PaymentStatus.paid,
                )
                .toList();

        if (_lockPartyAndInvoice && _selectedInvoiceId != null) {
          final isPresent = _unpaidInvoices.any(
            (i) => i.id == _selectedInvoiceId,
          );
          if (!isPresent && widget.invoice != null) {
            _unpaidInvoices.add(widget.invoice!);
          }
        }
      });
    } catch (e) {
      if (mounted) showErrorToast('Failed to load party invoices');
    } finally {
      if (mounted) setState(() => _isLoadingInvoices = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  void _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPartyId == null) {
      showErrorToast('Please select a party contact');
      return;
    }

    if (_selectedInvoiceId == null) {
      showErrorToast('Please select an invoice to link this payment');
      return;
    }

    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId == null) return;

    final data = {
      'party_id': _selectedPartyId!,
      'invoice_id': _selectedInvoiceId,
      'payment_type': widget.paymentType.value,
      'amount': double.parse(_amountController.text.trim()),
      'payment_date': _paymentDate.toUtc().toIso8601String(),
      'payment_mode': _paymentMode.value,
      'reference_number':
          _refNoController.text.trim().isEmpty
              ? null
              : _refNoController.text.trim(),
      'description':
          _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
    };

    final provider = context.read<Core>().payment;

    bool success;
    if (_isEdit && _existingPayment != null) {
      success = await provider.updatePayment(
        businessId,
        _existingPayment!.id,
        data,
      );
    } else {
      success = await provider.createPayment(businessId, data);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      context.read<Core>().business.fetchBusinesses();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted)
          showSuccessToast(
            _isEdit
                ? 'Payment updated successfully'
                : 'Payment recorded successfully',
          );
      });
    } else if (mounted) {
      showErrorToast(provider.error ?? 'Failed to save payment');
    }
  }

  void _deletePayment() async {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId == null || _existingPayment == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => const ConfirmationDialog(
            title: 'Delete Payment',
            content: 'Are you sure you want to delete this recorded payment?',
            confirmText: 'Delete',
            isDestructive: true,
            icon: Icons.delete_outline_rounded,
          ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<Core>().payment.deletePayment(
        businessId,
        _existingPayment!.id,
      );
      if (success && mounted) {
        Navigator.of(context).pop();
        context.read<Core>().business.fetchBusinesses();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showSuccessToast('Payment deleted successfully');
        });
      }
    }
  }

  Future<void> _showInvoicePicker() async {
    if (_unpaidInvoices.isEmpty) {
      showErrorToast('No unpaid invoices found for this party');
      return;
    }

    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      showDragHandle: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Select Invoice',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: isDark ? AppTheme.gray700 : Colors.grey.shade200),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ..._unpaidInvoices.map((inv) {
                      final due = inv.totalAmount - inv.paidAmount;
                      final isSelected = inv.id == _selectedInvoiceId;
                      final accent =
                          widget.paymentType == PaymentType.payment_in
                              ? AppTheme.success
                              : AppTheme.error;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.description_outlined,
                          color: isSelected ? accent : AppTheme.slate500,
                        ),
                        title: Text(
                          inv.invoiceNumber,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${Formatters.formatCurrency(due)} due',
                          style: GoogleFonts.outfit(
                            color: AppTheme.successDark,
                          ),
                        ),
                        trailing: Text(
                          Formatters.formatDate(inv.invoiceDate),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.slate500,
                          ),
                        ),
                        onTap: () => Navigator.of(ctx).pop(inv.id),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    setState(() {
      _selectedInvoiceId = result;
      final inv = _unpaidInvoices.firstWhere((i) => i.id == result);
      _amountController.text = (inv.totalAmount - inv.paidAmount).toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor =
        widget.paymentType == PaymentType.payment_in
            ? AppTheme.success
            : AppTheme.error;
    final parties = context.select<Core, List<Party>>((c) => c.party.parties);

    final filteredParties =
        parties.where((p) {
          if (widget.partyId != null && p.id == widget.partyId) return true;
          if (widget.paymentType == PaymentType.payment_in) {
            return p.partyType == PartyType.customer ||
                p.partyType == PartyType.both;
          }
          return p.partyType == PartyType.supplier ||
              p.partyType == PartyType.both;
        }).toList();

    final selectedParty =
        _selectedPartyId != null
            ? parties.where((p) => p.id == _selectedPartyId).firstOrNull
            : null;
    final selectedPartyName =
        _existingPayment?.partyName ?? selectedParty?.name;

    final showPartySelector = _selectedPartyId == null && !_lockPartyAndInvoice;
    final showInvoiceSelector =
        _selectedPartyId != null && !_lockPartyAndInvoice;
    final showSubtitle =
        (_lockPartyAndInvoice || widget.partyId != null) &&
        selectedPartyName != null;

    final invoiceLabel =
        _selectedInvoiceId != null
            ? (_unpaidInvoices
                    .where((i) => i.id == _selectedInvoiceId)
                    .firstOrNull
                    ?.invoiceNumber ??
                'Invoice selected')
            : 'Select Invoice *';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit
                  ? 'Edit Payment'
                  : widget.paymentType == PaymentType.payment_in
                  ? 'Record Payment In'
                  : 'Record Payment Out',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            if (showSubtitle)
              Text(
                selectedPartyName,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
          ],
        ),
        actions:
            _isEdit
                ? [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: _deletePayment,
                  ),
                ]
                : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showPartySelector) ...[
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText:
                          widget.paymentType == PaymentType.payment_in
                              ? 'Select Customer'
                              : 'Select Supplier',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                    ),
                    isExpanded: true,
                    value: null,
                    items:
                        filteredParties.map((party) {
                          return DropdownMenuItem<String>(
                            value: party.id,
                            child: Text(
                              party.name,
                              style: GoogleFonts.outfit(),
                            ),
                          );
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedPartyId = val;
                          _selectedInvoiceId = null;
                        });
                        _loadUnpaidInvoices(val);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                if (_selectedPartyId != null &&
                    !_lockPartyAndInvoice &&
                    selectedPartyName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedPartyName,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color:
                                      isDark ? Colors.white : AppTheme.primary,
                                ),
                              ),
                              Text(
                                widget.paymentType == PaymentType.payment_in
                                    ? 'Customer'
                                    : 'Supplier',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedPartyId = null;
                              _selectedInvoiceId = null;
                              _unpaidInvoices.clear();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Change',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (showInvoiceSelector) ...[
                  _isLoadingInvoices
                      ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : InkWell(
                        onTap: _showInvoicePicker,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Link to Invoice',
                            prefixIcon: const Icon(Icons.description_outlined),
                            suffixIcon: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                          ),
                          child: Text(
                            invoiceLabel,
                            style: GoogleFonts.outfit(
                              fontWeight:
                                  _selectedInvoiceId != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 20),
                ],

                Text(
                  'Amount',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹  ',
                    prefixStyle: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor:
                        isDark
                            ? AppTheme.cardDark
                            : accentColor.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                  ),
                  validator:
                      (val) => Validators.validatePositiveAmount(val, 'Amount'),
                ),
                const SizedBox(height: 24),

                Text(
                  'payment_mode'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildModeTile(
                      icon: Icons.monetization_on_outlined,
                      label: 'Cash',
                      mode: PaymentMode.cash,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _buildModeTile(
                      icon: Icons.account_balance_outlined,
                      label: 'Bank',
                      mode: PaymentMode.bank,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _buildModeTile(
                      icon: Icons.phone_android_outlined,
                      label: 'UPI',
                      mode: PaymentMode.upi,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'payment_date'.tr(),
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      Formatters.formatDate(_paymentDate),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _refNoController,
                  labelText: 'reference_number'.tr(),
                  hintText: 'Txn ID, Cheque #, etc.',
                  prefixIcon: Icons.tag,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _descController,
                  labelText: 'description'.tr(),
                  hintText: 'Add remarks...',
                  maxLines: 2,
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: 28),

                AppButton(
                  text: _isEdit ? 'Update Payment' : 'Record Payment',
                  isLoading: context.select<Core, bool>(
                    (c) => c.payment.isLoading,
                  ),
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTile({
    required IconData icon,
    required String label,
    required PaymentMode mode,
    required Color accentColor,
    required bool isDark,
  }) {
    final isSelected = _paymentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? accentColor.withValues(alpha: 0.1)
                    : (isDark ? AppTheme.cardDark : AppTheme.gray50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? accentColor
                      : (isDark ? AppTheme.gray600 : AppTheme.gray300),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color:
                    isSelected
                        ? accentColor
                        : (isDark ? Colors.white60 : AppTheme.slate500),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected
                          ? (isDark ? Colors.white : accentColor)
                          : (isDark ? Colors.white60 : AppTheme.slate500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
