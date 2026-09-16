import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
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

const _commonUnits = ['NOS', 'PCS', 'KGS', 'BAG', 'BOX', 'TON', 'LTR', 'MTR', 'SQF', 'SET'];

/// Adds or edits a product or service. Pops with the saved item.
class ItemFormScreen extends StatefulWidget {
  final Item? item;

  const ItemFormScreen({super.key, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Item? _item = widget.item;

  static String? _number(double? value, int decimals) =>
      value == null ? null : Formatters.formatNumber(value, maxDecimals: decimals);

  late final _name = TextEditingController(text: _item?.name);
  late final _unit = TextEditingController(text: _item?.unitCode ?? 'NOS');
  late final _salePrice = TextEditingController(text: _number(_item?.salePrice, 4));
  late final _purchasePrice = TextEditingController(text: _number(_item?.purchasePrice, 4));
  late final _hsn = TextEditingController(text: _item?.hsnSac);
  late final _sku = TextEditingController(text: _item?.sku);
  late final _barcode = TextEditingController(text: _item?.barcode);
  late final _lowStock = TextEditingController(text: _number(_item?.lowStockThreshold, 3));
  final _openingStock = TextEditingController();
  final _openingRate = TextEditingController();

  late ItemType _type = _item?.itemType ?? ItemType.goods;
  late bool _priceIncludesTax = _item?.priceIncludesTax ?? false;
  late bool _trackStock = _item?.trackStock ?? true;
  late TaxRate? _taxRate = _item?.taxRateId == null
      ? null
      : TaxRate(
          id: _item!.taxRateId!,
          name: '',
          rate: _item.taxRate ?? 0,
          cessRate: _item.cessRate ?? 0,
          isActive: true,
        );
  late Category? _category = _item?.categoryId == null
      ? null
      : Category(id: _item!.categoryId!, name: _item.categoryName ?? '');
  DateTime? _openingDate;

  bool get _isEdit => _item != null;
  bool get _stockTracked => _type == ItemType.goods && _trackStock;

  @override
  void dispose() {
    for (final controller in [
      _name, _unit, _salePrice, _purchasePrice, _hsn, _sku, _barcode,
      _lowStock, _openingStock, _openingRate,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      showErrorToast('form_fix_errors'.tr());
      return;
    }

    final core = context.read<Core>();
    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'item_type': _type.value,
      'category_id': _category?.id,
      'sku': _text(_sku),
      'barcode': _text(_barcode),
      'hsn_sac': _text(_hsn),
      'unit_code': _unit.text.trim().toUpperCase(),
      'sale_price': apiAmount(_salePrice.text),
      'purchase_price': apiAmount(_purchasePrice.text),
      'price_includes_tax': _priceIncludesTax,
      'tax_rate_id': _taxRate?.id,
      'track_stock': _stockTracked,
      'low_stock_threshold': _stockTracked ? apiAmount(_lowStock.text) : null,
      if (!_isEdit && _stockTracked && apiAmount(_openingStock.text) != null) ...{
        'opening_stock': apiAmount(_openingStock.text),
        'opening_stock_rate': ?apiAmount(_openingRate.text),
        'opening_stock_date': ?(_openingDate == null ? null : apiDate(_openingDate!)),
      },
    };

    final navigator = Navigator.of(context);
    final saved = _isEdit
        ? await core.item.updateItem(_item!.id, data)
        : await core.item.createItem(data);
    if (!mounted) return;
    if (saved == null) {
      showErrorToast(core.item.error ?? 'error_generic'.tr());
      return;
    }
    showSuccessToast(_isEdit ? 'item_saved'.tr() : 'item_added'.tr(namedArgs: {'name': saved.name}));
    navigator.pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<Core, bool>((c) => c.item.isSaving);
    const gap = SizedBox(height: AppTheme.spaceLg);
    final priceFormatter = DecimalInputFormatter(decimals: 4);
    final quantityFormatter = DecimalInputFormatter(decimals: 3);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'edit_item'.tr() : 'add_item'.tr())),
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
              title: 'item_details'.tr(),
              children: [
                ChoiceChipsField<ItemType>(
                  options: ItemType.values,
                  value: _type,
                  labelOf: (type) => type.displayName,
                  onChanged: (type) => setState(() => _type = type),
                ),
                AppTextField(
                  controller: _name,
                  labelText: 'item_name'.tr(),
                  textCapitalization: TextCapitalization.words,
                  autofocus: !_isEdit,
                  validator: (v) => Validators.required(v, 'item_name'.tr()),
                ),
                AppTextField(
                  controller: _unit,
                  labelText: 'unit'.tr(),
                  helperText: 'unit_hint'.tr(),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    UpperCaseTextFormatter(),
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: Validators.unitCode,
                  onChanged: (_) => setState(() {}),
                ),
                Wrap(
                  spacing: AppTheme.spaceSm,
                  runSpacing: AppTheme.spaceSm,
                  children: [
                    for (final unit in _commonUnits)
                      ChoiceChip(
                        label: Text(unit),
                        selected: _unit.text.trim().toUpperCase() == unit,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _unit.text = unit),
                      ),
                  ],
                ),
                SelectField<Category>(
                  label: 'category_optional'.tr(),
                  value: _category,
                  clearable: true,
                  prefixIcon: Icons.category_outlined,
                  labelOf: (category) => category.name,
                  onPick: () => pickCategory(context, CategoryKind.item, selectedId: _category?.id),
                  onChanged: (category) => setState(() => _category = category),
                ),
              ],
            ),
            gap,
            FormSection(
              title: 'pricing_and_tax'.tr(),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _salePrice,
                        labelText: 'sale_price'.tr(),
                        prefixText: '₹ ',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [priceFormatter],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMd),
                    Expanded(
                      child: AppTextField(
                        controller: _purchasePrice,
                        labelText: 'purchase_price'.tr(),
                        prefixText: '₹ ',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [priceFormatter],
                      ),
                    ),
                  ],
                ),
                SwitchRow(
                  title: 'price_includes_tax'.tr(),
                  subtitle: 'price_includes_tax_hint'.tr(),
                  value: _priceIncludesTax,
                  onChanged: (value) => setState(() => _priceIncludesTax = value),
                ),
                SelectField<TaxRate>(
                  label: 'gst_rate'.tr(),
                  value: _taxRate,
                  clearable: true,
                  hint: 'no_gst_rate'.tr(),
                  helperText: 'gst_rate_hint'.tr(),
                  prefixIcon: Icons.percent_rounded,
                  labelOf: taxRateLabel,
                  onPick: () => pickTaxRate(context, selectedId: _taxRate?.id),
                  onChanged: (rate) => setState(() => _taxRate = rate),
                ),
                AppTextField(
                  controller: _hsn,
                  labelText: _type == ItemType.service ? 'sac_code'.tr() : 'hsn_code'.tr(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  validator: Validators.hsnSac,
                ),
              ],
            ),
            if (_type == ItemType.goods) ...[
              gap,
              FormSection(
                title: 'stock'.tr(),
                children: [
                  SwitchRow(
                    title: 'track_stock'.tr(),
                    subtitle: 'track_stock_hint'.tr(),
                    value: _trackStock,
                    onChanged: (value) => setState(() => _trackStock = value),
                  ),
                  if (_trackStock) ...[
                    if (!_isEdit)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _openingStock,
                              labelText: 'opening_stock'.tr(),
                              suffixText: _unit.text.trim().toUpperCase(),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [quantityFormatter],
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceMd),
                          Expanded(
                            child: AppTextField(
                              controller: _openingRate,
                              labelText: 'rate_per_unit'.tr(),
                              prefixText: '₹ ',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [priceFormatter],
                            ),
                          ),
                        ],
                      ),
                    if (!_isEdit && _openingStock.text.trim().isNotEmpty)
                      DateField(
                        label: 'as_of_date'.tr(),
                        value: _openingDate,
                        clearable: true,
                        helperText: 'as_of_date_hint'.tr(),
                        onChanged: (date) => setState(() => _openingDate = date),
                      ),
                    AppTextField(
                      controller: _lowStock,
                      labelText: 'low_stock_alert'.tr(),
                      helperText: 'low_stock_alert_hint'.tr(),
                      suffixText: _unit.text.trim().toUpperCase(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [quantityFormatter],
                    ),
                  ],
                ],
              ),
            ],
            gap,
            FormSection(
              title: 'codes_optional'.tr(),
              children: [
                AppTextField(controller: _sku, labelText: 'sku'.tr(), maxLength: 50),
                AppTextField(controller: _barcode, labelText: 'barcode'.tr(), maxLength: 50),
              ],
            ),
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
            text: _isEdit ? 'save_changes'.tr() : 'save_item'.tr(),
            isLoading: isSaving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}
