import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/components/formFields.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/inputFormatters.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/types/account.dart';

/// Adds or edits a cash or bank account (admins).
class AccountFormScreen extends StatefulWidget {
  final Account? account;

  const AccountFormScreen({super.key, this.account});

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Account? _account = widget.account;

  late final _name = TextEditingController(text: _account?.name);
  late final _bankName = TextEditingController(text: _account?.bankName);
  late final _accountNumber = TextEditingController(text: _account?.accountNumber);
  late final _ifsc = TextEditingController(text: _account?.ifsc);
  late final _upi = TextEditingController(text: _account?.upiId);
  late final _opening = TextEditingController(
    text: (_account?.openingBalance ?? 0) != 0
        ? Formatters.formatNumber(_account!.openingBalance, maxDecimals: 2)
        : null,
  );

  late AccountType _type = _account?.accountType ?? AccountType.bank;
  late bool _isDefault = _account?.isDefault ?? false;
  late DateTime? _openingDate = _account?.openingBalanceDate;

  bool get _isEdit => _account != null;
  bool get _isBank => _type == AccountType.bank;

  @override
  void dispose() {
    for (final controller in [_name, _bankName, _accountNumber, _ifsc, _upi, _opening]) {
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
    if (!_formKey.currentState!.validate()) return;

    final accounts = context.read<Core>().account;
    final data = <String, dynamic>{
      if (!_isEdit) 'account_type': _type.value,
      'name': _name.text.trim(),
      'bank_name': _isBank ? _text(_bankName) : null,
      'account_number': _isBank ? _text(_accountNumber) : null,
      'ifsc': _isBank ? _text(_ifsc)?.toUpperCase() : null,
      'upi_id': _isBank ? _text(_upi) : null,
      'is_default': _isDefault,
      'opening_balance': apiAmount(_opening.text) ?? '0',
      'opening_balance_date': ?(_openingDate == null ? null : apiDate(_openingDate!)),
    };

    final navigator = Navigator.of(context);
    final saved = _isEdit
        ? await accounts.updateAccount(_account!.id, data)
        : await accounts.createAccount(data);
    if (!mounted) return;
    if (saved == null) {
      showErrorToast(accounts.error ?? 'error_generic'.tr());
      return;
    }
    showSuccessToast('account_saved'.tr());
    navigator.pop(saved);
  }

  Future<void> _toggleArchive() async {
    final account = _account!;
    if (!account.isArchived) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'archive_account_title'.tr(),
        message: 'archive_account_message'.tr(namedArgs: {'name': account.name}),
        confirmText: 'archive'.tr(),
        isDestructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    final accounts = context.read<Core>().account;
    final navigator = Navigator.of(context);
    final saved = await accounts.setArchived(account.id, archived: !account.isArchived);
    if (!mounted) return;
    if (saved == null) {
      showErrorToast(accounts.error ?? 'error_generic'.tr());
      return;
    }
    navigator.pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<Core, bool>((c) => c.account.isSaving);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'edit_account'.tr() : 'add_account'.tr()),
        actions: [
          if (_isEdit)
            PopupMenuButton<String>(
              onSelected: (_) => _toggleArchive(),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'archive',
                  child: Text(_account!.isArchived ? 'restore'.tr() : 'archive'.tr()),
                ),
              ],
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          children: [
            FormSection(
              title: 'account_details'.tr(),
              children: [
                if (!_isEdit)
                  ChoiceChipsField<AccountType>(
                    options: AccountType.values,
                    value: _type,
                    labelOf: (type) => type.displayName,
                    onChanged: (type) => setState(() => _type = type),
                  ),
                AppTextField(
                  controller: _name,
                  labelText: 'account_label'.tr(),
                  hintText: _isBank ? 'account_label_hint'.tr() : 'cash_label_hint'.tr(),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, 'account_label'.tr()),
                ),
                if (_isBank) ...[
                  AppTextField(
                    controller: _bankName,
                    labelText: 'bank_name'.tr(),
                    textCapitalization: TextCapitalization.words,
                  ),
                  AppTextField(
                    controller: _accountNumber,
                    labelText: 'account_number'.tr(),
                    keyboardType: TextInputType.number,
                  ),
                  AppTextField(
                    controller: _ifsc,
                    labelText: 'ifsc'.tr(),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(11),
                    ],
                    validator: Validators.ifsc,
                  ),
                  AppTextField(
                    controller: _upi,
                    labelText: 'upi_id_optional'.tr(),
                    helperText: 'upi_id_hint'.tr(),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.upiId,
                  ),
                ],
                SwitchRow(
                  title: 'default_account'.tr(),
                  subtitle: 'default_account_hint'.tr(),
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLg),
            FormSection(
              title: 'opening_balance'.tr(),
              subtitle: 'account_opening_hint'.tr(),
              children: [
                AppTextField(
                  controller: _opening,
                  labelText: 'amount'.tr(),
                  prefixText: '₹ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [DecimalInputFormatter(allowNegative: true)],
                  validator: (v) => Validators.amount(
                    v,
                    fieldLabel: 'amount'.tr(),
                    isRequired: false,
                    allowNegative: true,
                  ),
                ),
                DateField(
                  label: 'as_of_date'.tr(),
                  value: _openingDate,
                  clearable: true,
                  helperText: 'as_of_date_hint'.tr(),
                  onChanged: (date) => setState(() => _openingDate = date),
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
            text: _isEdit ? 'save_changes'.tr() : 'save_account'.tr(),
            isLoading: isSaving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}
