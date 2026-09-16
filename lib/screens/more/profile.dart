import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/avatar.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _user = context.read<Core>().auth.user;
  late final _name = TextEditingController(text: _user?.name);
  late final _phone = TextEditingController(text: _user?.phone);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<Core>().auth;
    final phone = _phone.text.trim();
    final ok = await auth.updateProfile(name: _name.text.trim(), phone: phone.isEmpty ? null : phone);
    if (!mounted) return;
    if (!ok) {
      showErrorToast(auth.error ?? 'error_generic'.tr());
      return;
    }
    showSuccessToast('profile_saved'.tr());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<Core, bool>((c) => c.auth.isSaving);

    return Scaffold(
      appBar: AppBar(title: Text('my_profile'.tr())),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          children: [
            Center(child: InitialsAvatar(name: _user?.name ?? '?', size: 72)),
            const SizedBox(height: AppTheme.space2xl),
            AppTextField(
              controller: _name,
              labelText: 'your_name'.tr(),
              textCapitalization: TextCapitalization.words,
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => Validators.required(v, 'your_name'.tr()),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            AppTextField(
              controller: _phone,
              labelText: 'mobile_optional'.tr(),
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: Validators.phone,
            ),
            const SizedBox(height: AppTheme.spaceLg),
            AppTextField(
              labelText: 'email'.tr(),
              initialValue: _user?.email,
              enabled: false,
              prefixIcon: Icons.mail_outline_rounded,
              helperText: 'email_cannot_change'.tr(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: AppButton(text: 'save_changes'.tr(), isLoading: isSaving, onPressed: _save),
        ),
      ),
    );
  }
}
