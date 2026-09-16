import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/formFields.dart';
import 'package:vyaparsetu/components/infoRow.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/inputFormatters.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/screens/common/pickers.dart';
import 'package:vyaparsetu/types/account.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/types/item.dart';
import 'package:vyaparsetu/types/party.dart';

typedef _PartyRef = ({String id, String name, String? stateCode, int? creditDays});
typedef _PayeeRef = ({String id, String name});

double _round2(double value) => (value * 100).roundToDouble() / 100;

class _LineDraft {
  String? itemId;
  final description = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final rate = TextEditingController();
  final discount = TextEditingController();
  String? hsnSac;
  String? unitCode;
  TaxRate? taxRate;

  _LineDraft();

  factory _LineDraft.fromItem(Item item, InvoiceType type) {
    final draft = _LineDraft()
      ..itemId = item.id
      ..hsnSac = item.hsnSac
      ..unitCode = item.unitCode;
    draft.description.text = item.name;
    final price = item.priceFor(type);
    if (price != null) draft.rate.text = Formatters.formatNumber(price, maxDecimals: 4);
    if (item.taxRateId != null) {
      draft.taxRate = TaxRate(
        id: item.taxRateId!,
        name: '',
        rate: item.taxRate ?? 0,
        cessRate: item.cessRate ?? 0,
        isActive: true,
      );
    }
    return draft;
  }

  factory _LineDraft.fromInvoiceLine(InvoiceLine line) {
    final draft = _LineDraft()
      ..itemId = line.itemId
      ..hsnSac = line.hsnSac
      ..unitCode = line.unitCode;
    draft.description.text = line.description;
    draft.quantity.text = Formatters.formatNumber(line.quantity);
    draft.rate.text = Formatters.formatNumber(line.unitPrice, maxDecimals: 4);
    if (line.discountPct > 0) {
      draft.discount.text = Formatters.formatNumber(line.discountPct, maxDecimals: 2);
    }
    if (line.taxRate > 0 || line.cessRate > 0) {
      draft.taxRate = TaxRate(
        id: '',
        name: '',
        rate: line.taxRate,
        cessRate: line.cessRate,
        isActive: true,
      );
    }
    return draft;
  }

  double get qty => double.tryParse(quantity.text.trim()) ?? 0;
  double get price => double.tryParse(rate.text.trim()) ?? 0;
  double get discountPct => double.tryParse(discount.text.trim()) ?? 0;

  bool get isEmpty => description.text.trim().isEmpty && itemId == null;

  void dispose() {
    description.dispose();
    quantity.dispose();
    rate.dispose();
    discount.dispose();
  }
}

class _ChargeDraft {
  String? id;
  ChargeType type = ChargeType.transport;
  ChargeBillTo billTo = ChargeBillTo.invoiceParty;
  _PayeeRef? payee;
  final description = TextEditingController();
  final vehicleNo = TextEditingController();
  final amount = TextEditingController();
  TaxRate? taxRate;

  _ChargeDraft();

  factory _ChargeDraft.fromCharge(InvoiceCharge charge) {
    final draft = _ChargeDraft()
      ..id = charge.id
      ..type = charge.chargeType
      ..billTo = charge.billTo
      ..payee = charge.payeePartyId == null
          ? null
          : (id: charge.payeePartyId!, name: charge.payeeName ?? '');
    draft.description.text = charge.description ?? '';
    draft.vehicleNo.text = charge.vehicleNo ?? '';
    draft.amount.text = Formatters.formatNumber(charge.amount, maxDecimals: 2);
    if (charge.taxRate > 0) {
      draft.taxRate = TaxRate(id: '', name: '', rate: charge.taxRate, cessRate: 0, isActive: true);
    }
    return draft;
  }

  double get value => double.tryParse(amount.text.trim()) ?? 0;

  void dispose() {
    description.dispose();
    vehicleNo.dispose();
    amount.dispose();
  }
}

/// Creates or replaces a bill: lines, charges, transport details and an
/// optional payment made at the same time.
class InvoiceFormScreen extends StatefulWidget {
  final InvoiceType type;
  final Invoice? invoice;
  final Party? party;

  const InvoiceFormScreen({
    super.key,
    this.type = InvoiceType.sale,
    this.invoice,
    this.party,
  });

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Invoice? _invoice = widget.invoice;

  late final InvoiceType _type = _invoice?.invoiceType ?? widget.type;
  late TaxMode _taxMode = _invoice?.taxMode ?? TaxMode.gst;
  late _PartyRef? _party = _initialParty();
  late DateTime _date = _invoice?.invoiceDate ?? DateTime.now();
  late DateTime? _dueDate = _invoice?.dueDate;
  late DateTime? _supplierDate = _invoice?.supplierInvoiceDate;
  late bool _priceIncludesTax = _invoice?.priceIncludesTax ?? false;
  late bool _reverseCharge = _invoice?.isReverseCharge ?? false;
  late TransportMode? _transportMode = _invoice?.transportMode;
  late DateTime? _lrDate = _invoice?.lrDate;
  late DateTime? _ewayDate = _invoice?.ewayBillDate;
  late DateTime? _deliveryDate = _invoice?.deliveryDate;

  late final _walkInName = TextEditingController(
    text: _invoice?.partyId == null ? _invoice?.partyName : null,
  );
  late final _invoiceNumber = TextEditingController(text: _invoice?.invoiceNumber);
  late final _supplierNumber = TextEditingController(text: _invoice?.supplierInvoiceNumber);
  late final _vehicleNo = TextEditingController(text: _invoice?.vehicleNo);
  late final _driverName = TextEditingController(text: _invoice?.driverName);
  late final _driverPhone = TextEditingController(text: _invoice?.driverPhone);
  late final _lrNo = TextEditingController(text: _invoice?.lrNo);
  late final _ewayNo = TextEditingController(text: _invoice?.ewayBillNo);
  late final _chalanNo = TextEditingController(text: _invoice?.chalanNo);
  late final _notes = TextEditingController(text: _invoice?.notes);
  late final _terms = TextEditingController(text: _invoice?.terms);
  final _paidAmount = TextEditingController();

  late final List<_LineDraft> _lines = _invoice == null
      ? [_LineDraft()]
      : _invoice.lines.map(_LineDraft.fromInvoiceLine).toList();
  late final List<_ChargeDraft> _charges =
      _invoice?.charges.map(_ChargeDraft.fromCharge).toList() ?? [];

  bool _showTransport = false;
  bool _showMore = false;
  bool _paidNow = false;
  PaymentMode _paymentMode = PaymentMode.cash;
  Account? _account;

  bool get _isEdit => _invoice != null;
  bool get _isGst => _taxMode == TaxMode.gst;

  _PartyRef? _initialParty() {
    final invoice = widget.invoice;
    if (invoice?.partyId != null) {
      return (
        id: invoice!.partyId!,
        name: invoice.partyName,
        stateCode: invoice.partyStateCode,
        creditDays: null,
      );
    }
    final party = widget.party;
    if (party != null) {
      return (id: party.id, name: party.name, stateCode: party.stateCode, creditDays: party.creditDays);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final core = context.read<Core>();
      if (!_isEdit) {
        setState(() => _taxMode = core.business.selectedBusiness?.defaultTaxMode ?? TaxMode.gst);
      }
      await core.account.fetchAccounts();
      if (mounted) setState(() => _account ??= core.account.defaultAccount);
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _walkInName, _invoiceNumber, _supplierNumber, _vehicleNo, _driverName,
      _driverPhone, _lrNo, _ewayNo, _chalanNo, _notes, _terms, _paidAmount,
    ]) {
      controller.dispose();
    }
    for (final line in _lines) {
      line.dispose();
    }
    for (final charge in _charges) {
      charge.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------- estimates

  double _lineTaxable(_LineDraft line) {
    var value = line.qty * line.price;
    if (line.discountPct > 0) value -= value * line.discountPct / 100;
    final rate = _isGst ? (line.taxRate?.rate ?? 0) : 0;
    if (_priceIncludesTax && rate > 0) value = value / (1 + rate / 100);
    return _round2(value);
  }

  double _lineTax(_LineDraft line) {
    if (!_isGst) return 0;
    final rate = (line.taxRate?.rate ?? 0) + (line.taxRate?.cessRate ?? 0);
    return _round2(_lineTaxable(line) * rate / 100);
  }

  double get _chargesTotal => _charges
      .where((charge) => charge.billTo == ChargeBillTo.invoiceParty)
      .fold(0.0, (sum, charge) {
        final tax = _isGst ? charge.value * (charge.taxRate?.rate ?? 0) / 100 : 0;
        return sum + _round2(charge.value + tax);
      });

  double get _paidNowAmount => double.tryParse(apiAmount(_paidAmount.text) ?? '') ?? 0;

  double get _balanceAfterPayment {
    final due = _estimatedTotal - _paidNowAmount;
    return due < 0 ? 0 : _round2(due);
  }

  /// Guards the part-payment: something must be entered, and it can never be
  /// more than the bill itself.
  String? _validatePaidNow(String? value) {
    final invalid = Validators.amount(value, fieldLabel: 'amount'.tr(), allowZero: false);
    if (invalid != null) return invalid;
    final paid = double.tryParse(apiAmount(value ?? '') ?? '') ?? 0;
    // Half a rupee of slack for round-off between the estimate and the server.
    if (paid > _estimatedTotal + 0.5) {
      return 'validation_paid_more_than_total'.tr(namedArgs: {
        'amount': Formatters.formatCurrency(_estimatedTotal),
      });
    }
    return null;
  }

  double get _estimatedTotal {
    final lines = _lines.fold(0.0, (sum, line) => sum + _lineTaxable(line) + _lineTax(line));
    final total = lines + _chargesTotal;
    final roundOff = context.read<Core>().business.selectedBusiness?.settings.roundOffInvoices ?? true;
    return roundOff ? total.roundToDouble() : _round2(total);
  }

  // ---------------------------------------------------------------- actions

  Future<void> _pickParty() async {
    final party = await pickParty(
      context,
      type: _type.isSaleSide ? PartyType.customer : PartyType.supplier,
      selectedId: _party?.id,
    );
    if (party == null || !mounted) return;
    setState(() {
      _party = (
        id: party.id,
        name: party.name,
        stateCode: party.stateCode,
        creditDays: party.creditDays,
      );
      if (party.creditDays != null && _dueDate == null) {
        _dueDate = _date.add(Duration(days: party.creditDays!));
      }
    });
  }

  Future<void> _addLine() async {
    final item = await pickItem(context, priceFor: _type);
    if (item == null || !mounted) return;
    setState(() {
      final draft = _LineDraft.fromItem(item, _type);
      if (_lines.length == 1 && _lines.first.isEmpty) {
        _lines.first.dispose();
        _lines[0] = draft;
      } else {
        _lines.add(draft);
      }
    });
  }

  Future<void> _pickLineItem(_LineDraft line) async {
    final item = await pickItem(context, priceFor: _type);
    if (item == null || !mounted) return;
    setState(() {
      line
        ..itemId = item.id
        ..hsnSac = item.hsnSac
        ..unitCode = item.unitCode;
      line.description.text = item.name;
      final price = item.priceFor(_type);
      if (price != null) line.rate.text = Formatters.formatNumber(price, maxDecimals: 4);
      if (item.taxRateId != null) {
        line.taxRate = TaxRate(
          id: item.taxRateId!,
          name: '',
          rate: item.taxRate ?? 0,
          cessRate: item.cessRate ?? 0,
          isActive: true,
        );
      }
    });
  }

  Future<void> _pickPayee(_ChargeDraft charge) async {
    final party = await pickParty(
      context,
      type: PartyType.transporter,
      selectedId: charge.payee?.id,
      title: 'select_transporter'.tr(),
    );
    if (party == null || !mounted) return;
    setState(() => charge.payee = (id: party.id, name: party.name));
  }

  String? _text(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Map<String, dynamic> _payload(InvoiceStatus status) {
    final lines = _lines.where((line) => !line.isEmpty).toList();
    return {
      'invoice_type': _type.value,
      'tax_mode': _taxMode.value,
      if (status != InvoiceStatus.cancelled) 'status': status.value,
      'invoice_number': _text(_invoiceNumber),
      'invoice_date': apiDate(_date),
      'due_date': _dueDate == null ? null : apiDate(_dueDate!),
      'supplier_invoice_number': _text(_supplierNumber),
      'supplier_invoice_date': _supplierDate == null ? null : apiDate(_supplierDate!),
      'party_id': _party?.id,
      'party_name': _party == null ? _text(_walkInName) : null,
      'is_reverse_charge': _isGst && _reverseCharge,
      'price_includes_tax': _priceIncludesTax,
      'vehicle_no': _text(_vehicleNo),
      'driver_name': _text(_driverName),
      'driver_phone': _text(_driverPhone),
      'transport_mode': _transportMode?.value,
      'lr_no': _text(_lrNo),
      'lr_date': _lrDate == null ? null : apiDate(_lrDate!),
      'eway_bill_no': _text(_ewayNo),
      'eway_bill_date': _ewayDate == null ? null : apiDate(_ewayDate!),
      'chalan_no': _text(_chalanNo),
      'delivery_date': _deliveryDate == null ? null : apiDate(_deliveryDate!),
      'notes': _text(_notes),
      'terms': _text(_terms),
      'lines': [
        for (final line in lines)
          {
            'item_id': line.itemId,
            'description': line.description.text.trim(),
            'hsn_sac': line.hsnSac,
            'quantity': apiAmount(line.quantity.text),
            'unit_code': line.unitCode,
            'unit_price': apiAmount(line.rate.text),
            'discount_pct': ?apiAmount(line.discount.text),
            if (_isGst) ...{
              'tax_rate': (line.taxRate?.rate ?? 0).toStringAsFixed(2),
              'cess_rate': (line.taxRate?.cessRate ?? 0).toStringAsFixed(2),
            },
          },
      ],
      'charges': [
        for (final charge in _charges.where((c) => c.value > 0))
          {
            if (charge.id != null) 'id': charge.id,
            'charge_type': charge.type.value,
            'description': _text(charge.description),
            'bill_to': charge.billTo.value,
            'payee_party_id': charge.payee?.id,
            'vehicle_no': _text(charge.vehicleNo),
            'amount': apiAmount(charge.amount.text),
            if (_isGst) 'tax_rate': (charge.taxRate?.rate ?? 0).toStringAsFixed(2),
          },
      ],
      if (!_isEdit && _paidNow)
        'payment': {
          'account_id': _account!.id,
          'mode': _paymentMode.value,
          // Exactly what was entered; the form refuses an empty amount.
          'amount': apiAmount(_paidAmount.text),
        },
    };
  }

  Future<void> _save(InvoiceStatus status) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      showErrorToast('form_fix_errors'.tr());
      return;
    }
    if (_lines.every((line) => line.isEmpty)) {
      showErrorToast('invoice_needs_line'.tr());
      return;
    }
    for (final charge in _charges) {
      if (charge.billTo == ChargeBillTo.payeeOnly && charge.payee == null) {
        showErrorToast('charge_needs_payee'.tr());
        return;
      }
    }

    final invoices = context.read<Core>().invoice;
    final navigator = Navigator.of(context);
    final data = _payload(status);
    final saved = _isEdit
        ? await invoices.updateInvoice(_invoice!.id, data)
        : await invoices.createInvoice(data);
    if (!mounted) return;
    if (saved == null) {
      showErrorToast(invoices.error ?? 'error_generic'.tr());
      return;
    }
    showSuccessToast(
      status == InvoiceStatus.draft
          ? 'draft_saved'.tr()
          : 'bill_saved'.tr(namedArgs: {'number': saved.invoiceNumber}),
    );
    navigator.pop(saved);
  }

  // ------------------------------------------------------------------- UI

  Widget _buildLine(int index, _LineDraft line) {
    final taxable = _lineTaxable(line);
    final tax = _lineTax(line);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'line_number'.tr(namedArgs: {'number': '${index + 1}'}),
                  style: context.text.labelMedium,
                ),
              ),
              IconButton(
                tooltip: 'select_item'.tr(),
                icon: const Icon(Icons.inventory_2_outlined),
                onPressed: () => _pickLineItem(line),
              ),
              if (_lines.length > 1)
                IconButton(
                  tooltip: 'remove'.tr(),
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => setState(() => _lines.removeAt(index).dispose()),
                ),
            ],
          ),
          AppTextField(
            controller: line.description,
            labelText: 'item_or_description'.tr(),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'validation_required'.tr(namedArgs: {'field': 'item_or_description'.tr()})
                : null,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: line.quantity,
                  labelText: 'quantity'.tr(),
                  suffixText: line.unitCode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter(decimals: 3)],
                  onChanged: (_) => setState(() {}),
                  validator: Validators.quantity,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: AppTextField(
                  controller: line.rate,
                  labelText: 'rate'.tr(),
                  prefixText: '₹ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter(decimals: 4)],
                  onChanged: (_) => setState(() {}),
                  validator: (v) => Validators.amount(v, fieldLabel: 'rate'.tr(), allowZero: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: line.discount,
                  labelText: 'discount_percent'.tr(),
                  suffixText: '%',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter()],
                  onChanged: (_) => setState(() {}),
                  validator: Validators.percent,
                ),
              ),
              if (_isGst) ...[
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: SelectField<TaxRate>(
                    label: 'gst_rate'.tr(),
                    value: line.taxRate,
                    clearable: true,
                    labelOf: taxRateLabel,
                    onPick: () => pickTaxRate(context, selectedId: line.taxRate?.id),
                    onChanged: (rate) => setState(() => line.taxRate = rate),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _isGst
                  ? 'line_total_with_tax'.tr(namedArgs: {
                      'taxable': Formatters.formatCurrency(taxable),
                      'total': Formatters.formatCurrency(taxable + tax),
                    })
                  : Formatters.formatCurrency(taxable),
              style: context.text.titleSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharge(int index, _ChargeDraft charge) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('charge'.tr(), style: context.text.labelMedium)),
              IconButton(
                tooltip: 'remove'.tr(),
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => setState(() => _charges.removeAt(index).dispose()),
              ),
            ],
          ),
          ChoiceChipsField<ChargeType>(
            options: ChargeType.values,
            value: charge.type,
            labelOf: (type) => type.displayName,
            onChanged: (type) => setState(() => charge.type = type),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: charge.amount,
                  labelText: 'amount'.tr(),
                  prefixText: '₹ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter()],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_isGst) ...[
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: SelectField<TaxRate>(
                    label: 'gst_rate'.tr(),
                    value: charge.taxRate,
                    clearable: true,
                    labelOf: taxRateLabel,
                    onPick: () => pickTaxRate(context, selectedId: charge.taxRate?.id),
                    onChanged: (rate) => setState(() => charge.taxRate = rate),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          AppTextField(
            controller: charge.description,
            labelText: 'description_optional'.tr(),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          AppTextField(
            controller: charge.vehicleNo,
            labelText: 'vehicle_number'.tr(),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(20)],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          SelectField<_PayeeRef>(
            label: 'transporter_optional'.tr(),
            value: charge.payee,
            clearable: true,
            prefixIcon: Icons.local_shipping_outlined,
            helperText: 'transporter_hint'.tr(),
            labelOf: (payee) => payee.name,
            onPick: () async {
              await _pickPayee(charge);
              return null;
            },
            onChanged: (payee) => setState(() => charge.payee = payee),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          ChoiceChipsField<ChargeBillTo>(
            label: 'who_pays'.tr(),
            options: ChargeBillTo.values,
            value: charge.billTo,
            labelOf: (billTo) => billTo.displayName,
            onChanged: (billTo) => setState(() => charge.billTo = billTo),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final isSaving = core.invoice.isSaving;
    final canChooseTaxMode = core.business.selectedBusiness?.canIssueGstInvoices ?? false;
    const gap = SizedBox(height: AppTheme.spaceLg);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'edit_bill'.tr() : _type.displayName),
        actions: [
          if (!_isEdit)
            TextButton(
              onPressed: isSaving ? null : () => _save(InvoiceStatus.draft),
              child: Text('save_draft'.tr()),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLg,
            AppTheme.spaceSm,
            AppTheme.spaceLg,
            AppTheme.space3xl,
          ),
          children: [
            FormSection(
              title: 'bill_details'.tr(),
              children: [
                if (canChooseTaxMode)
                  ChoiceChipsField<TaxMode>(
                    label: 'bill_type'.tr(),
                    options: TaxMode.values,
                    value: _taxMode,
                    labelOf: (mode) => mode.displayName,
                    onChanged: (mode) => setState(() => _taxMode = mode),
                  ),
                SelectField<_PartyRef>(
                  label: _type.isSaleSide ? 'customer'.tr() : 'supplier'.tr(),
                  value: _party,
                  clearable: true,
                  prefixIcon: Icons.person_outline_rounded,
                  labelOf: (party) => party.name,
                  onPick: () async {
                    await _pickParty();
                    return null;
                  },
                  onChanged: (party) => setState(() => _party = party),
                ),
                if (_party == null)
                  AppTextField(
                    controller: _walkInName,
                    labelText: 'walk_in_name'.tr(),
                    helperText: 'walk_in_hint'.tr(),
                    textCapitalization: TextCapitalization.words,
                  ),
                DateField(
                  label: 'date'.tr(),
                  value: _date,
                  onChanged: (date) => setState(() => _date = date ?? _date),
                ),
                DateField(
                  label: 'due_date_optional'.tr(),
                  value: _dueDate,
                  clearable: true,
                  helperText: 'due_date_hint'.tr(),
                  onChanged: (date) => setState(() => _dueDate = date),
                ),
                if (!_type.isSaleSide) ...[
                  AppTextField(
                    controller: _supplierNumber,
                    labelText: 'supplier_bill_number'.tr(),
                    maxLength: 50,
                  ),
                  DateField(
                    label: 'supplier_bill_date'.tr(),
                    value: _supplierDate,
                    clearable: true,
                    onChanged: (date) => setState(() => _supplierDate = date),
                  ),
                ],
              ],
            ),
            gap,
            Row(
              children: [
                Expanded(child: Text('items'.tr(), style: context.text.titleMedium)),
                TextButton.icon(
                  onPressed: _addLine,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('add_item'.tr()),
                ),
              ],
            ),
            for (final (index, line) in _lines.indexed) ...[
              _buildLine(index, line),
              const SizedBox(height: AppTheme.spaceSm),
            ],
            AppButton(
              text: 'add_line'.tr(),
              icon: Icons.playlist_add_rounded,
              variant: AppButtonVariant.outline,
              onPressed: () => setState(() => _lines.add(_LineDraft())),
            ),
            gap,
            FormSection(
              title: 'transport_details'.tr(),
              subtitle: 'transport_hint'.tr(),
              trailing: IconButton(
                icon: Icon(_showTransport ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                onPressed: () => setState(() => _showTransport = !_showTransport),
              ),
              children: [
                if (_showTransport) ...[
                  AppTextField(
                    controller: _vehicleNo,
                    labelText: 'vehicle_number'.tr(),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(20)],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _driverName,
                          labelText: 'driver_name'.tr(),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      Expanded(
                        child: AppTextField(
                          controller: _driverPhone,
                          labelText: 'driver_phone'.tr(),
                          keyboardType: TextInputType.phone,
                          validator: Validators.phone,
                        ),
                      ),
                    ],
                  ),
                  ChoiceChipsField<TransportMode>(
                    label: 'transport_mode'.tr(),
                    options: TransportMode.values,
                    value: _transportMode,
                    labelOf: (mode) => mode.displayName,
                    onChanged: (mode) => setState(
                      () => _transportMode = _transportMode == mode ? null : mode,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _lrNo,
                          labelText: 'lr_number'.tr(),
                          maxLength: 50,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      Expanded(
                        child: DateField(
                          label: 'lr_date'.tr(),
                          value: _lrDate,
                          clearable: true,
                          onChanged: (date) => setState(() => _lrDate = date),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _ewayNo,
                          labelText: 'eway_bill_number'.tr(),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            return value.isEmpty || value.length == 12
                                ? null
                                : 'validation_eway_bill'.tr();
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      Expanded(
                        child: DateField(
                          label: 'eway_bill_date'.tr(),
                          value: _ewayDate,
                          clearable: true,
                          onChanged: (date) => setState(() => _ewayDate = date),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _chalanNo,
                          labelText: 'challan_number'.tr(),
                          maxLength: 50,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      Expanded(
                        child: DateField(
                          label: 'delivery_date'.tr(),
                          value: _deliveryDate,
                          clearable: true,
                          onChanged: (date) => setState(() => _deliveryDate = date),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            gap,
            Row(
              children: [
                Expanded(child: Text('other_charges'.tr(), style: context.text.titleMedium)),
                TextButton.icon(
                  onPressed: () => setState(() => _charges.add(_ChargeDraft())),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('add_charge'.tr()),
                ),
              ],
            ),
            if (_charges.isEmpty)
              Text('charges_hint'.tr(), style: context.text.bodySmall)
            else
              for (final (index, charge) in _charges.indexed) ...[
                _buildCharge(index, charge),
                const SizedBox(height: AppTheme.spaceSm),
              ],
            gap,
            if (!_isEdit)
              FormSection(
                title: 'payment'.tr(),
                children: [
                  SwitchRow(
                    title: _type.paymentDirection == PaymentDirection.paymentIn
                        ? 'received_payment_now'.tr()
                        : 'paid_now'.tr(),
                    subtitle: 'paid_now_hint'.tr(),
                    value: _paidNow,
                    // The amount is never filled in automatically: a part
                    // payment must not turn into a full one by accident.
                    onChanged: (value) => setState(() => _paidNow = value),
                  ),
                  if (_paidNow) ...[
                    AppTextField(
                      controller: _paidAmount,
                      labelText: _type.paymentDirection == PaymentDirection.paymentIn
                          ? 'amount_received_now'.tr()
                          : 'amount_paid_now'.tr(),
                      helperText: 'bill_total_helper'.tr(namedArgs: {
                        'amount': Formatters.formatCurrency(_estimatedTotal),
                      }),
                      prefixText: '₹ ',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [DecimalInputFormatter()],
                      onChanged: (_) => setState(() {}),
                      validator: _validatePaidNow,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(
                          () => _paidAmount.text = _estimatedTotal.toStringAsFixed(2),
                        ),
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: Text('pay_full_amount'.tr()),
                      ),
                    ),
                    InfoRow(
                      label: 'balance_after_payment'.tr(),
                      value: Formatters.formatCurrency(_balanceAfterPayment),
                    ),
                    ChoiceChipsField<PaymentMode>(
                      options: PaymentMode.values,
                      value: _paymentMode,
                      labelOf: (mode) => mode.displayName,
                      onChanged: (mode) => setState(() => _paymentMode = mode),
                    ),
                    SelectField<Account>(
                      label: _type.paymentDirection == PaymentDirection.paymentIn
                          ? 'deposit_to'.tr()
                          : 'paid_from'.tr(),
                      value: _account,
                      prefixIcon: Icons.account_balance_wallet_outlined,
                      labelOf: (account) => account.name,
                      onPick: () => pickAccount(context, selectedId: _account?.id),
                      onChanged: (account) => setState(() => _account = account),
                      validator: (account) => account == null
                          ? 'validation_required'.tr(namedArgs: {'field': 'account'.tr()})
                          : null,
                    ),
                  ],
                ],
              ),
            gap,
            FormSection(
              title: 'more_options'.tr(),
              trailing: IconButton(
                icon: Icon(_showMore ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                onPressed: () => setState(() => _showMore = !_showMore),
              ),
              children: [
                if (_showMore) ...[
                  if (_isGst) ...[
                    SwitchRow(
                      title: 'prices_include_tax'.tr(),
                      subtitle: 'prices_include_tax_hint'.tr(),
                      value: _priceIncludesTax,
                      onChanged: (value) => setState(() => _priceIncludesTax = value),
                    ),
                    SwitchRow(
                      title: 'reverse_charge'.tr(),
                      subtitle: 'reverse_charge_hint'.tr(),
                      value: _reverseCharge,
                      onChanged: (value) => setState(() => _reverseCharge = value),
                    ),
                  ],
                  AppTextField(
                    controller: _invoiceNumber,
                    labelText: 'bill_number_optional'.tr(),
                    helperText: 'bill_number_hint'.tr(),
                    maxLength: 50,
                  ),
                  AppTextField(
                    controller: _notes,
                    labelText: 'notes_optional'.tr(),
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  AppTextField(
                    controller: _terms,
                    labelText: 'terms_optional'.tr(),
                    helperText: 'terms_on_bill_hint'.tr(),
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.spaceLg),
            AppCard(
              child: Column(
                children: [
                  InfoRow(
                    label: 'estimated_total'.tr(),
                    emphasize: true,
                    value: Formatters.formatCurrency(_estimatedTotal),
                  ),
                  Text('estimate_note'.tr(), style: context.text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: AppButton(
            text: _isEdit ? 'save_changes'.tr() : 'save_bill'.tr(),
            isLoading: isSaving,
            onPressed: () => _save(InvoiceStatus.finalized),
          ),
        ),
      ),
    );
  }
}
