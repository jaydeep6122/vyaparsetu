import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/validators.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<Core>().auth;
    final ok = await auth.changePassword(
      currentPassword: _current.text,
      newPassword: _new.text,
    );
    if (!mounted) return;
    if (!ok) {
      showErrorToast(auth.error ?? 'error_generic'.tr());
      return;
    }
    showSuccessToast('password_changed'.tr());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<Core, bool>((c) => c.auth.isSaving);

    return Scaffold(
      appBar: AppBar(title: Text('change_password'.tr())),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          children: [
            Text('change_password_hint'.tr(), style: context.text.bodyMedium),
            const SizedBox(height: AppTheme.space2xl),
            AppTextField(
              controller: _current,
              labelText: 'current_password'.tr(),
              isPassword: true,
              prefixIcon: Icons.lock_outline_rounded,
              autofillHints: const [AutofillHints.password],
              validator: (v) => (v == null || v.isEmpty)
                  ? 'validation_password_required'.tr()
                  : null,
            ),
            const SizedBox(height: AppTheme.spaceLg),
            AppTextField(
              controller: _new,
              labelText: 'new_password'.tr(),
              helperText: 'password_rule'.tr(),
              isPassword: true,
              prefixIcon: Icons.lock_reset_rounded,
              autofillHints: const [AutofillHints.newPassword],
              validator: Validators.password,
            ),
            const SizedBox(height: AppTheme.spaceLg),
            AppTextField(
              controller: _confirm,
              labelText: 'confirm_new_password'.tr(),
              isPassword: true,
              prefixIcon: Icons.lock_reset_rounded,
              validator: (v) => Validators.confirmPassword(v, _new.text),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: AppButton(text: 'change_password'.tr(), isLoading: isSaving, onPressed: _save),
        ),
      ),
    );
  }
}
