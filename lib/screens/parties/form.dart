import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/formFields.dart';
import 'package:vyaparsetu/components/statePicker.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/gst.dart';
import 'package:vyaparsetu/helpers/inputFormatters.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/types/address.dart';
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
  late final _billLine1 = TextEditingController(text: _party?.billingAddress?.line1);
  late final _billLine2 = TextEditingController(text: _party?.billingAddress?.line2);
  late final _billCity = TextEditingController(text: _party?.billingAddress?.city);
  late final _billPincode = TextEditingController(text: _party?.billingAddress?.pincode);
  late final _shipLine1 = TextEditingController(text: _party?.shippingAddress?.line1);
  late final _shipLine2 = TextEditingController(text: _party?.shippingAddress?.line2);
  late final _shipCity = TextEditingController(text: _party?.shippingAddress?.city);
  late final _shipPincode = TextEditingController(text: _party?.shippingAddress?.pincode);
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
  late bool _sameShipping = _party?.shippingAddress?.isEmpty ?? true;
  late BalanceType _openingType = _party?.openingBalanceType ??
      (widget.initialType.canSell ? BalanceType.receivable : BalanceType.payable);
  late DateTime? _openingDate = _party?.openingBalanceDate;
  late bool _showMore = _party != null;

  bool get _isEdit => _party != null;

  @override
  void dispose() {
    for (final controller in [
      _name, _phone, _email, _gstin, _billLine1, _billLine2, _billCity,
      _billPincode, _shipLine1, _shipLine2, _shipCity, _shipPincode,
      _creditDays, _creditLimit, _opening, _notes,
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

  Map<String, dynamic>? _address(
    TextEditingController line1,
    TextEditingController line2,
    TextEditingController city,
    TextEditingController pincode,
  ) {
    final address = Address(
      line1: line1.text,
      line2: line2.text,
      city: city.text,
      pincode: pincode.text,
    );
    if (address.isEmpty) return null;
    return Address(
      line1: line1.text,
      line2: line2.text,
      city: city.text,
      state: stateNameFromCode(_stateCode),
      pincode: pincode.text,
    ).toJson();
  }

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
      'billing_address': _address(_billLine1, _billLine2, _billCity, _billPincode),
      'shipping_address': _sameShipping
          ? null
          : _address(_shipLine1, _shipLine2, _shipCity, _shipPincode),
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

  List<Widget> _addressFields(
    TextEditingController line1,
    TextEditingController line2,
    TextEditingController city,
    TextEditingController pincode,
  ) {
    return [
      AppTextField(
        controller: line1,
        labelText: 'address_line1'.tr(),
        textCapitalization: TextCapitalization.words,
      ),
      AppTextField(
        controller: line2,
        labelText: 'address_line2'.tr(),
        textCapitalization: TextCapitalization.words,
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField(
              controller: city,
              labelText: 'city'.tr(),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: AppTextField(
              controller: pincode,
              labelText: 'pincode'.tr(),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: Validators.pincode,
            ),
          ),
        ],
      ),
    ];
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
                title: 'billing_address'.tr(),
                children: _addressFields(_billLine1, _billLine2, _billCity, _billPincode),
              ),
              gap,
              FormSection(
                title: 'shipping_address'.tr(),
                children: [
                  SwitchRow(
                    title: 'same_as_billing'.tr(),
                    value: _sameShipping,
                    onChanged: (value) => setState(() => _sameShipping = value),
                  ),
                  if (!_sameShipping)
                    ..._addressFields(_shipLine1, _shipLine2, _shipCity, _shipPincode),
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
