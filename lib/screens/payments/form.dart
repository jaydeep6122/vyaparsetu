import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/formFields.dart';
import 'package:vyaparsetu/components/infoRow.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
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
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/types/payment.dart';
import 'package:vyaparsetu/types/reports.dart';

typedef PartyRef = ({String id, String name});

/// Warns that money not linked to a bill becomes an advance, which flips the
/// party's balance the other way.
class _AdvanceNotice extends StatelessWidget {
  final double amount;
  final String partyName;

  const _AdvanceNotice({required this.amount, required this.partyName});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.colors.warningSoft,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: context.colors.warning),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Text(
              'advance_warning'.tr(namedArgs: {
                'amount': Formatters.formatCurrency(amount),
                'name': partyName,
              }),
              style: context.text.bodySmall?.copyWith(color: context.colors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

/// A bill, freight charge or expense a payment can settle.
class _OpenDocument {
  final String kind;
  final String id;
  final String number;
  final String label;
  final DateTime? date;
  final double outstanding;

  const _OpenDocument({
    required this.kind,
    required this.id,
    required this.number,
    required this.label,
    required this.date,
    required this.outstanding,
  });

  factory _OpenDocument.fromOutstanding(OutstandingDocument doc) => _OpenDocument(
    kind: doc.kind,
    id: doc.id,
    number: doc.number,
    label: _labelFor(doc.kind, doc.documentType),
    date: doc.documentDate,
    outstanding: doc.outstanding,
  );

  factory _OpenDocument.fromInvoice(Invoice invoice) => _OpenDocument(
    kind: 'invoice',
    id: invoice.id,
    number: invoice.invoiceNumber,
    label: invoice.invoiceType.displayName,
    date: invoice.invoiceDate,
    outstanding: invoice.outstanding,
  );

  static String _labelFor(String kind, String documentType) => switch (kind) {
    'charge' => 'freight_charge'.tr(),
    'expense' => 'expense'.tr(),
    _ => InvoiceType.fromString(documentType).displayName,
  };

  String get key => '$kind:$id';

  String get field => switch (kind) {
    'charge' => 'invoice_charge_id',
    'expense' => 'expense_id',
    _ => 'invoice_id',
  };

  _OpenDocument plus(double amount) => _OpenDocument(
    kind: kind,
    id: id,
    number: number,
    label: label,
    date: date,
    outstanding: outstanding + amount,
  );
}

/// Records money received or paid, and which bills it settles.
class PaymentFormScreen extends StatefulWidget {
  final PaymentDirection direction;
  final Payment? payment;
  final Party? party;

  /// Settle this bill: fills in its party and the amount still due.
  final Invoice? invoice;

  const PaymentFormScreen({
    super.key,
    this.direction = PaymentDirection.paymentIn,
    this.payment,
    this.party,
    this.invoice,
  });

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Payment? _payment = widget.payment;

  static String _plain(double value) => Formatters.formatNumber(value, maxDecimals: 2);

  late PaymentDirection _direction = _payment?.paymentType ?? widget.direction;
  late PartyRef? _party = _initialParty();
  Account? _account;
  bool _accountChosen = false;
  late PaymentMode _mode = _payment?.mode ?? PaymentMode.cash;
  late DateTime _date = _payment?.paymentDate ?? DateTime.now();
  late DateTime? _chequeDate = _payment?.chequeDate;
  late final _amount = TextEditingController(
    text: _payment != null
        ? _plain(_payment.amount)
        : widget.invoice != null
        ? _plain(widget.invoice!.outstanding)
        : null,
  );
  late final _reference = TextEditingController(text: _payment?.referenceNo);
  late final _chequeNo = TextEditingController(text: _payment?.chequeNo);
  late final _notes = TextEditingController(text: _payment?.notes);

  List<_OpenDocument>? _documents;
  final Map<String, TextEditingController> _allocations = {};

  bool get _isEdit => _payment != null;

  PartyRef? _initialParty() {
    final payment = widget.payment;
    if (payment?.partyId != null) return (id: payment!.partyId!, name: payment.partyName ?? '');
    if (widget.party != null) return (id: widget.party!.id, name: widget.party!.name);
    final invoice = widget.invoice;
    if (invoice?.partyId != null) return (id: invoice!.partyId!, name: invoice.partyName);
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) _direction = widget.invoice!.invoiceType.paymentDirection;
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final accounts = context.read<Core>().account;
    await accounts.fetchAccounts();
    if (!mounted) return;
    setState(() {
      _account = _payment != null
          ? accounts.activeAccounts.where((a) => a.id == _payment.accountId).firstOrNull
          : _suggestAccount(accounts.activeAccounts, accounts.defaultAccount);
      _accountChosen = _payment != null;
    });
    await _loadDocuments();
  }

  @override
  void dispose() {
    for (final controller in [_amount, _reference, _chequeNo, _notes, ..._allocations.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  Account? _suggestAccount(List<Account> active, Account? fallback) {
    if (_mode == PaymentMode.cash) return fallback;
    return active.where((a) => a.accountType == AccountType.bank).firstOrNull ?? fallback;
  }

  TextEditingController _allocationFor(String key) =>
      _allocations.putIfAbsent(key, TextEditingController.new);

  double _parse(String text) => double.tryParse(apiAmount(text) ?? '') ?? 0;

  double get _amountValue => _parse(_amount.text);

  double get _allocated => (_documents ?? const <_OpenDocument>[])
      .fold(0.0, (sum, doc) => sum + _parse(_allocations[doc.key]?.text ?? ''));

  Future<void> _loadDocuments() async {
    for (final controller in _allocations.values) {
      controller.dispose();
    }
    _allocations.clear();
    setState(() => _documents = null);

    final core = context.read<Core>();
    final party = _party;
    final invoice = widget.invoice;
    var documents = <_OpenDocument>[];

    if (party != null) {
      if (core.can(MemberRole.accountant)) {
        final type = _direction == PaymentDirection.paymentIn
            ? OutstandingType.receivable
            : OutstandingType.payable;
        final open = await core.report.outstandingForParty(type, party.id);
        documents = open.map(_OpenDocument.fromOutstanding).toList();
      } else {
        final invoices = await core.invoice.invoicesForParty(party.id, unpaidOnly: true);
        documents = invoices
            .where((i) => i.invoiceType.paymentDirection == _direction)
            .map(_OpenDocument.fromInvoice)
            .toList();
      }
    }

    // When editing, what this payment already settles is still open to it.
    final payment = _payment;
    if (payment != null && payment.partyId == party?.id) {
      for (final allocation in payment.allocations) {
        final kind = allocation.invoiceChargeId != null
            ? 'charge'
            : allocation.expenseId != null
            ? 'expense'
            : 'invoice';
        final id = allocation.invoiceChargeId ?? allocation.expenseId ?? allocation.invoiceId ?? '';
        final index = documents.indexWhere((d) => d.kind == kind && d.id == id);
        if (index >= 0) {
          documents[index] = documents[index].plus(allocation.amount);
        } else {
          documents.add(_OpenDocument(
            kind: kind,
            id: id,
            number: allocation.documentNumber ?? '',
            label: _OpenDocument._labelFor(kind, ''),
            date: allocation.documentDate,
            outstanding: allocation.amount,
          ));
        }
        _allocationFor('$kind:$id').text = _plain(allocation.amount);
      }
    }

    // Settling a specific bill (including a walk-in cash sale).
    if (payment == null && invoice != null) {
      if (!documents.any((d) => d.kind == 'invoice' && d.id == invoice.id)) {
        documents.add(_OpenDocument.fromInvoice(invoice));
      }
      _allocationFor('invoice:${invoice.id}').text = _plain(invoice.outstanding);
    }

    documents.sort((a, b) => (a.date ?? DateTime(2100)).compareTo(b.date ?? DateTime(2100)));
    if (!mounted) return;
    setState(() => _documents = documents);
  }

  void _settleOldestFirst() {
    var remaining = _amountValue;
    for (final doc in _documents ?? const <_OpenDocument>[]) {
      final share = math.min(remaining, doc.outstanding);
      _allocationFor(doc.key).text = share > 0.004 ? _plain(share) : '';
      remaining = math.max(0, remaining - share);
    }
    setState(() {});
  }

  Future<void> _pickParty() async {
    final party = await pickParty(context, selectedId: _party?.id);
    if (party == null || !mounted) return;
    setState(() => _party = (id: party.id, name: party.name));
    await _loadDocuments();
  }

  void _setMode(PaymentMode mode) {
    final accounts = context.read<Core>().account;
    setState(() {
      _mode = mode;
      if (!_accountChosen) {
        _account = _suggestAccount(accounts.activeAccounts, accounts.defaultAccount);
      }
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      showErrorToast('form_fix_errors'.tr());
      return;
    }
    if (_allocated > _amountValue + 0.004) {
      showErrorToast('allocation_exceeds_amount'.tr());
      return;
    }

    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final isCheque = _mode == PaymentMode.cheque;
    final data = <String, dynamic>{
      if (!_isEdit) 'payment_type': _direction.value,
      'payment_date': apiDate(_date),
      'party_id': _party?.id,
      'account_id': _account!.id,
      'mode': _mode.value,
      'amount': apiAmount(_amount.text),
      'reference_no': text(_reference),
      'cheque_no': isCheque ? text(_chequeNo) : null,
      'cheque_date': isCheque && _chequeDate != null ? apiDate(_chequeDate!) : null,
      'notes': text(_notes),
      'allocations': [
        for (final doc in _documents ?? const <_OpenDocument>[])
          if (_parse(_allocations[doc.key]?.text ?? '') > 0)
            {doc.field: doc.id, 'amount': apiAmount(_allocations[doc.key]!.text)},
      ],
    };

    final payments = context.read<Core>().payment;
    final navigator = Navigator.of(context);
    final saved = _isEdit
        ? await payments.updatePayment(_payment!.id, data)
        : await payments.createPayment(data);
    if (!mounted) return;
    if (saved == null) {
      showErrorToast(payments.error ?? 'error_generic'.tr());
      return;
    }
    showSuccessToast(
      saved.isIn ? 'payment_received_saved'.tr() : 'payment_made_saved'.tr(),
    );
    navigator.pop(saved);
  }

  Widget _buildAllocations(BuildContext context) {
    final documents = _documents;
    if (_party == null && widget.invoice == null) {
      return Text('choose_party_to_settle'.tr(), style: context.text.bodySmall);
    }
    if (documents == null) return const LinearProgressIndicator();
    if (documents.isEmpty) {
      // Nothing to settle: the money stays on the party as an advance, which
      // shows up as a balance owed the other way. Say so plainly.
      if (_amountValue <= 0.004) {
        return Text('no_open_bills'.tr(), style: context.text.bodySmall);
      }
      return _AdvanceNotice(
        amount: _amountValue,
        partyName: _party?.name ?? '',
      );
    }

    final unallocated = _amountValue - _allocated;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _settleOldestFirst,
            icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
            label: Text('settle_oldest_first'.tr()),
          ),
        ),
        for (final doc in documents)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${doc.label} · ${doc.number}', style: context.text.titleSmall),
                      Text(
                        [
                          if (doc.date != null) Formatters.formatDate(doc.date!),
                          'due_amount'.tr(namedArgs: {
                            'amount': Formatters.formatCurrency(doc.outstanding),
                          }),
                        ].join(' · '),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMd),
                SizedBox(
                  width: 128,
                  child: AppTextField(
                    controller: _allocationFor(doc.key),
                    labelText: '',
                    hintText: '0',
                    prefixText: '₹ ',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.amount(
                      v,
                      fieldLabel: 'amount'.tr(),
                      isRequired: false,
                      max: doc.outstanding,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Divider(),
        InfoRow(label: 'settles_bills'.tr(), value: Formatters.formatCurrency(_allocated)),
        if (unallocated > 0.004) ...[
          InfoRow(
            label: 'kept_as_advance'.tr(),
            value: Formatters.formatCurrency(unallocated),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          _AdvanceNotice(amount: unallocated, partyName: _party?.name ?? ''),
        ],
        if (unallocated < -0.004)
          Text(
            'allocation_exceeds_amount'.tr(),
            style: context.text.bodySmall?.copyWith(color: context.colors.danger),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<Core, bool>((c) => c.payment.isSaving);
    final isIn = _direction == PaymentDirection.paymentIn;
    const gap = SizedBox(height: AppTheme.spaceLg);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'edit_payment'.tr()
              : isIn
              ? 'payment_in_title'.tr()
              : 'payment_out_title'.tr(),
        ),
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
            if (!_isEdit && widget.invoice == null) ...[
              SegmentedButton<PaymentDirection>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: PaymentDirection.paymentIn,
                    icon: const Icon(Icons.call_received_rounded),
                    label: Text('money_in'.tr()),
                  ),
                  ButtonSegment(
                    value: PaymentDirection.paymentOut,
                    icon: const Icon(Icons.call_made_rounded),
                    label: Text('money_out'.tr()),
                  ),
                ],
                selected: {_direction},
                onSelectionChanged: (selection) {
                  setState(() => _direction = selection.first);
                  _loadDocuments();
                },
              ),
              gap,
            ],
            FormSection(
              title: 'payment_details'.tr(),
              children: [
                SelectField<PartyRef>(
                  label: isIn ? 'received_from'.tr() : 'paid_to'.tr(),
                  value: _party,
                  clearable: !_isEdit,
                  prefixIcon: Icons.person_outline_rounded,
                  helperText: 'payment_party_hint'.tr(),
                  labelOf: (party) => party.name,
                  onPick: () async {
                    await _pickParty();
                    return null;
                  },
                  onChanged: (party) {
                    setState(() => _party = party);
                    _loadDocuments();
                  },
                ),
                AppTextField(
                  controller: _amount,
                  labelText: 'amount'.tr(),
                  prefixText: '₹ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter()],
                  onChanged: (_) => setState(() {}),
                  validator: (v) => Validators.amount(v, fieldLabel: 'amount'.tr(), allowZero: false),
                ),
                DateField(
                  label: 'date'.tr(),
                  value: _date,
                  onChanged: (date) => setState(() => _date = date ?? _date),
                ),
                ChoiceChipsField<PaymentMode>(
                  label: 'payment_mode'.tr(),
                  options: PaymentMode.values,
                  value: _mode,
                  labelOf: (mode) => mode.displayName,
                  onChanged: _setMode,
                ),
                SelectField<Account>(
                  label: isIn ? 'deposit_to'.tr() : 'paid_from'.tr(),
                  value: _account,
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  labelOf: (account) => account.name,
                  onPick: () => pickAccount(context, selectedId: _account?.id),
                  onChanged: (account) => setState(() {
                    _account = account;
                    _accountChosen = true;
                  }),
                  validator: (account) => account == null
                      ? 'validation_required'.tr(namedArgs: {'field': 'account'.tr()})
                      : null,
                ),
                if (_mode == PaymentMode.cheque) ...[
                  AppTextField(
                    controller: _chequeNo,
                    labelText: 'cheque_number'.tr(),
                    keyboardType: TextInputType.number,
                    maxLength: 20,
                  ),
                  DateField(
                    label: 'cheque_date'.tr(),
                    value: _chequeDate,
                    clearable: true,
                    onChanged: (date) => setState(() => _chequeDate = date),
                  ),
                ] else if (_mode != PaymentMode.cash)
                  AppTextField(
                    controller: _reference,
                    labelText: 'reference_optional'.tr(),
                    helperText: 'reference_hint'.tr(),
                    maxLength: 100,
                  ),
              ],
            ),
            gap,
            FormSection(
              title: 'settle_bills'.tr(),
              subtitle: 'settle_bills_hint'.tr(),
              children: [_buildAllocations(context)],
            ),
            gap,
            FormSection(
              title: 'notes'.tr(),
              children: [
                AppTextField(
                  controller: _notes,
                  labelText: 'notes_optional'.tr(),
                  minLines: 2,
                  maxLines: 4,
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
            text: _isEdit ? 'save_changes'.tr() : 'save_payment'.tr(),
            isLoading: isSaving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}
