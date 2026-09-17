import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/formFields.dart';
import 'package:vyaparsetu/components/statePicker.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/gst.dart';
import 'package:vyaparsetu/helpers/inputFormatters.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/screens/parties/addressSheet.dart';
import 'package:vyaparsetu/types/party.dart';

/// Adds or edits a customer, supplier or transporter. Pops with the saved
/// party.
class PartyFormScreen extends StatefulWidget {
  final Party? party;
  final PartyType initialType;

  const PartyFormScreen({super.key, this.party, this.initialType = PartyType.customer});

  @override
  State<PartyFormScreen> createState() => _PartyFormScreenState();
}

class _PartyFormScreenState extends State<PartyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Party? _party = widget.party;

  late final _name = TextEditingController(text: _party?.name);
  late final _phone = TextEditingController(text: _party?.phone);
  late final _email = TextEditingController(text: _party?.email);
  late final _gstin = TextEditingController(text: _party?.gstin);
  late final _creditDays = TextEditingController(text: _party?.creditDays?.toString());
  late final _creditLimit = TextEditingController(
    text: _party?.creditLimit == null ? null : Formatters.formatNumber(_party!.creditLimit!, maxDecimals: 2),
  );
  late final _opening = TextEditingController(
    text: (_party?.openingBalance ?? 0) > 0
        ? Formatters.formatNumber(_party!.openingBalance, maxDecimals: 2)
        : null,
  );
  late final _notes = TextEditingController(text: _party?.notes);

  late PartyType _type = _party?.partyType ?? widget.initialType;
  late PartyGstType _gstType = _party?.gstType ?? PartyGstType.unregistered;
  late String? _stateCode = _party?.stateCode;
  late BalanceType _openingType = _party?.openingBalanceType ??
      (widget.initialType.canSell ? BalanceType.receivable : BalanceType.payable);
  late DateTime? _openingDate = _party?.openingBalanceDate;
  late bool _showMore = _party != null;

  /// The whole set of saved addresses; sent back in full on save.
  late final List<PartyAddress> _addresses = [...?widget.party?.addresses];

  bool get _isEdit => _party != null;

  @override
  void dispose() {
    for (final controller in [
      _name, _phone, _email, _gstin, _creditDays, _creditLimit, _opening, _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onGstinChanged(String value) {
    final code = stateCodeFromGstin(value.trim().toUpperCase());
    if (code != null && code != _stateCode) setState(() => _stateCode = code);
  }

  String? _text(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  // ---------------------------------------------------------------- addresses

  /// Every kind that has addresses keeps exactly one default.
  void _normaliseDefaults() {
    for (final kind in AddressKind.values) {
      final indexes = [
        for (var i = 0; i < _addresses.length; i++)
          if (_addresses[i].kind == kind) i,
      ];
      if (indexes.isEmpty || indexes.any((i) => _addresses[i].isDefault)) continue;
      _addresses[indexes.first] = _addresses[indexes.first].copyWith(isDefault: true);
    }
  }

  /// Clears the default flag from every other address of [kind].
  void _clearOtherDefaults(AddressKind kind, {int? except}) {
    for (var i = 0; i < _addresses.length; i++) {
      if (i != except && _addresses[i].kind == kind && _addresses[i].isDefault) {
        _addresses[i] = _addresses[i].copyWith(isDefault: false);
      }
    }
  }

  Future<void> _addAddress(AddressKind kind) async {
    final created = await showAddressSheet(
      context,
      kind: kind,
      startAsDefault: !_addresses.any((address) => address.kind == kind),
    );
    if (created == null || !mounted) return;
    setState(() {
      if (created.isDefault) _clearOtherDefaults(created.kind);
      _addresses.add(created);
      _normaliseDefaults();
    });
  }

  Future<void> _editAddress(int index) async {
    final updated = await showAddressSheet(
      context,
      kind: _addresses[index].kind,
      initial: _addresses[index],
    );
    if (updated == null || !mounted) return;
    setState(() {
      if (updated.isDefault) _clearOtherDefaults(updated.kind, except: index);
      _addresses[index] = updated;
      _normaliseDefaults();
    });
  }

  void _makeDefault(int index) {
    setState(() {
      _clearOtherDefaults(_addresses[index].kind, except: index);
      _addresses[index] = _addresses[index].copyWith(isDefault: true);
    });
  }

  void _removeAddress(int index) {
    setState(() {
      _addresses.removeAt(index);
      _normaliseDefaults();
    });
  }

  // --------------------------------------------------------------------- save

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _showMore = true);
      showErrorToast('form_fix_errors'.tr());
      return;
    }

    final core = context.read<Core>();
    final opening = apiAmount(_opening.text);
    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'party_type': _type.value,
      'phone': _text(_phone),
      'email': _text(_email)?.toLowerCase(),
      'gst_type': _gstType.value,
      'gstin': _gstType.needsGstin ? _text(_gstin)?.toUpperCase() : null,
      'state_code': _stateCode,
      'addresses': [for (final address in _addresses) address.toJson()],
      'credit_limit': apiAmount(_creditLimit.text),
      'credit_days': int.tryParse(_creditDays.text.trim()),
      'notes': _text(_notes),
      if (_isEdit || opening != null) ...{
        'opening_balance': opening ?? '0',
        'opening_balance_type': _openingType.value,
        'opening_balance_date': ?(_openingDate == null ? null : apiDate(_openingDate!)),
      },
    };

    final navigator = Navigator.of(context);
    final saved = _isEdit
        ? await core.party.updateParty(_party!.id, data)
        : await core.party.createParty(data);
    if (!mounted) return;
    if (saved == null) {
      showErrorToast(core.party.error ?? 'error_generic'.tr());
      return;
    }
    showSuccessToast(_isEdit ? 'party_saved'.tr() : 'party_added'.tr(namedArgs: {'name': saved.name}));
    navigator.pop(saved);
  }

  // ----------------------------------------------------------------------- UI

  Widget _buildAddresses(BuildContext context) {
    return FormSection(
      title: 'addresses'.tr(),
      subtitle: 'addresses_hint'.tr(),
      children: [
        for (final kind in AddressKind.values) ...[
          Text(
            kind == AddressKind.billing ? 'billing_address'.tr() : 'shipping_address'.tr(),
            style: context.text.labelMedium,
          ),
          for (final (index, address) in _addresses.indexed)
            if (address.kind == kind)
              _AddressTile(
                address: address,
                onEdit: () => _editAddress(index),
                onMakeDefault: address.isDefault ? null : () => _makeDefault(index),
                onRemove: () => _removeAddress(index),
              ),
          if (kind == AddressKind.shipping && !_addresses.any((a) => a.kind == kind))
            Text('shipping_same_as_billing_hint'.tr(), style: context.text.bodySmall),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addAddress(kind),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                kind == AddressKind.billing
                    ? 'add_billing_address'.tr()
                    : 'add_shipping_address'.tr(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<Core, bool>((c) => c.party.isSaving);
    const gap = SizedBox(height: AppTheme.spaceLg);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'edit_party'.tr() : 'add_party'.tr())),
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
              title: 'party_details'.tr(),
              children: [
                AppTextField(
                  controller: _name,
                  labelText: 'party_name'.tr(),
                  textCapitalization: TextCapitalization.words,
                  prefixIcon: Icons.person_outline_rounded,
                  autofocus: !_isEdit,
                  validator: (v) => Validators.required(v, 'party_name'.tr()),
                ),
                ChoiceChipsField<PartyType>(
                  label: 'party_type'.tr(),
                  options: PartyType.values,
                  value: _type,
                  labelOf: (type) => type.displayName,
                  onChanged: (type) => setState(() => _type = type),
                ),
                AppTextField(
                  controller: _phone,
                  labelText: 'phone_optional'.tr(),
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: Validators.phone,
                ),
              ],
            ),
            gap,
            FormSection(
              title: 'gst_details'.tr(),
              children: [
                ChoiceChipsField<PartyGstType>(
                  options: PartyGstType.values,
                  value: _gstType,
                  labelOf: (type) => type.displayName,
                  onChanged: (type) => setState(() => _gstType = type),
                ),
                if (_gstType.needsGstin)
                  AppTextField(
                    controller: _gstin,
                    labelText: 'gstin'.tr(),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    onChanged: _onGstinChanged,
                    validator: (v) => Validators.gstin(v, isRequired: true),
                  ),
                StateSelectField(
                  value: _stateCode,
                  isRequired: false,
                  clearable: true,
                  label: 'state_optional'.tr(),
                  helperText: 'party_state_hint'.tr(),
                  onChanged: (code) => setState(() => _stateCode = code),
                  validator: (code) {
                    final fromGstin = stateCodeFromGstin(_gstin.text.trim());
                    return _gstType.needsGstin && fromGstin != null && fromGstin != code
                        ? 'validation_state_gstin_mismatch'.tr()
                        : null;
                  },
                ),
              ],
            ),
            gap,
            _buildAddresses(context),
            gap,
            FormSection(
              title: 'opening_balance'.tr(),
              subtitle: 'party_opening_hint'.tr(),
              children: [
                AppTextField(
                  controller: _opening,
                  labelText: 'amount'.tr(),
                  prefixText: '₹ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter()],
                  validator: (v) => Validators.amount(v, fieldLabel: 'amount'.tr(), isRequired: false),
                  onChanged: (_) => setState(() {}),
                ),
                if (_opening.text.trim().isNotEmpty) ...[
                  ChoiceChipsField<BalanceType>(
                    options: BalanceType.values,
                    value: _openingType,
                    labelOf: (type) => 'opening_${type.value}'.tr(),
                    onChanged: (type) => setState(() => _openingType = type),
                  ),
                  DateField(
                    label: 'as_of_date'.tr(),
                    value: _openingDate,
                    clearable: true,
                    helperText: 'as_of_date_hint'.tr(),
                    onChanged: (date) => setState(() => _openingDate = date),
                  ),
                ],
              ],
            ),
            gap,
            if (!_showMore)
              AppButton(
                text: 'more_details'.tr(),
                icon: Icons.expand_more_rounded,
                variant: AppButtonVariant.text,
                onPressed: () => setState(() => _showMore = true),
              )
            else ...[
              FormSection(
                title: 'contact_and_credit'.tr(),
                children: [
                  AppTextField(
                    controller: _email,
                    labelText: 'email_optional'.tr(),
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                    validator: (v) => Validators.email(v, isRequired: false),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _creditDays,
                          labelText: 'credit_days'.tr(),
                          helperText: 'credit_days_hint'.tr(),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      Expanded(
                        child: AppTextField(
                          controller: _creditLimit,
                          labelText: 'credit_limit'.tr(),
                          prefixText: '₹ ',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [DecimalInputFormatter()],
                        ),
                      ),
                    ],
                  ),
                ],
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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLg,
            AppTheme.spaceSm,
            AppTheme.spaceLg,
            AppTheme.spaceSm,
          ),
          child: AppButton(
            text: _isEdit ? 'save_changes'.tr() : 'save_party'.tr(),
            isLoading: isSaving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}

/// One saved address in the form: tap to edit, menu to make default or remove.
class _AddressTile extends StatelessWidget {
  final PartyAddress address;
  final VoidCallback onEdit;
  final VoidCallback? onMakeDefault;
  final VoidCallback onRemove;

  const _AddressTile({
    required this.address,
    required this.onEdit,
    required this.onMakeDefault,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            AppTheme.spaceSm,
            AppTheme.spaceXs,
            AppTheme.spaceSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            address.title,
                            style: context.text.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: AppTheme.spaceSm),
                          StatusChip(label: 'default_address'.tr(), tone: ChipTone.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(address.address.singleLine, style: context.text.bodySmall),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) {
                  switch (action) {
                    case 'default':
                      onMakeDefault?.call();
                    case 'remove':
                      onRemove();
                    default:
                      onEdit();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text('edit'.tr())),
                  if (onMakeDefault != null)
                    PopupMenuItem(value: 'default', child: Text('set_as_default'.tr())),
                  PopupMenuItem(value: 'remove', child: Text('remove'.tr())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
