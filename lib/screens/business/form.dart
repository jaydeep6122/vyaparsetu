import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/components/formFields.dart';
import 'package:vyaparsetu/components/imagePickerWidget.dart';
import 'package:vyaparsetu/components/signaturePadWidget.dart';
import 'package:vyaparsetu/components/statePicker.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/gst.dart';
import 'package:vyaparsetu/helpers/imageData.dart';
import 'package:vyaparsetu/helpers/inputFormatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/screens/auth/login.dart';
import 'package:vyaparsetu/screens/auth/sessionRouter.dart';
import 'package:vyaparsetu/screens/business/joinBusiness.dart';
import 'package:vyaparsetu/screens/home/home.dart';
import 'package:vyaparsetu/types/address.dart';
import 'package:vyaparsetu/types/business.dart';

/// Creates a business, or edits [business] (admins only).
class BusinessFormScreen extends StatefulWidget {
  final Business? business;

  /// First business after sign-up: no back button, offers to join instead.
  final bool isOnboarding;

  const BusinessFormScreen({super.key, this.business, this.isOnboarding = false});

  @override
  State<BusinessFormScreen> createState() => _BusinessFormScreenState();
}

class _BusinessFormScreenState extends State<BusinessFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Business? _business = widget.business;

  late final _name = TextEditingController(text: _business?.name);
  late final _legalName = TextEditingController(text: _business?.legalName);
  late final _gstin = TextEditingController(text: _business?.gstin);
  late final _pan = TextEditingController(text: _business?.pan);
  late final _phone = TextEditingController(text: _business?.phone);
  late final _email = TextEditingController(text: _business?.email);
  late final _line1 = TextEditingController(text: _business?.address?.line1);
  late final _line2 = TextEditingController(text: _business?.address?.line2);
  late final _city = TextEditingController(text: _business?.address?.city);
  late final _pincode = TextEditingController(text: _business?.address?.pincode);
  late final _terms = TextEditingController(text: _business?.settings.invoiceTerms);
  final _openingCash = TextEditingController();
  final _bankLabel = TextEditingController();
  final _bankName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _ifsc = TextEditingController();
  final _upi = TextEditingController();
  final _bankOpening = TextEditingController();

  late GstRegistrationType _registration =
      _business?.gstRegistrationType ?? GstRegistrationType.regular;
  late String? _stateCode =
      (_business?.stateCode.isEmpty ?? true) ? null : _business!.stateCode;
  late bool _roundOff = _business?.settings.roundOffInvoices ?? true;
  late String? _logoUri = _business?.logoUrl;
  late String? _signatureUri = _business?.signatureUrl;
  bool _processingLogo = false;
  bool _addBank = false;
  bool _signing = false;

  bool get _isEdit => _business != null;
  bool get _isRegistered => _registration != GstRegistrationType.unregistered;

  @override
  void dispose() {
    for (final controller in [
      _name, _legalName, _gstin, _pan, _phone, _email, _line1, _line2, _city,
      _pincode, _terms, _openingCash, _bankLabel, _bankName, _accountNumber,
      _ifsc, _upi, _bankOpening,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onGstinChanged(String value) {
    final gstin = value.trim().toUpperCase();
    final code = stateCodeFromGstin(gstin);
    if (gstin.length == 15 && _pan.text.trim().isEmpty) {
      _pan.text = gstin.substring(2, 12);
    }
    if (code != null && code != _stateCode) setState(() => _stateCode = code);
  }

  Future<void> _onLogoPicked(File file) async {
    setState(() => _processingLogo = true);
    final result = await imageFileToDataUri(file);
    if (!mounted) return;
    setState(() {
      _processingLogo = false;
      if (result.uri != null) _logoUri = result.uri;
    });
    if (result.uri == null) {
      showErrorToast(
        result.failure == ImageFailure.unreadable
            ? 'image_unreadable'.tr()
            : 'image_too_large'.tr(),
      );
    }
  }

  /// The pad hands back PNG bytes; refuse anything the server would reject.
  void _onSignatureSaved(Uint8List? bytes) {
    if (bytes == null) {
      _signatureUri = null;
      return;
    }
    final uri = pngBytesToDataUri(bytes);
    if (uri.length > maxImageDataUriLength) {
      showErrorToast('image_too_large'.tr());
      return;
    }
    _signatureUri = uri;
  }

  String? _text(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Map<String, dynamic> _payload() {
    return {
      'name': _name.text.trim(),
      'legal_name': _text(_legalName),
      'gst_registration_type': _registration.value,
      'gstin': _isRegistered ? _text(_gstin)?.toUpperCase() : null,
      'pan': _text(_pan)?.toUpperCase(),
      'state_code': _stateCode,
      'address': Address(
        line1: _line1.text,
        line2: _line2.text,
        city: _city.text,
        state: stateNameFromCode(_stateCode),
        pincode: _pincode.text,
      ).toJson(),
      'phone': _text(_phone),
      'email': _text(_email)?.toLowerCase(),
      'logo_url': _logoUri,
      'signature_url': _signatureUri,
      'settings': {'round_off_invoices': _roundOff, 'invoice_terms': _text(_terms)},
      if (!_isEdit) ...{
        'opening_cash_balance': ?apiAmount(_openingCash.text),
        if (_addBank)
          'bank_account': {
            'name': _bankLabel.text.trim(),
            'bank_name': _text(_bankName),
            'account_number': _text(_accountNumber),
            'ifsc': _text(_ifsc)?.toUpperCase(),
            'upi_id': _text(_upi),
            'opening_balance': ?apiAmount(_bankOpening.text),
          },
      },
    };
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      showErrorToast('form_fix_errors'.tr());
      return;
    }

    final core = context.read<Core>();
    final navigator = Navigator.of(context);

    if (_isEdit) {
      final saved = await core.business.updateBusiness(_payload());
      if (!mounted) return;
      if (saved == null) {
        showErrorToast(core.business.error ?? 'error_generic'.tr());
        return;
      }
      showSuccessToast('business_saved'.tr());
      navigator.pop();
    } else {
      final created = await core.business.createBusiness(_payload());
      if (!mounted) return;
      if (created == null) {
        showErrorToast(core.business.error ?? 'error_generic'.tr());
        return;
      }
      showSuccessToast('business_created'.tr(namedArgs: {'name': created.name}));
      navigator.pushAndRemoveUntil(getPageRoute(const HomeScreen()), (_) => false);
    }
  }

  Future<void> _archive() async {
    final core = context.read<Core>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'archive_business_title'.tr(),
      message: 'archive_business_message'.tr(namedArgs: {'name': _business!.name}),
      confirmText: 'archive'.tr(),
      isDestructive: true,
      icon: Icons.archive_outlined,
    );
    if (!confirmed || !mounted) return;
    if (await core.business.archiveBusiness()) {
      if (mounted) await openAfterSignIn(context);
    } else {
      showErrorToast(core.business.error ?? 'error_generic'.tr());
    }
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await context.read<Core>().auth.logout();
    navigator.pushAndRemoveUntil(getPageRoute(const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<Core, bool>((c) => c.business.isSaving);
    final isOwner = context.select<Core, bool>((c) => c.can(MemberRole.owner));
    const gap = SizedBox(height: AppTheme.spaceLg);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isOnboarding,
        title: Text(
          _isEdit
              ? 'business_profile'.tr()
              : widget.isOnboarding
              ? 'setup_business_title'.tr()
              : 'add_business'.tr(),
        ),
        actions: [
          if (widget.isOnboarding)
            IconButton(
              tooltip: 'sign_out'.tr(),
              icon: const Icon(Icons.logout_rounded),
              onPressed: _logout,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: _signing ? const NeverScrollableScrollPhysics() : null,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLg,
            AppTheme.spaceSm,
            AppTheme.spaceLg,
            AppTheme.space3xl,
          ),
          children: [
            if (widget.isOnboarding) ...[
              Text(
                'setup_business_subtitle'.tr(),
                style: context.text.bodyLarge?.copyWith(color: context.colors.inkSecondary),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              AppButton(
                text: 'join_with_invite'.tr(),
                icon: Icons.group_add_outlined,
                variant: AppButtonVariant.outline,
                onPressed: () => showJoinBusinessDialog(context),
              ),
              gap,
            ],
            FormSection(
              title: 'business_details'.tr(),
              children: [
                AppTextField(
                  controller: _name,
                  labelText: 'business_name'.tr(),
                  textCapitalization: TextCapitalization.words,
                  prefixIcon: Icons.storefront_outlined,
                  validator: (v) => Validators.required(v, 'business_name'.tr()),
                ),
                AppTextField(
                  controller: _legalName,
                  labelText: 'legal_name_optional'.tr(),
                  helperText: 'legal_name_hint'.tr(),
                  textCapitalization: TextCapitalization.words,
                ),
                AppTextField(
                  controller: _phone,
                  labelText: 'phone_optional'.tr(),
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: Validators.phone,
                ),
                AppTextField(
                  controller: _email,
                  labelText: 'email_optional'.tr(),
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: (v) => Validators.email(v, isRequired: false),
                ),
              ],
            ),
            gap,
            FormSection(
              title: 'gst_details'.tr(),
              children: [
                ChoiceChipsField<GstRegistrationType>(
                  label: 'gst_registration'.tr(),
                  options: GstRegistrationType.values,
                  value: _registration,
                  labelOf: (type) => type.displayName,
                  onChanged: (type) => setState(() => _registration = type),
                ),
                if (_isRegistered)
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
                  )
                else
                  Text(
                    'unregistered_business_hint'.tr(),
                    style: context.text.bodySmall,
                  ),
                StateSelectField(
                  value: _stateCode,
                  helperText: 'business_state_hint'.tr(),
                  onChanged: (code) => setState(() => _stateCode = code),
                  validator: (code) {
                    final fromGstin = stateCodeFromGstin(_gstin.text.trim());
                    return _isRegistered && fromGstin != null && fromGstin != code
                        ? 'validation_state_gstin_mismatch'.tr()
                        : null;
                  },
                ),
                AppTextField(
                  controller: _pan,
                  labelText: 'pan_optional'.tr(),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    UpperCaseTextFormatter(),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: Validators.pan,
                ),
              ],
            ),
            gap,
            FormSection(
              title: 'address'.tr(),
              children: [
                AppTextField(
                  controller: _line1,
                  labelText: 'address_line1'.tr(),
                  textCapitalization: TextCapitalization.words,
                ),
                AppTextField(
                  controller: _line2,
                  labelText: 'address_line2'.tr(),
                  textCapitalization: TextCapitalization.words,
                ),
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
              ],
            ),
            if (!_isEdit) ...[
              gap,
              FormSection(
                title: 'opening_balances'.tr(),
                subtitle: 'opening_balances_hint'.tr(),
                children: [
                  AppTextField(
                    controller: _openingCash,
                    labelText: 'cash_in_hand'.tr(),
                    prefixText: '₹ ',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalInputFormatter()],
                    validator: (v) => Validators.amount(
                      v,
                      fieldLabel: 'cash_in_hand'.tr(),
                      isRequired: false,
                    ),
                  ),
                  SwitchRow(
                    title: 'add_bank_account'.tr(),
                    subtitle: 'add_bank_account_hint'.tr(),
                    value: _addBank,
                    onChanged: (value) => setState(() => _addBank = value),
                  ),
                  if (_addBank) ...[
                    AppTextField(
                      controller: _bankLabel,
                      labelText: 'account_label'.tr(),
                      hintText: 'account_label_hint'.tr(),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => Validators.required(v, 'account_label'.tr()),
                    ),
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
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.upiId,
                    ),
                    AppTextField(
                      controller: _bankOpening,
                      labelText: 'balance_in_bank'.tr(),
                      prefixText: '₹ ',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [DecimalInputFormatter()],
                      validator: (v) => Validators.amount(
                        v,
                        fieldLabel: 'balance_in_bank'.tr(),
                        isRequired: false,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            gap,
            FormSection(
              title: 'branding'.tr(),
              subtitle: 'branding_hint'.tr(),
              children: [
                ImagePickerWidget(
                  label: 'logo'.tr(),
                  initialImageUrl: _logoUri,
                  onImageSelected: _onLogoPicked,
                  onImageRemoved: () => setState(() => _logoUri = null),
                ),
                if (_processingLogo) const LinearProgressIndicator(),
                SignaturePadWidget(
                  label: 'signature'.tr(),
                  initialSignatureUrl: _business?.signatureUrl,
                  onSignatureSaved: _onSignatureSaved,
                  onDrawStart: () => setState(() => _signing = true),
                  onDrawEnd: () => setState(() => _signing = false),
                ),
              ],
            ),
            gap,
            FormSection(
              title: 'invoice_settings'.tr(),
              children: [
                SwitchRow(
                  title: 'round_off_totals'.tr(),
                  subtitle: 'round_off_totals_hint'.tr(),
                  value: _roundOff,
                  onChanged: (value) => setState(() => _roundOff = value),
                ),
                AppTextField(
                  controller: _terms,
                  labelText: 'terms_optional'.tr(),
                  helperText: 'terms_hint'.tr(),
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
            if (_isEdit && isOwner) ...[
              const SizedBox(height: AppTheme.space2xl),
              AppButton(
                text: 'archive_business'.tr(),
                icon: Icons.archive_outlined,
                variant: AppButtonVariant.text,
                onPressed: _archive,
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
            text: _isEdit ? 'save_changes'.tr() : 'create_business'.tr(),
            isLoading: isSaving,
            onPressed: _processingLogo ? null : _save,
          ),
        ),
      ),
    );
  }
}
