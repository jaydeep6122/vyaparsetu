import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/formFields.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/inputFormatters.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/screens/common/pickers.dart';
import 'package:vyaparsetu/types/item.dart';

class _LineDraft {
  Item? item;
  bool adds = true;
  final quantity = TextEditingController();
  final unitCost = TextEditingController();

  _LineDraft({this.item});

  void dispose() {
    quantity.dispose();
    unitCost.dispose();
  }
}

/// Corrects stock for damage, a physical count or opening stock.
class StockAdjustmentFormScreen extends StatefulWidget {
  final Item? item;

  const StockAdjustmentFormScreen({super.key, this.item});

  @override
  State<StockAdjustmentFormScreen> createState() => _StockAdjustmentFormScreenState();
}

class _StockAdjustmentFormScreenState extends State<StockAdjustmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  late final List<_LineDraft> _lines = [_LineDraft(item: widget.item)];
  AdjustmentReason _reason = AdjustmentReason.count;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _notes.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final stock = context.read<Core>().stock;
    final notes = _notes.text.trim();
    final navigator = Navigator.of(context);
    final saved = await stock.createAdjustment({
      'adjustment_date': apiDate(_date),
      'reason': _reason.value,
      'notes': notes.isEmpty ? null : notes,
      'lines': [
        for (final line in _lines)
          {
            'item_id': line.item!.id,
            'quantity': '${line.adds ? '' : '-'}${apiAmount(line.quantity.text)}',
            if (line.adds) 'unit_cost': apiAmount(line.unitCost.text),
          },
      ],
    });
    if (!mounted) return;
    if (saved == null) {
      showErrorToast(stock.error ?? 'error_generic'.tr());
      return;
    }
    showSuccessToast('stock_adjusted'.tr());
    navigator.pop(saved);
  }

  Widget _buildLine(int index, _LineDraft line) {
    final item = line.item;
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
              if (_lines.length > 1)
                IconButton(
                  tooltip: 'remove'.tr(),
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => setState(() => _lines.removeAt(index).dispose()),
                ),
            ],
          ),
          SelectField<Item>(
            label: 'item'.tr(),
            value: item,
            prefixIcon: Icons.inventory_2_outlined,
            labelOf: (item) => item.name,
            helperText: item == null || !item.trackStock
                ? null
                : 'in_stock_quantity'.tr(namedArgs: {
                    'quantity': Formatters.formatQuantity(item.quantityOnHand ?? 0, item.unitCode),
                  }),
            onPick: () => pickItem(context),
            onChanged: (picked) => setState(() => line.item = picked),
            validator: (picked) {
              if (picked == null) return 'validation_required'.tr(namedArgs: {'field': 'item'.tr()});
              return picked.trackStock ? null : 'item_not_tracked'.tr();
            },
          ),
          const SizedBox(height: AppTheme.spaceMd),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: true, icon: const Icon(Icons.add_rounded), label: Text('stock_add'.tr())),
              ButtonSegment(value: false, icon: const Icon(Icons.remove_rounded), label: Text('stock_remove'.tr())),
            ],
            selected: {line.adds},
            onSelectionChanged: (selection) => setState(() => line.adds = selection.first),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: line.quantity,
                  labelText: 'quantity'.tr(),
                  suffixText: item?.unitCode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter(decimals: 3)],
                  validator: Validators.quantity,
                ),
              ),
              if (line.adds) ...[
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: AppTextField(
                    controller: line.unitCost,
                    labelText: 'cost_per_unit_optional'.tr(),
                    prefixText: '₹ ',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalInputFormatter(decimals: 4)],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<Core, bool>((c) => c.stock.isSaving);

    return Scaffold(
      appBar: AppBar(title: Text('adjust_stock'.tr())),
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
              title: 'adjustment_details'.tr(),
              children: [
                ChoiceChipsField<AdjustmentReason>(
                  label: 'reason'.tr(),
                  options: AdjustmentReason.values,
                  value: _reason,
                  labelOf: (reason) => reason.displayName,
                  onChanged: (reason) => setState(() => _reason = reason),
                ),
                DateField(
                  label: 'date'.tr(),
                  value: _date,
                  lastDate: DateTime.now(),
                  onChanged: (date) => setState(() => _date = date ?? _date),
                ),
                AppTextField(
                  controller: _notes,
                  labelText: 'notes_optional'.tr(),
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLg),
            for (final (index, line) in _lines.indexed) ...[
              _buildLine(index, line),
              const SizedBox(height: AppTheme.spaceMd),
            ],
            AppButton(
              text: 'add_another_item'.tr(),
              icon: Icons.add_rounded,
              variant: AppButtonVariant.outline,
              onPressed: () => setState(() => _lines.add(_LineDraft())),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: AppButton(text: 'save_adjustment'.tr(), isLoading: isSaving, onPressed: _save),
        ),
      ),
    );
  }
}
