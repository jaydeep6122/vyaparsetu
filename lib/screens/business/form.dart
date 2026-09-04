import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image/image.dart' as img;
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/imagePickerWidget.dart';
import 'package:vyaparsetu/components/signaturePadWidget.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/home/home.dart';
import 'package:vyaparsetu/core/Core.dart';

class BusinessFormScreen extends StatefulWidget {
  final Business? existingBusiness;
  const BusinessFormScreen({super.key, this.existingBusiness});

  @override
  State<BusinessFormScreen> createState() => _BusinessFormScreenState();
}

class _BusinessFormScreenState extends State<BusinessFormScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isGoingNext = true;

  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();
  final _step4FormKey = GlobalKey<FormState>();

  late List<GlobalKey<FormState>> _formKeys;

  Business? _existingBusiness;
  bool _isEdit = false;
  bool _canScroll = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _prefixController = TextEditingController();

  final _bankNameController = TextEditingController();
  final _accNoController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiIdController = TextEditingController();

  String _financialYear = '2026-2027';

  File? _logoFile;
  String? _logoUrlBase64;
  String? _signatureUrlBase64;

  @override
  void initState() {
    super.initState();
    _formKeys = [_step1FormKey, _step2FormKey, _step3FormKey, _step4FormKey];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = widget.existingBusiness;
    if (args is Business) {
      _existingBusiness = args;
      _isEdit = true;
      _initForm();
    } else {
      if (_prefixController.text.isEmpty) {
        _prefixController.text = 'INV';
      }
    }
  }

  void _initForm() {
    if (_existingBusiness == null) return;
    final b = _existingBusiness!;
    _nameController.text = b.name;
    _emailController.text = b.email ?? '';
    _phoneController.text = b.phone ?? '';
    _addressController.text = b.address;
    _cityController.text = b.city;
    _stateController.text = b.state;
    _pincodeController.text = b.pincode;
    _gstinController.text = b.gstin ?? '';
    _panController.text = b.panNumber ?? '';
    _prefixController.text = b.invoicePrefix;

    _bankNameController.text = b.bankName ?? '';
    _accNoController.text = b.accountNumber ?? '';
    _ifscController.text = b.ifscCode ?? '';
    _upiIdController.text = b.upiId ?? '';

    _financialYear = b.financialYear;
    _logoUrlBase64 = b.logoUrl;
    _signatureUrlBase64 = b.signatureUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _prefixController.dispose();
    _bankNameController.dispose();
    _accNoController.dispose();
    _ifscController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<bool> _showTermsBottomSheet(
    Map<String, dynamic> data,
    bool isEdit, {
    String? businessId,
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool accepted = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final isLoading = context.select<Core, bool>(
              (c) => c.business.isLoading,
            );
            final sheetHeight = MediaQuery.of(context).size.height * 0.8;

            return Container(
              height: sheetHeight,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.backgroundDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'terms_conditions'.tr(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: isDark ? Colors.white : AppTheme.gray900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.gray800.withValues(alpha: 0.3)
                                  : AppTheme.gray50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.gray700
                                    : AppTheme.gray200,
                              ),
                            ),
                            child: Text(
                              'The GST details you provide must be your own. If you enter someone else\'s GST or commit fraud using this app, the app owner is not responsible. All legal action will be taken against you.',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                height: 1.5,
                                color: isDark
                                    ? AppTheme.gray300
                                    : AppTheme.gray700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'privacy_policy'.tr(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: isDark ? Colors.white : AppTheme.gray900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.gray800.withValues(alpha: 0.3)
                                  : AppTheme.gray50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.gray700
                                    : AppTheme.gray200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ppSection(
                                  isDark,
                                  '1. Information We Collect',
                                  'Personal information: name, email address, phone number\n'
                                      'Business information: business name, address, GSTIN, PAN, bank details, UPI ID\n'
                                      'Usage data: app interactions, device information',
                                ),
                                const SizedBox(height: 10),
                                _ppSection(
                                  isDark,
                                  '2. How We Use Your Information',
                                  'To provide and maintain our services\n'
                                      'To generate invoices, reports, and business documents\n'
                                      'To communicate with you regarding your account\n'
                                      'To comply with legal obligations',
                                ),
                                const SizedBox(height: 10),
                                _ppSection(
                                  isDark,
                                  '3. Data Sharing & Disclosure',
                                  'We do not sell your personal information.\n'
                                      'We may share data only with your consent, to comply with legal obligations, '
                                      'or to protect against fraud or legal liability.',
                                ),
                                const SizedBox(height: 10),
                                _ppSection(
                                  isDark,
                                  '4. Data Security',
                                  'We implement reasonable security measures to protect your data. '
                                      'However, no method of transmission over the internet is 100% secure.',
                                ),
                                const SizedBox(height: 10),
                                _ppSection(
                                  isDark,
                                  '5. Your Responsibility',
                                  'You are solely responsible for the accuracy of the data you enter, '
                                      'including GST details. Any fraudulent use of this app is strictly prohibited '
                                      'and may result in legal action.',
                                ),
                                const SizedBox(height: 10),
                                _ppSection(
                                  isDark,
                                  '6. Contact Us',
                                  'For questions about this policy, contact: jdsarvaiya281@gmail.com',
                                ),
                                const SizedBox(height: 10),
                                _ppSection(
                                  isDark,
                                  '7. Changes to This Policy',
                                  'We may update this policy. Continued use of the app after changes constitutes acceptance.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: accepted,
                              onChanged: (val) {
                                setStateSheet(() {
                                  accepted = val ?? false;
                                });
                              },
                              activeColor: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'I have read and agree to the Terms & Conditions and Privacy Policy',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : AppTheme.gray800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: accepted && !isLoading
                              ? () async {
                                  final businessProvider = context
                                      .read<Core>()
                                      .business;
                                  bool apiSuccess;
                                  if (isEdit) {
                                    apiSuccess = await businessProvider
                                        .updateBusiness(businessId!, data);
                                  } else {
                                    apiSuccess = await businessProvider
                                        .createBusiness(data);
                                  }
                                  if (apiSuccess && context.mounted) {
                                    Navigator.of(context).pop(true);
                                  } else if (context.mounted) {
                                    showErrorToast(
                                      businessProvider.error ??
                                          'failed_save_business'.tr(),
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isEdit
                                      ? 'update_business'.tr()
                                      : 'create_business'.tr(),
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom > 0
                            ? 0
                            : 8,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result ?? false;
  }

  Widget _ppSection(bool isDark, String heading, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDark ? Colors.white : AppTheme.gray900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: GoogleFonts.outfit(
            fontSize: 12,
            height: 1.4,
            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
          ),
        ),
      ],
    );
  }

  String? _compressAndEncodeImage(File file) {
    try {
      final bytes = file.readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final maxDimension = 300;
      final resized = image.width > image.height
          ? img.copyResize(image, width: maxDimension)
          : img.copyResize(image, height: maxDimension);

      final compressed = img.encodeJpg(resized, quality: 80);
      return 'data:image/jpeg;base64,${base64Encode(compressed)}';
    } catch (e) {
      debugPrint('Error compressing image: $e');
      final bytes = file.readAsBytesSync();
      return 'data:image/png;base64,${base64Encode(bytes)}';
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'gstin': _gstinController.text.trim().isEmpty
          ? null
          : _gstinController.text.trim().toUpperCase(),
      'pan_number': _panController.text.trim().isEmpty
          ? null
          : _panController.text.trim().toUpperCase(),
      'business_type': BusinessType.service.value,
      'invoice_prefix': _prefixController.text.trim(),
      'financial_year': _financialYear,
      'logo_url': _logoUrlBase64,
      'signature_url': _signatureUrlBase64,
      'bank_name': _bankNameController.text.trim().isEmpty
          ? null
          : _bankNameController.text.trim(),
      'account_number': _accNoController.text.trim().isEmpty
          ? null
          : _accNoController.text.trim(),
      'ifsc_code': _ifscController.text.trim().isEmpty
          ? null
          : _ifscController.text.trim().toUpperCase(),
      'upi_id': _upiIdController.text.trim().isEmpty
          ? null
          : _upiIdController.text.trim(),
    };

    final success = await _showTermsBottomSheet(
      data,
      _isEdit,
      businessId: _existingBusiness?.id,
    );
    if (!success || !mounted) return;

    if (_isEdit) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(getPageRoute(const HomeScreen()));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        showSuccessToast(
          _isEdit ? 'business_updated'.tr() : 'business_created'.tr(),
        );
    });
  }

  String _stepTitle() {
    switch (_currentStep) {
      case 0:
        return 'basic_information'.tr();
      case 1:
        return 'address_section'.tr();
      case 2:
        return 'bank_upi_details'.tr();
      case 3:
        return 'branding_signature'.tr();
      default:
        return '';
    }
  }

  Widget _buildProgressBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${'step'.tr()} ${_currentStep + 1} ${'of'.tr()} $_totalSteps: ${_stepTitle()}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.primary,
              ),
            ),
            Text(
              '${((_currentStep + 1) / _totalSteps * 100).toInt()}%',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            minHeight: 6,
            backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray100,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppTheme.primaryDark : AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryDark.withValues(alpha: 0.1)
            : AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.primaryDark.withValues(alpha: 0.2)
              : AppTheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: isDark ? AppTheme.primaryDark : AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isDark ? AppTheme.gray300 : AppTheme.gray700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'edit_business'.tr() : 'add_business'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: _buildProgressBar(),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder:
                    (Widget child, Animation<double> animation) {
                      final isEntering =
                          child.key == ValueKey('step$_currentStep');

                      final startOffset = _isGoingNext
                          ? (isEntering
                                ? const Offset(1.0, 0.0)
                                : const Offset(-1.0, 0.0))
                          : (isEntering
                                ? const Offset(-1.0, 0.0)
                                : const Offset(1.0, 0.0));

                      final tween = Tween<Offset>(
                        begin: startOffset,
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeInOut));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                child: SingleChildScrollView(
                  key: ValueKey('step$_currentStep'),
                  physics: _canScroll
                      ? null
                      : const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: _buildActiveStepContent(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: _buildNavigationButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo();
      case 1:
        return _buildStep2Address();
      case 2:
        return _buildStep3TaxBank();
      case 3:
        return _buildStep4Branding();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1BasicInfo() {
    final theme = Theme.of(context);
    return KeyedSubtree(
      key: const ValueKey('step0'),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTipCard(
              'Provide basic profile information about your business. Required fields are marked with a red asterisk (*).',
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _nameController,
              labelText: 'name'.tr() + ' *',
              hintText: 'enter_business_name'.tr(),
              prefixIcon: Icons.store_outlined,
              validator: (val) =>
                  Validators.validateRequired(val, 'Business name'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _phoneController,
              labelText: 'phone'.tr() + ' *',
              hintText: '10 digit number',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'mobile_required'.tr();
                }
                return Validators.validatePhone(val);
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _emailController,
              labelText: 'email'.tr() + ' (${'optional'.tr().toLowerCase()})',
              hintText: 'e.g. info@shop.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(val.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _prefixController,
              labelText: 'invoice_prefix'.tr() + ' *',
              hintText: 'prefix_hint'.tr(),
              validator: (val) =>
                  Validators.validateRequired(val, 'prefix_label'.tr()),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'financial_year'.tr() + ' *',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _financialYear,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '2025-2026',
                      child: Text('2025-2026'),
                    ),
                    DropdownMenuItem(
                      value: '2026-2027',
                      child: Text('2026-2027'),
                    ),
                    DropdownMenuItem(
                      value: '2027-2028',
                      child: Text('2027-2028'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _financialYear = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Address() {
    return KeyedSubtree(
      key: const ValueKey('step1'),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTipCard(
              'Provide the mailing and physical address of your business operations. This will be formatted as the sender address on invoices.',
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _addressController,
              labelText: 'address'.tr() + ' *',
              hintText: 'building_street'.tr(),
              prefixIcon: Icons.location_on_outlined,
              validator: (val) => Validators.validateRequired(val, 'Address'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _cityController,
              labelText: 'city'.tr() + ' *',
              hintText: 'city_hint'.tr(),
              validator: (val) => Validators.validateRequired(val, 'City'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _stateController,
              labelText: 'state'.tr() + ' *',
              hintText: 'state_hint'.tr(),
              validator: (val) => Validators.validateRequired(val, 'State'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _pincodeController,
              labelText: 'pincode'.tr() + ' *',
              hintText: 'six_digits'.tr(),
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Pincode is required';
                }
                if (val.trim().length != 6) {
                  return 'Pincode must be 6 digits';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3TaxBank() {
    return KeyedSubtree(
      key: const ValueKey('step2'),
      child: Form(
        key: _step3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTipCard(
              'Add optional taxation identifiers and bank information. All of these details are optional, but filling them enables printed payments and tax invoice options.',
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _gstinController,
              labelText: 'gstin'.tr() + ' (${'optional'.tr().toLowerCase()})',
              hintText: 'gstin_15_digit'.tr(),
              validator: Validators.validateGSTIN,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _panController,
              labelText: 'pan'.tr() + ' (${'optional'.tr().toLowerCase()})',
              hintText: 'pan_10_digit'.tr(),
              validator: Validators.validatePAN,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _bankNameController,
              labelText:
                  'bank_name'.tr() + ' (${'optional'.tr().toLowerCase()})',
              hintText: 'bank_name_hint'.tr(),
              prefixIcon: Icons.account_balance_outlined,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _accNoController,
              labelText:
                  'account_number'.tr() + ' (${'optional'.tr().toLowerCase()})',
              hintText: 'account_number_hint'.tr(),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _ifscController,
              labelText:
                  'ifsc_code'.tr() + ' (${'optional'.tr().toLowerCase()})',
              hintText: 'ifsc_hint'.tr(),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _upiIdController,
              labelText: 'upi_id'.tr() + ' (${'optional'.tr().toLowerCase()})',
              hintText: 'upi_hint'.tr(),
              prefixIcon: Icons.qr_code_2_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Branding() {
    return KeyedSubtree(
      key: const ValueKey('step3'),
      child: Form(
        key: _step4FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTipCard(
              'Upload a clear PNG/JPG logo of your firm and draw your signature below. These assets will appear directly inside generated invoices.',
            ),
            const SizedBox(height: 20),
            ImagePickerWidget(
              label: 'upload_logo'.tr(),
              initialImageUrl: _logoUrlBase64,
              selectedImageFile: _logoFile,
              onImageSelected: (file) {
                setState(() {
                  _logoFile = file;
                  _logoUrlBase64 = _compressAndEncodeImage(file);
                });
              },
              onImageRemoved: () {
                setState(() {
                  _logoFile = null;
                  _logoUrlBase64 = null;
                });
              },
            ),
            const SizedBox(height: 24),
            SignaturePadWidget(
              label: 'signature'.tr(),
              initialSignatureUrl: _signatureUrlBase64,
              onDrawStart: () {
                setState(() {
                  _canScroll = false;
                });
              },
              onDrawEnd: () {
                setState(() {
                  _canScroll = true;
                });
              },
              onSignatureSaved: (bytes) {
                setState(() {
                  if (bytes != null) {
                    _signatureUrlBase64 =
                        'data:image/png;base64,${base64Encode(bytes)}';
                  } else {
                    _signatureUrlBase64 = null;
                  }
                });
              },
              onClear: () {
                setState(() {
                  _signatureUrlBase64 = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == _totalSteps - 1;
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _isGoingNext = false;
                  _currentStep--;
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'previous'.tr(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: AppButton(
            text: isLastStep
                ? (_isEdit ? 'update_business'.tr() : 'create_business'.tr())
                : 'next'.tr(),
            onPressed: () {
              if (_formKeys[_currentStep].currentState!.validate()) {
                if (isLastStep) {
                  _submit();
                } else {
                  setState(() {
                    _isGoingNext = true;
                    _currentStep++;
                  });
                }
              } else {
                showErrorToast('Please fix all errors on the current page.');
              }
            },
          ),
        ),
      ],
    );
  }
}
