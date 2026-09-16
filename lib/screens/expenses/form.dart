import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
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
import 'package:vyaparsetu/types/expense.dart';
import 'package:vyaparsetu/types/item.dart';

typedef _Vendor = ({String id, String name, String? stateCode});

double _round2(double value) => (value * 100).roundToDouble() / 100;

/// Records a business expense, with GST and payment when known.
class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Expense? _expense = widget.expense;

  late final _amount = TextEditingController(
    text: _expense == null ? null : Formatters.formatNumber(_expense.taxableAmount, maxDecimals: 2),
  );
  late final _notes = TextEditingController(text: _expense?.notes);
  late DateTime _date = _expense?.expenseDate ?? DateTime.now();
  late Category? _category = _expense?.categoryId == null
      ? null
      : Category(id: _expense!.categoryId!, name: _expense.categoryName ?? '');
  late _Vendor? _vendor = _expense?.partyId == null
      ? null
      : (id: _expense!.partyId!, name: _expense.partyName ?? '', stateCode: null);

  late bool _hasGst = _expense?.taxMode == TaxMode.gst;
  late TaxRate? _taxRate = _initialTaxRate();
  late bool _interState = (_expense?.igstAmount ?? 0) > 0;
  late bool _itcEligible = _expense?.itcEligible ?? true;

  bool _paidNow = true;
  PaymentMode _mode = PaymentMode.cash;
  Account? _account;

  bool get _isEdit => _expense != null;

  TaxRate? _initialTaxRate() {
    final expense = widget.expense;
    if (expense == null || expense.taxMode != TaxMode.gst || expense.taxableAmount <= 0) return null;
    final gst = expense.cgstAmount + expense.sgstAmount + expense.igstAmount;
    return TaxRate(
      id: '',
      name: '',
      rate: _round2(gst / expense.taxableAmount * 100),
      cessRate: _round2(expense.cessAmount / expense.taxableAmount * 100),
      isActive: true,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final accounts = context.read<Core>().account;
      await accounts.fetchAccounts();
      if (mounted) setState(() => _account ??= accounts.defaultAccount);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _taxable => double.tryParse(apiAmount(_amount.text) ?? '') ?? 0;

  ({double cgst, double sgst, double igst, double cess}) get _taxes {
    final rate = _taxRate;
    if (!_hasGst || rate == null) return (cgst: 0, sgst: 0, igst: 0, cess: 0);
    final gst = _round2(_taxable * rate.rate / 100);
    final cess = _round2(_taxable * rate.cessRate / 100);
    if (_interState) return (cgst: 0, sgst: 0, igst: gst, cess: cess);
    final cgst = _round2(gst / 2);
    return (cgst: cgst, sgst: _round2(gst - cgst), igst: 0, cess: cess);
  }

  double get _total {
    final t = _taxes;
    return _round2(_taxable + t.cgst + t.sgst + t.igst + t.cess);
  }

  Future<void> _pickVendor() async {
    final party = await pickParty(
      context,
      type: PartyType.supplier,
      selectedId: _vendor?.id,
      title: 'select_vendor'.tr(),
    );
    if (party == null || !mounted) return;
    final businessState = context.read<Core>().business.selectedBusiness?.stateCode;
    setState(() {
      _vendor = (id: party.id, name: party.name, stateCode: party.stateCode);
      if (party.stateCode != null && businessState != null) {
        _interState = party.stateCode != businessState;
      }
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      showErrorToast('form_fix_errors'.tr());
      return;
    }
    if (!_isEdit && _vendor == null && !_paidNow) {
      showErrorToast('expense_needs_vendor_or_payment'.tr());
      return;
    }

    final taxes = _taxes;
    final notes = _notes.text.trim();
    final data = <String, dynamic>{
      'expense_date': apiDate(_date),
      'category_id': _category?.id,
      'party_id': _vendor?.id,
      'tax_mode': _hasGst ? TaxMode.gst.value : TaxMode.nonGst.value,
      'taxable_amount': apiAmount(_amount.text),
      'cgst_amount': taxes.cgst.toStringAsFixed(2),
      'sgst_amount': taxes.sgst.toStringAsFixed(2),
      'igst_amount': taxes.igst.toStringAsFixed(2),
      'cess_amount': taxes.cess.toStringAsFixed(2),
      'itc_eligible': _hasGst && _itcEligible,
      'notes': notes.isEmpty ? null : notes,
      if (!_isEdit && _paidNow)
        'payment': {
          'account_id': _account!.id,
          'mode': _mode.value,
          'amount': _total.toStringAsFixed(2),
        },
    };

    final expenses = context.read<Core>().expense;
    final navigator = Navigator.of(context);
    final saved = _isEdit
        ? await expenses.updateExpense(_expense!.id, data)
        : await expenses.createExpense(data);
    if (!mounted) return;
    if (saved == null) {
      showErrorToast(expenses.error ?? 'error_generic'.tr());
      return;
    }
    showSuccessToast('expense_saved'.tr());
    navigator.pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final isSaving = core.expense.isSaving;
    final gstRegistered = core.business.selectedBusiness?.canIssueGstInvoices ?? false;
    final taxes = _taxes;
    const gap = SizedBox(height: AppTheme.spaceLg);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'edit_expense'.tr() : 'add_expense'.tr())),
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
              title: 'expense_details'.tr(),
              children: [
                SelectField<Category>(
                  label: 'category'.tr(),
                  value: _category,
                  clearable: true,
                  prefixIcon: Icons.label_outline_rounded,
                  hint: 'expense_category_hint'.tr(),
                  labelOf: (category) => category.name,
                  onPick: () => pickCategory(context, CategoryKind.expense, selectedId: _category?.id),
                  onChanged: (category) => setState(() => _category = category),
                ),
                AppTextField(
                  controller: _amount,
                  labelText: _hasGst ? 'amount_before_tax'.tr() : 'amount'.tr(),
                  prefixText: '₹ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter()],
                  onChanged: (_) => setState(() {}),
                  validator: (v) => Validators.amount(v, fieldLabel: 'amount'.tr(), allowZero: false),
                ),
                DateField(
                  label: 'date'.tr(),
                  value: _date,
                  lastDate: DateTime.now(),
                  onChanged: (date) => setState(() => _date = date ?? _date),
                ),
                SelectField<_Vendor>(
                  label: 'vendor_optional'.tr(),
                  value: _vendor,
                  clearable: true,
                  prefixIcon: Icons.storefront_outlined,
                  helperText: 'vendor_hint'.tr(),
                  labelOf: (vendor) => vendor.name,
                  onPick: () async {
                    await _pickVendor();
                    return null;
                  },
                  onChanged: (vendor) => setState(() => _vendor = vendor),
                ),
              ],
            ),
            if (gstRegistered || _hasGst) ...[
              gap,
              FormSection(
                title: 'gst'.tr(),
                children: [
                  SwitchRow(
                    title: 'expense_has_gst'.tr(),
                    subtitle: 'expense_has_gst_hint'.tr(),
                    value: _hasGst,
                    onChanged: (value) => setState(() => _hasGst = value),
                  ),
                  if (_hasGst) ...[
                    SelectField<TaxRate>(
                      label: 'gst_rate'.tr(),
                      value: _taxRate,
                      prefixIcon: Icons.percent_rounded,
                      labelOf: taxRateLabel,
                      onPick: () => pickTaxRate(context, selectedId: _taxRate?.id),
                      onChanged: (rate) => setState(() => _taxRate = rate),
                      validator: (rate) => rate == null
                          ? 'validation_required'.tr(namedArgs: {'field': 'gst_rate'.tr()})
                          : null,
                    ),
                    SwitchRow(
                      title: 'inter_state_purchase'.tr(),
                      subtitle: 'inter_state_purchase_hint'.tr(),
                      value: _interState,
                      onChanged: (value) => setState(() => _interState = value),
                    ),
                    SwitchRow(
                      title: 'itc_eligible'.tr(),
                      subtitle: 'itc_eligible_hint'.tr(),
                      value: _itcEligible,
                      onChanged: (value) => setState(() => _itcEligible = value),
                    ),
                    InfoRow(label: 'cgst'.tr(), value: taxes.cgst > 0 ? Formatters.formatCurrency(taxes.cgst) : null),
                    InfoRow(label: 'sgst'.tr(), value: taxes.sgst > 0 ? Formatters.formatCurrency(taxes.sgst) : null),
                    InfoRow(label: 'igst'.tr(), value: taxes.igst > 0 ? Formatters.formatCurrency(taxes.igst) : null),
                    InfoRow(label: 'cess'.tr(), value: taxes.cess > 0 ? Formatters.formatCurrency(taxes.cess) : null),
                  ],
                ],
              ),
            ],
            gap,
            FormSection(
              title: 'total'.tr(),
              trailing: Text(Formatters.formatCurrency(_total), style: context.text.titleLarge),
              children: [
                if (!_isEdit) ...[
                  SwitchRow(
                    title: 'paid_now'.tr(),
                    subtitle: 'expense_paid_now_hint'.tr(),
                    value: _paidNow,
                    onChanged: (value) => setState(() => _paidNow = value),
                  ),
                  if (_paidNow) ...[
                    ChoiceChipsField<PaymentMode>(
                      options: PaymentMode.values,
                      value: _mode,
                      labelOf: (mode) => mode.displayName,
                      onChanged: (mode) => setState(() => _mode = mode),
                    ),
                    SelectField<Account>(
                      label: 'paid_from'.tr(),
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
                ] else
                  Text('expense_edit_payment_hint'.tr(), style: context.text.bodySmall),
                AppTextField(
                  controller: _notes,
                  labelText: 'notes_optional'.tr(),
                  minLines: 1,
                  maxLines: 3,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: AppButton(
            text: _isEdit ? 'save_changes'.tr() : 'save_expense'.tr(),
            isLoading: isSaving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}
