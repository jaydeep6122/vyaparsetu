import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vyaparsetu/components/formFields.dart';
import 'package:vyaparsetu/components/pickerSheet.dart';
import 'package:vyaparsetu/helpers/gst.dart';

/// Picks a GST state; returns its 2-digit code.
Future<String?> pickGstState(BuildContext context, {String? selected}) async {
  final picked = await showPickerSheet<MapEntry<String, String>>(
    context: context,
    title: 'select_state'.tr(),
    options: gstStates,
    labelOf: (state) => state.value,
    subtitleOf: (state) => 'state_code_label'.tr(namedArgs: {'code': state.key}),
    isSelected: (state) => state.key == selected,
    searchHint: 'search_state'.tr(),
  );
  return picked?.key;
}

/// Form field for a GST state code.
class StateSelectField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? label;
  final String? helperText;
  final bool isRequired;
  final bool clearable;

  /// Extra check once a state is chosen (e.g. that it matches the GSTIN).
  final String? Function(String code)? validator;

  const StateSelectField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.helperText,
    this.isRequired = true,
    this.clearable = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final fieldLabel = label ?? 'state'.tr();
    return SelectField<String>(
      label: fieldLabel,
      value: value,
      helperText: helperText,
      prefixIcon: Icons.place_outlined,
      clearable: clearable,
      labelOf: (code) => stateNameFromCode(code) ?? code,
      onPick: () => pickGstState(context, selected: value),
      onChanged: onChanged,
      validator: (code) {
        if (code == null) {
          return isRequired
              ? 'validation_required'.tr(namedArgs: {'field': fieldLabel})
              : null;
        }
        return validator?.call(code);
      },
    );
  }
}
