import 'package:flutter/material.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/datePicker.dart';
import 'package:vyaparsetu/helpers/formatters.dart';

/// A titled card grouping related form fields.
class FormSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  const FormSection({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: context.text.bodySmall),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          for (final child in children) ...[
            const SizedBox(height: AppTheme.spaceMd),
            child,
          ],
        ],
      ),
    );
  }
}

/// Read-only field that opens a picker when tapped.
class _PickerInput extends StatelessWidget {
  final String label;
  final String? valueText;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _PickerInput({
    required this.label,
    required this.valueText,
    required this.onTap,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        isEmpty: valueText == null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          errorText: errorText,
          enabled: enabled,
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: onClear,
                )
              : const Icon(Icons.expand_more_rounded),
        ),
        child: valueText == null
            ? null
            : Text(
                valueText!,
                style: context.text.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}

/// A form field whose value is chosen from a picker (party, item, state...).
class SelectField<T> extends FormField<T> {
  SelectField({
    super.key,
    required String label,
    required T? value,
    required String Function(T value) labelOf,
    required Future<T?> Function() onPick,
    ValueChanged<T?>? onChanged,
    String? hint,
    String? helperText,
    IconData? prefixIcon,
    bool clearable = false,
    super.validator,
    super.enabled,
  }) : super(
         initialValue: value,
         builder: (field) {
           final current = field.value;
           return _PickerInput(
             label: label,
             hint: hint,
             helperText: helperText,
             errorText: field.errorText,
             prefixIcon: prefixIcon,
             enabled: field.widget.enabled,
             valueText: current == null ? null : labelOf(current),
             onClear: clearable && current != null
                 ? () {
                     field.didChange(null);
                     onChanged?.call(null);
                   }
                 : null,
             onTap: () async {
               final picked = await onPick();
               if (picked == null || !field.mounted) return;
               field.didChange(picked);
               onChanged?.call(picked);
             },
           );
         },
       );

  @override
  FormFieldState<T> createState() => _SyncedFieldState<T>();
}

/// A date form field that opens the date picker.
class DateField extends FormField<DateTime> {
  DateField({
    super.key,
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    String? hint,
    String? helperText,
    IconData prefixIcon = Icons.calendar_today_outlined,
    bool clearable = false,
    super.validator,
    super.enabled,
  }) : super(
         initialValue: value,
         builder: (field) {
           final current = field.value;
           return _PickerInput(
             label: label,
             hint: hint,
             helperText: helperText,
             errorText: field.errorText,
             prefixIcon: prefixIcon,
             enabled: field.widget.enabled,
             valueText: current == null ? null : Formatters.formatDate(current),
             onClear: clearable && current != null
                 ? () {
                     field.didChange(null);
                     onChanged(null);
                   }
                 : null,
             onTap: () async {
               final picked = await pickAppDate(
                 context: field.context,
                 initialDate: current,
                 firstDate: firstDate,
                 lastDate: lastDate,
               );
               if (picked == null || !field.mounted) return;
               field.didChange(picked);
               onChanged(picked);
             },
           );
         },
       );

  @override
  FormFieldState<DateTime> createState() => _SyncedFieldState<DateTime>();
}

/// Keeps the field's value in step when the parent passes a new value (for
/// example when choosing a party fills in its state).
class _SyncedFieldState<T> extends FormFieldState<T> {
  @override
  void didUpdateWidget(covariant FormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != value) {
      setValue(widget.initialValue);
    }
  }
}

/// A row of chips to pick one option (e.g. GST / Non-GST).
class ChoiceChipsField<T> extends StatelessWidget {
  final String? label;
  final List<T> options;
  final T? value;
  final String Function(T option) labelOf;
  final ValueChanged<T> onChanged;
  final bool enabled;

  const ChoiceChipsField({
    super.key,
    this.label,
    required this.options,
    required this.value,
    required this.labelOf,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: context.text.labelMedium),
          const SizedBox(height: AppTheme.spaceSm),
        ],
        Wrap(
          spacing: AppTheme.spaceSm,
          runSpacing: AppTheme.spaceSm,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(labelOf(option)),
                selected: option == value,
                showCheckmark: false,
                onSelected: enabled ? (_) => onChanged(option) : null,
              ),
          ],
        ),
      ],
    );
  }
}

/// A labelled on/off switch with an optional explanation.
class SwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.bodyLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: context.text.bodySmall),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
