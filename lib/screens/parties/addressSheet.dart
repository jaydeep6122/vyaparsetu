import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/formFields.dart';
import 'package:vyaparsetu/components/statePicker.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/gst.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/types/address.dart';
import 'package:vyaparsetu/types/party.dart';

/// Adds or edits one saved address of a party. Returns the address, or null
/// when dismissed; saving it to the server is up to the caller.
Future<PartyAddress?> showAddressSheet(
  BuildContext context, {
  required AddressKind kind,
  PartyAddress? initial,
  bool startAsDefault = false,
}) {
  return showModalBottomSheet<PartyAddress>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddressSheet(
      kind: initial?.kind ?? kind,
      initial: initial,
      startAsDefault: startAsDefault,
    ),
  );
}

class _AddressSheet extends StatefulWidget {
  final AddressKind kind;
  final PartyAddress? initial;
  final bool startAsDefault;

  const _AddressSheet({
    required this.kind,
    required this.initial,
    required this.startAsDefault,
  });

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  final _formKey = GlobalKey<FormState>();
  late final Address? _original = widget.initial?.address;

  late final _label = TextEditingController(text: widget.initial?.label);
  late final _line1 = TextEditingController(text: _original?.line1);
  late final _line2 = TextEditingController(text: _original?.line2);
  late final _city = TextEditingController(text: _original?.city);
  late final _pincode = TextEditingController(text: _original?.pincode);

  late AddressKind _kind = widget.kind;
  late String? _stateCode = stateCodeFromName(_original?.state);
  bool _stateChanged = false;
  late bool _isDefault = widget.initial?.isDefault ?? widget.startAsDefault;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    for (final controller in [_label, _line1, _line2, _city, _pincode]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _clean(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      PartyAddress(
        id: widget.initial?.id,
        kind: _kind,
        label: _clean(_label),
        isDefault: _isDefault,
        address: Address(
          line1: _clean(_line1),
          line2: _clean(_line2),
          city: _clean(_city),
          // A state typed long ago that matches no GST state is kept as is
          // unless the picker is used.
          state: _stateChanged || _stateCode != null
              ? stateNameFromCode(_stateCode)
              : _original?.state,
          pincode: _clean(_pincode),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppTheme.spaceMd);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spaceLg,
        0,
        AppTheme.spaceLg,
        MediaQuery.viewInsetsOf(context).bottom + AppTheme.spaceLg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? 'edit_address'.tr() : 'add_address'.tr(),
                style: context.text.titleLarge,
              ),
              const SizedBox(height: AppTheme.spaceLg),
              ChoiceChipsField<AddressKind>(
                label: 'address_type'.tr(),
                options: AddressKind.values,
                value: _kind,
                labelOf: (kind) => kind.displayName,
                onChanged: (kind) => setState(() => _kind = kind),
              ),
              gap,
              AppTextField(
                controller: _label,
                labelText: 'address_label'.tr(),
                hintText: 'address_label_hint'.tr(),
                textCapitalization: TextCapitalization.words,
                maxLength: 50,
              ),
              gap,
              AppTextField(
                controller: _line1,
                labelText: 'address_line1'.tr(),
                textCapitalization: TextCapitalization.words,
                autofocus: !_isEdit,
                validator: (_) => _clean(_line1) == null && _clean(_city) == null
                    ? 'validation_address_required'.tr()
                    : null,
              ),
              gap,
              AppTextField(
                controller: _line2,
                labelText: 'address_line2'.tr(),
                textCapitalization: TextCapitalization.words,
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _city,
                      labelText: 'city'.tr(),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Expanded(
                    child: AppTextField(
                      controller: _pincode,
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
              gap,
              StateSelectField(
                value: _stateCode,
                isRequired: false,
                clearable: true,
                label: 'state_optional'.tr(),
                onChanged: (code) => setState(() {
                  _stateCode = code;
                  _stateChanged = true;
                }),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              SwitchRow(
                title: 'default_address'.tr(),
                subtitle: 'default_address_hint'.tr(),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              AppButton(text: 'save'.tr(), onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
