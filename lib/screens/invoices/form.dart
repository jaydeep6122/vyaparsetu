import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/types/item.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/types/invoiceItem.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/core/Core.dart';

class InvoiceFormScreen extends StatefulWidget {
  final bool isSale;
  final Invoice? existingInvoice;

  const InvoiceFormScreen.sale({super.key, this.existingInvoice})
      : isSale = true;

  const InvoiceFormScreen.purchase({super.key, this.existingInvoice})
      : isSale = false;

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late InvoiceType _invoiceType;
  late bool _isSale;

  final _invoiceNumberController = TextEditingController();
  final _chalanNoController = TextEditingController();
  final _transportQtyController = TextEditingController();
  final _transportRateController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  DateTime? _deliveryDate;

  String? _selectedPartyId;
  String? _billingAddress;
  String? _shippingAddress;
  final List<InvoiceItem> _lineItems = [];

  PaymentMode _paymentMode = PaymentMode.cash;

  double _subTotal = 0.0;
  double _taxAmount = 0.0;
  double _discountAmount = 0.0;
  double _transportCost = 0.0;
  double _totalAmount = 0.0;

  bool _isEdit = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isEdit = widget.existingInvoice != null;
      _isSale = widget.isSale;
      _invoiceType = _isSale ? InvoiceType.sale : InvoiceType.purchase;
      _loadPartiesAndItems();

      if (_isEdit) {
        final inv = widget.existingInvoice!;
        _selectedPartyId = inv.partyId;
        _billingAddress = inv.billingAddress;
        _shippingAddress = inv.shippingAddress;
        _invoiceNumberController.text = inv.invoiceNumber;
        _invoiceDate = inv.invoiceDate;
        _dueDate = inv.dueDate;
        _deliveryDate = inv.deliveryDate;
        _chalanNoController.text = inv.chalanNo ?? '';
        if (_isSale) {
          _deliveryDate = inv.deliveryDate;
        } else {
          _transportQtyController.text =
              inv.transportCost > 0 ? inv.transportCost.toString() : '';
        }
        _lineItems.addAll(inv.items ?? []);
        _paymentMode = inv.paymentMode;
        if (inv.paidAmount > 0) {
          _paidAmountController.text = inv.paidAmount.toString();
        }
        _notesController.text = inv.notes ?? '';
        WidgetsBinding.instance.addPostFrameCallback((_) => _calculateTotals());
      } else {
        if (_isSale) {
          _deliveryDate = DateTime.now();
        }
        final business = context.read<Core>().business.selectedBusiness;
        if (business != null && _isSale) {
          _invoiceNumberController.text = business.invoicePrefix;
        }
      }

      _isInitialized = true;
    }
  }

  void _loadPartiesAndItems() {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId != null) {
      context.read<Core>().party.fetchParties(businessId);
      context.read<Core>().item.fetchItems(businessId);
    }
  }

  void _calculateTotals() {
    double sub = 0.0;
    double disc = 0.0;
    double tax = 0.0;
    final transport = _isSale
        ? 0.0
        : (double.tryParse(_transportQtyController.text.trim()) ?? 0.0) *
            (double.tryParse(_transportRateController.text.trim()) ?? 0.0);

    for (var item in _lineItems) {
      final lineSub = item.unitPrice * item.quantity;
      final lineDisc = lineSub * (item.discountPercentage / 100);
      final taxableAmount = lineSub - lineDisc;
      final lineTax = taxableAmount * (item.taxRate / 100);

      sub += lineSub;
      disc += lineDisc;
      tax += lineTax;
    }

    setState(() {
      _subTotal = sub;
      _discountAmount = disc;
      _taxAmount = tax;
      _transportCost = transport;
      _totalAmount = sub - disc + tax + transport;
    });
  }

  void _onAddItemDialog() {
    final items = context.read<Core>().item.items;

    Item? tempItem;
    final qtyController = TextEditingController();
    final rateController = TextEditingController();
    final discController = TextEditingController();
    final taxController = TextEditingController();

    VoidCallback? onUpdate;
    qtyController.addListener(() => onUpdate?.call());
    rateController.addListener(() => onUpdate?.call());
    discController.addListener(() => onUpdate?.call());
    taxController.addListener(() => onUpdate?.call());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            onUpdate = () {
              setStateDialog(() {});
            };

            final qtyVal = double.tryParse(qtyController.text.trim()) ?? 1.0;
            final rateVal = double.tryParse(rateController.text.trim()) ?? 0.0;
            final discVal = double.tryParse(discController.text.trim()) ?? 0.0;
            final taxVal = double.tryParse(taxController.text.trim()) ?? 0.0;

            final lineSub = qtyVal * rateVal;
            final lineDisc = lineSub * (discVal / 100);
            final lineTax = (lineSub - lineDisc) * (taxVal / 100);
            final lineTotal = lineSub - lineDisc + lineTax;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.backgroundDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
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
                    // Header
                    Text(
                      'Add Product / Service',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isDark ? Colors.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Product Selection
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Product/Service',
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                      value: tempItem?.id,
                      items:
                          items.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.id,
                              child: Text(
                                item.name,
                                style: GoogleFonts.outfit(),
                              ),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() {
                            final matchedItem = items.firstWhere(
                              (item) => item.id == val,
                            );
                            tempItem = matchedItem;
                            rateController.text = '';
                            taxController.text = '';
                          });
                        }
                      },
                    ),
                    if (tempItem != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppTheme.primary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : AppTheme.primary.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tag_rounded,
                                  size: 14,
                                  color:
                                      isDark ? Colors.white : AppTheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'HSN Code: ${tempItem?.hsnCode ?? "N/A"}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : AppTheme.gray800,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? AppTheme.gray800
                                        : AppTheme.primary.withValues(
                                          alpha: 0.08,
                                        ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Unit: ${tempItem?.measuringUnit ?? "pcs"}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white : AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Quantity and Rate
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: qtyController,
                            labelText: 'Quantity',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.unfold_more_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: rateController,
                            labelText: 'Rate (₹)',
                            keyboardType: TextInputType.number,
                            hintText: 'Rate',
                            prefixIcon: Icons.currency_rupee_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Discount and Tax
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: discController,
                            labelText: 'Discount (%)',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.percent_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: taxController,
                            labelText: 'Tax Rate (%)',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.gavel_rounded,
                          ),
                        ),
                      ],
                    ),
                    if (tempItem != null) ...[
                      const SizedBox(height: 20),
                      // Summary breakdown panel
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? AppTheme.gray800.withValues(alpha: 0.3)
                                  : AppTheme.gray100.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isDark
                                    ? AppTheme.gray700.withValues(alpha: 0.4)
                                    : AppTheme.gray200.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color:
                                        isDark
                                            ? AppTheme.gray400
                                            : AppTheme.gray600,
                                  ),
                                ),
                                Text(
                                  Formatters.formatCurrency(lineSub),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : AppTheme.gray800,
                                  ),
                                ),
                              ],
                            ),
                            if (lineDisc > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Discount (${discVal.toStringAsFixed(0)}%)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color:
                                          isDark
                                              ? AppTheme.gray400
                                              : AppTheme.gray600,
                                    ),
                                  ),
                                  Text(
                                    '- ${Formatters.formatCurrency(lineDisc)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (lineTax > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tax (${taxVal.toStringAsFixed(0)}%)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color:
                                          isDark
                                              ? AppTheme.gray400
                                              : AppTheme.gray600,
                                    ),
                                  ),
                                  Text(
                                    '+ ${Formatters.formatCurrency(lineTax)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : AppTheme.gray800,
                                  ),
                                ),
                                Text(
                                  Formatters.formatCurrency(lineTotal),
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Add Item Button (Full Width)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                              if (tempItem == null) {
                                showErrorToast('Please select an item');
                                return;
                              }
                              final qty =
                                  double.tryParse(qtyController.text.trim()) ??
                                  1.0;
                              final rate =
                                  double.tryParse(rateController.text.trim()) ??
                                  0.0;
                              final disc =
                                  double.tryParse(discController.text.trim()) ??
                                  0.0;
                              final tax =
                                  double.tryParse(taxController.text.trim()) ??
                                  0.0;

                              final total =
                                  (rate * qty) - ((rate * qty) * (disc / 100));
                              final totalWithTax =
                                  total + (total * (tax / 100));

                              final invoiceItem = InvoiceItem(
                                id: '',
                                invoiceId: '',
                                itemId: tempItem!.id,
                                name: tempItem!.name,
                                quantity: qty,
                                unitPrice: rate,
                                discountPercentage: disc,
                                discountAmount: (rate * qty) * (disc / 100),
                                taxRate: tax,
                                taxAmount: total * (tax / 100),
                                totalAmount: totalWithTax,
                              );

                              setState(() {
                                _lineItems.add(invoiceItem);
                              });
                              _calculateTotals();
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Add Item',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onRemoveItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
    });
    _calculateTotals();
  }

  Future<void> _selectDate(BuildContext context, int dateField) async {
    final DateTime initialDate;
    switch (dateField) {
      case 0:
        initialDate = _invoiceDate;
      case 1:
        initialDate = _dueDate ?? DateTime.now();
      case 2:
        initialDate = _deliveryDate ?? DateTime.now();
      default:
        initialDate = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (!isDark) return child!;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.white,
              onPrimary: AppTheme.primaryDark,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppTheme.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (dateField) {
          case 0:
            _invoiceDate = picked;
          case 1:
            _dueDate = picked;
          case 2:
            _deliveryDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_isSale && _deliveryDate == null) {
      showErrorToast('Please select Delivery Date');
      return;
    }

    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId == null) return;

    if (_lineItems.isEmpty) {
      showErrorToast('Please add at least one item to the invoice');
      return;
    }

    final paidText = _paidAmountController.text.trim();
    final hasPaidAmount = paidText.isNotEmpty;
    final paid = hasPaidAmount ? (double.tryParse(paidText) ?? 0.0) : 0.0;

    if (hasPaidAmount && paid > _totalAmount) {
      showErrorToast('Paid amount cannot exceed total invoice amount');
      return;
    }

    if (hasPaidAmount && _selectedPartyId == null && paid < _totalAmount) {
      showErrorToast(
        'Walk-in/Cash sales must be paid in full at the time of creation.',
      );
      return;
    }

    PaymentStatus status = PaymentStatus.unpaid;
    if (hasPaidAmount && paid == _totalAmount) {
      status = PaymentStatus.paid;
    } else if (hasPaidAmount && paid > 0) {
      status = PaymentStatus.partially_paid;
    }

    final transportCost = _isSale
        ? 0.0
        : (double.tryParse(_transportQtyController.text.trim()) ?? 0.0) *
            (double.tryParse(_transportRateController.text.trim()) ?? 0.0);

    final data = {
      'party_id': _selectedPartyId,
      'invoice_number': _invoiceNumberController.text.trim(),
      'invoice_type': _invoiceType.value,
      'chalan_no':
          _chalanNoController.text.trim().isEmpty
              ? null
              : _chalanNoController.text.trim(),
      'transport_cost': transportCost,
      'invoice_date': _invoiceDate.toUtc().toIso8601String(),
      if (_dueDate != null) 'due_date': _dueDate?.toUtc().toIso8601String(),
      if (_isSale && _deliveryDate != null)
        'delivery_date': _deliveryDate?.toUtc().toIso8601String(),
      'sub_total': _subTotal,
      'tax_amount': _taxAmount,
      'discount_amount': _discountAmount,
      'total_amount': _totalAmount,
      'payment_status': status.value,
      'payment_mode': _paymentMode.value,
      'notes':
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
      'items': _lineItems.map((e) => e.toJson()).toList(),
      if (_billingAddress != null && _billingAddress!.isNotEmpty)
        'billing_address': _billingAddress,
      if (_shippingAddress != null && _shippingAddress!.isNotEmpty)
        'shipping_address': _shippingAddress,
    };

    if (hasPaidAmount && paid > 0) {
      data['paid_amount'] = paid;
    }

    final invoiceProvider = context.read<Core>().invoice;
    final success =
        _isEdit
            ? await invoiceProvider.updateInvoice(
              businessId,
              widget.existingInvoice!.id,
              data,
            )
            : await invoiceProvider.createInvoice(businessId, data);

    if (success && mounted) {
      Navigator.of(context).pop();
      if (!_isEdit) {
        context.read<Core>().business.fetchBusinesses();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSuccessToast(
          _isEdit
              ? 'Invoice updated successfully'
              : 'Invoice generated successfully',
        );
      });
    } else if (mounted) {
      showErrorToast(
        invoiceProvider.error ??
            'Failed to ${_isEdit ? 'update' : 'generate'} invoice',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'Edit ${widget.existingInvoice!.invoiceNumber}'
              : 'New ${_isSale ? "Sale" : "Purchase"} Invoice',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isSale ? _buildSaleHeaderCard() : _buildPurchaseHeaderCard(),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Products & Services',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _onAddItemDialog,
                            icon: Icon(Icons.add, size: 18),
                            label: Text('add_line_item'.tr()),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      _buildLineItemsList(),
                      const SizedBox(height: 20),

                      _buildTotalsCard(),
                      const SizedBox(height: 20),

                      _buildPaymentSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildPartyItems(List<Party> parties) {
    final filtered = parties.where((p) {
      if (_isSale) {
        return p.partyType == PartyType.customer || p.partyType == PartyType.both;
      } else {
        return p.partyType == PartyType.supplier || p.partyType == PartyType.both;
      }
    }).toList();

    if (_isSale) {
      return [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            'Walk-in / Cash Customer',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
        ...filtered.map((party) {
          return DropdownMenuItem<String>(
            value: party.id,
            child: Text(party.name, style: GoogleFonts.outfit()),
          );
        }),
      ];
    }

    return filtered.map((party) {
      return DropdownMenuItem<String>(
        value: party.id,
        child: Text(party.name, style: GoogleFonts.outfit()),
      );
    }).toList();
  }

  Widget _buildSaleHeaderCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final parties = context.select<Core, List<Party>>((c) => c.party.parties);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Customer'),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: 'Select Customer',
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              value:
                  parties.any((p) => p.id == _selectedPartyId)
                      ? _selectedPartyId
                      : null,
              items: _buildPartyItems(parties),
              onChanged: (val) {
                setState(() {
                  _selectedPartyId = val;
                  if (val != null) {
                    final party = parties.firstWhere((p) => p.id == val);
                    final billAddrs = party.billingAddresses;
                    final shipAddrs = party.shippingAddresses;
                    _billingAddress =
                        billAddrs.isNotEmpty ? billAddrs.first : '';
                    _shippingAddress =
                        shipAddrs.isNotEmpty
                            ? shipAddrs.first
                            : (_billingAddress ?? '');
                  } else {
                    _billingAddress = null;
                    _shippingAddress = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Invoice No.'),
                      AppTextField(
                        controller: _invoiceNumberController,
                        labelText: '',
                        hintText: 'INV-1001',
                        validator: (val) =>
                            Validators.validateRequired(val, 'Invoice number'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Invoice Date'),
                      _buildDateField(
                        date: _invoiceDate,
                        icon: Icons.calendar_today_outlined,
                        onTap: () => _selectDate(context, 0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Due Date'),
                      _buildDateField(
                        date: _dueDate,
                        placeholder: 'Select',
                        icon: Icons.calendar_month_outlined,
                        onTap: () => _selectDate(context, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Delivery Date'),
                      _buildDateField(
                        date: _deliveryDate,
                        placeholder: 'Today',
                        icon: Icons.local_shipping_outlined,
                        onTap: () => _selectDate(context, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _fieldLabel('Chalan No.'),
            AppTextField(
              controller: _chalanNoController,
              labelText: '',
              hintText: 'e.g. CH-2041',
              validator: (val) =>
                  Validators.validateRequired(val, 'Chalan number'),
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Bill To'),
                      _buildAddressCard(
                        address: _billingAddress,
                        onTap: () => _showAddressPicker('billing'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Ship To'),
                      _buildAddressCard(
                        address: _shippingAddress,
                        onTap: () => _showAddressPicker('shipping'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseHeaderCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final parties = context.select<Core, List<Party>>((c) => c.party.parties);
    final transportCost = _transportCost;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Supplier'),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: 'Select Supplier',
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              value:
                  parties.any((p) => p.id == _selectedPartyId)
                      ? _selectedPartyId
                      : null,
              items: _buildPartyItems(parties),
              validator: (val) =>
                  Validators.validateRequired(val, 'Supplier'),
              onChanged: (val) {
                setState(() {
                  _selectedPartyId = val;
                  if (val != null) {
                    final party = parties.firstWhere((p) => p.id == val);
                    final billAddrs = party.billingAddresses;
                    final shipAddrs = party.shippingAddresses;
                    _billingAddress =
                        billAddrs.isNotEmpty ? billAddrs.first : '';
                    _shippingAddress =
                        shipAddrs.isNotEmpty
                            ? shipAddrs.first
                            : (_billingAddress ?? '');
                  } else {
                    _billingAddress = null;
                    _shippingAddress = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Invoice No.'),
                      AppTextField(
                        controller: _invoiceNumberController,
                        labelText: '',
                        hintText: 'INV-1001',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Chalan No.'),
                      AppTextField(
                        controller: _chalanNoController,
                        labelText: '',
                        hintText: 'e.g. CH-2041',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Invoice Date'),
                      _buildDateField(
                        date: _invoiceDate,
                        icon: Icons.calendar_today_outlined,
                        onTap: () => _selectDate(context, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Due Date'),
                      _buildDateField(
                        date: _dueDate,
                        placeholder: 'Select',
                        icon: Icons.calendar_month_outlined,
                        onTap: () => _selectDate(context, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Transport Qty'),
                      AppTextField(
                        controller: _transportQtyController,
                        labelText: '',
                        hintText: 'e.g. 1',
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _calculateTotals(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Transport Rate'),
                      AppTextField(
                        controller: _transportRateController,
                        labelText: '',
                        hintText: '₹ 500',
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _calculateTotals(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (transportCost > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Cost: ',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(transportCost),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Bill To'),
                      _buildAddressCard(
                        address: _billingAddress,
                        onTap: () => _showAddressPicker('billing'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Ship To'),
                      _buildAddressCard(
                        address: _shippingAddress,
                        onTap: () => _showAddressPicker('shipping'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required DateTime? date,
    String placeholder = 'Select',
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = date != null ? Formatters.formatDate(date) : placeholder;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.gray700 : AppTheme.gray300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: date != null
                    ? theme.textTheme.bodyLarge?.color
                    : (isDark ? AppTheme.gray500 : AppTheme.gray400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.gray500,
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required String? address,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isDark
                  ? AppTheme.gray800.withValues(alpha: 0.3)
                  : AppTheme.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          ),
        ),
        child: Text(
          (address != null && address.isNotEmpty) ? address : 'Tap to set',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color:
                (address != null && address.isNotEmpty)
                    ? (isDark ? Colors.white : AppTheme.gray900)
                    : AppTheme.gray400,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showAddressPicker(String type) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final parties = context.read<Core>().party.parties;
    final party =
        _selectedPartyId != null
            ? parties.firstWhere((p) => p.id == _selectedPartyId)
            : null;

    final addresses =
        type == 'billing'
            ? (party?.billingAddresses ?? <String>[])
            : (party?.shippingAddresses ?? <String>[]);

    String customAddress = '';
    final isCustomController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.backgroundDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
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
                      type == 'billing'
                          ? 'Select Billing Address'
                          : 'Select Shipping Address',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (type == 'shipping') ...[
                      _addressOption(
                        label: 'Same as Billing Address',
                        subtitle:
                            _billingAddress != null &&
                                    _billingAddress!.isNotEmpty
                                ? _billingAddress!
                                : 'No billing address set',
                        isDark: isDark,
                        onTap: () {
                          setState(() {
                            _shippingAddress = _billingAddress;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],

                    ...addresses.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _addressOption(
                          label: 'Address ${entry.key + 1}',
                          subtitle: entry.value,
                          isDark: isDark,
                          onTap: () {
                            setState(() {
                              if (type == 'billing')
                                _billingAddress = entry.value;
                              else
                                _shippingAddress = entry.value;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                    _addressOption(
                      label: 'Enter Custom Address',
                      subtitle:
                          customAddress.isNotEmpty
                              ? customAddress
                              : 'Type a custom address',
                      isDark: isDark,
                      trailing:
                          customAddress.isEmpty
                              ? const Icon(Icons.edit_outlined, size: 18)
                              : null,
                      onTap: () {
                        setStateSheet(() {
                          customAddress =
                              customAddress.isEmpty ? '_editing' : '';
                        });
                      },
                    ),

                    if (customAddress == '_editing') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: isCustomController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter full address...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final addr = isCustomController.text.trim();
                            if (addr.isNotEmpty) {
                              setState(() {
                                if (type == 'billing')
                                  _billingAddress = addr;
                                else
                                  _shippingAddress = addr;
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],

                    if (addresses.isEmpty && customAddress != '_editing') ...[
                      const SizedBox(height: 12),
                      Text(
                        party != null
                            ? 'No saved ${type} addresses for this party.'
                            : 'Select a party first, or enter a custom address.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            );
          },
        );
      },
    );
  }

  Widget _addressOption({
    required String label,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isDark
                  ? AppTheme.gray800.withValues(alpha: 0.3)
                  : AppTheme.gray50,
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
                    label,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      );
    }

  Widget _buildLineItemsList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_lineItems.isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          ),
        ),
        child: Center(
          child: Text(
            'No items added yet. Click Add Item above.',
            style: GoogleFonts.outfit(color: isDark ? AppTheme.gray400 : AppTheme.gray500, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _lineItems.length,
      itemBuilder: (context, index) {
        final item = _lineItems[index];
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.formatCurrency(item.totalAmount),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppTheme.error),
                  onPressed: () => _onRemoveItem(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalsCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTotalRow('Sub Total', Formatters.formatCurrency(_subTotal)),
            const SizedBox(height: 8),
            _buildTotalRow(
              'Discount Total (-)',
              Formatters.formatCurrency(_discountAmount),
              color: AppTheme.success,
            ),
            const SizedBox(height: 8),
            _buildTotalRow(
              'Tax Total (+)',
              Formatters.formatCurrency(_taxAmount),
              color: AppTheme.warning,
            ),
            if (!_isSale) ...[
              const SizedBox(height: 8),
              _buildTotalRow(
                'Transport Cost (+)',
                Formatters.formatCurrency(_transportCost),
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
              ),
            ],
            const Divider(height: 20),
            _buildTotalRow(
              'Total Bill Amount',
              Formatters.formatCurrency(_totalAmount),
              isBold: true,
              fontSize: 18,
              color: isDark ? Colors.white : AppTheme.primary,
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
    double fontSize = 14,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: fontSize,
          ),
        ),
        Text(
          val,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment & Notes',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),

            // Payment Mode
            Text(
              'payment_mode'.tr(),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<PaymentMode>(
              value:
                  PaymentMode.values.contains(_paymentMode)
                      ? _paymentMode
                      : PaymentMode.cash,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
              items:
                  PaymentMode.values.map((mode) {
                    return DropdownMenuItem<PaymentMode>(
                      value: mode,
                      child: Text(
                        mode.displayName,
                        style: GoogleFonts.outfit(),
                      ),
                    );
                  }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _paymentMode = val;
                    if (val == PaymentMode.credit) {
                      _paidAmountController.text = '0';
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Paid Amount
            AppTextField(
              controller: _paidAmountController,
              labelText: 'paid_amount'.tr(),
              hintText: 'Enter cash collected/paid',
              keyboardType: TextInputType.number,
              readOnly: _paymentMode == PaymentMode.credit,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                final numValue = double.tryParse(val);
                if (numValue == null) return 'Please enter a valid number';
                if (numValue < 0) return 'Amount cannot be negative';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Notes
            AppTextField(
              controller: _notesController,
              labelText: 'notes'.tr(),
              hintText: 'Write terms, greetings, or details...',
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.gray700 : AppTheme.gray200,
            width: 1,
          ),
        ),
      ),
      child: AppButton(
        text: _isEdit ? 'Update Invoice' : 'Generate Invoice',
        isLoading: context.select<Core, bool>((c) => c.invoice.isLoading),
        onPressed: _submit,
      ),
    );
  }
}
