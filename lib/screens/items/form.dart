import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/item.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/core/Core.dart';

class ItemFormScreen extends StatefulWidget {
  final Item? existingItem;
  const ItemFormScreen({super.key, this.existingItem});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Item? _existingItem;
  bool _isEdit = false;
  bool _isInitialized = false;

  final _nameController = TextEditingController();
  final _hsnController = TextEditingController();

  String _measuringUnit = 'pcs';

  final List<String> _units = ['pcs', 'kg', 'g', 'l', 'ml', 'box', 'packet', 'meter', 'pair'];

  void _showUnitPicker() {
    final customController = TextEditingController();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      showDragHandle: false,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('measuring_unit'.tr(),
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._units.map((unit) {
                  final isSelected = _measuringUnit == unit;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? AppTheme.primary : (isDark ? Colors.white38 : AppTheme.slate500),
                      size: 22,
                    ),
                    title: Text(unit, style: GoogleFonts.outfit(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                    trailing: isSelected ? Icon(Icons.check, color: AppTheme.primary, size: 20) : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() => _measuringUnit = unit);
                    },
                  );
                }),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text('add_custom_unit'.tr(),
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : AppTheme.slate500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customController,
                        decoration: InputDecoration(
                          hintText: 'unit_hint'.tr(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                        ),
                        style: GoogleFonts.outfit(fontSize: 14),
                        onSubmitted: (val) {
                          final trimmed = val.trim();
                          if (trimmed.isNotEmpty) {
                            setState(() {
                              _units.add(trimmed);
                              _measuringUnit = trimmed;
                            });
                            Navigator.of(ctx).pop();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () {
                        final trimmed = customController.text.trim();
                        if (trimmed.isEmpty) return;
                        setState(() {
                          _units.add(trimmed);
                          _measuringUnit = trimmed;
                        });
                        Navigator.of(ctx).pop();
                      },
                      child: Text('add'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('cancel'.tr()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => customController.dispose());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      final args = widget.existingItem;
      if (args is Item) {
        _existingItem = args;
        _isEdit = true;
        _initForm();
      }
    }
  }

  void _initForm() {
    if (_existingItem == null) return;
    final item = _existingItem!;
    _nameController.text = item.name;
    _hsnController.text = item.hsnCode ?? '';

    if (_units.contains(item.measuringUnit)) {
      _measuringUnit = item.measuringUnit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hsnController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId == null) return;

    final itemModule = context.read<Core>().item;

    final data = {
      'name': _nameController.text.trim(),
      'hsn_code': _hsnController.text.trim().isEmpty ? null : _hsnController.text.trim(),
      'measuring_unit': _measuringUnit,
    };

    if (_isEdit) {
      final success = await itemModule.updateItem(businessId, _existingItem!.id, data);
      if (success && mounted) {
        Navigator.of(context).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showSuccessToast('item_updated'.tr());
        });
      } else if (mounted) {
        showErrorToast(itemModule.error ?? 'failed_save_item'.tr());
      }
    } else {
      final createdItem = await itemModule.createItem(businessId, data);
      if (createdItem != null && mounted) {
        Navigator.of(context).pop(createdItem);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showSuccessToast('item_created'.tr());
        });
      } else if (mounted) {
        showErrorToast(itemModule.error ?? 'failed_save_item'.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'edit_item'.tr() : 'add_item'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Name
                AppTextField(
                  controller: _nameController,
                  labelText: 'item_name'.tr(),
                  hintText: 'enter_item_name'.tr(),
                  prefixIcon: Icons.shopping_bag_outlined,
                  validator: (val) => Validators.validateRequired(val, 'Item name'),
                ),
                const SizedBox(height: 16),

                // HSN Code
                AppTextField(
                  controller: _hsnController,
                  labelText: 'hsn_code'.tr(),
                  hintText: 'e.g. 8471',
                  prefixIcon: Icons.tag,
                ),
                const SizedBox(height: 16),

                // Measuring Unit Selection
                Text(
                  'measuring_unit'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _showUnitPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      suffixIcon: const Icon(Icons.arrow_forward_ios, size: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    child: Text(
                      _measuringUnit,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                AppButton(
                  text: 'save'.tr(),
                  isLoading: context.select<Core, bool>((c) => c.item.isLoading),
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
