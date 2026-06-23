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
  final _formKey = GlobalKey<FormState>();

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

  BusinessType _businessType = BusinessType.service;
  String _financialYear = '2026-2027';

  File? _logoFile;
  String? _logoUrlBase64;
  String? _signatureUrlBase64;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = widget.existingBusiness;
    if (args is Business) {
      _existingBusiness = args;
      _isEdit = true;
      _initForm();
    } else {
      // Default invoice prefix
      _prefixController.text = 'INV';
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

            return Container(
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
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
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
                    Text(
                      'Terms & Conditions',
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
                        color:
                            isDark
                                ? AppTheme.gray800.withValues(alpha: 0.3)
                                : AppTheme.gray50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                        ),
                      ),
                      child: Text(
                        'The GST details you provide must be your own. If you enter someone else\'s GST or commit fraud using this app, the app owner is not responsible. All legal action will be taken against you.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? AppTheme.gray300 : AppTheme.gray700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Privacy Policy',
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
                        color:
                            isDark
                                ? AppTheme.gray800.withValues(alpha: 0.3)
                                : AppTheme.gray50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            accepted && !isLoading
                                ? () async {
                                  final businessProvider =
                                      context.read<Core>().business;
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
                                          'Failed to save business',
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
                        child:
                            isLoading
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
                    const SizedBox(height: 8),
                  ],
                ),
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
      final resized =
          image.width > image.height
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
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'email':
          _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
      'phone':
          _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'gstin':
          _gstinController.text.trim().isEmpty
              ? null
              : _gstinController.text.trim().toUpperCase(),
      'pan_number':
          _panController.text.trim().isEmpty
              ? null
              : _panController.text.trim().toUpperCase(),
      'business_type': _businessType.value,
      'invoice_prefix': _prefixController.text.trim(),
      'financial_year': _financialYear,
      'logo_url': _logoUrlBase64,
      'signature_url': _signatureUrlBase64,
      'bank_name':
          _bankNameController.text.trim().isEmpty
              ? null
              : _bankNameController.text.trim(),
      'account_number':
          _accNoController.text.trim().isEmpty
              ? null
              : _accNoController.text.trim(),
      'ifsc_code':
          _ifscController.text.trim().isEmpty
              ? null
              : _ifscController.text.trim().toUpperCase(),
      'upi_id':
          _upiIdController.text.trim().isEmpty
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
          _isEdit
              ? 'Business updated successfully'
              : 'Business created successfully',
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'edit_business'.tr() : 'add_business'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: _canScroll ? null : const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 1: BASIC INFO
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _nameController,
                  labelText: 'name'.tr(),
                  hintText: 'Enter business/store name',
                  prefixIcon: Icons.store_outlined,
                  validator:
                      (val) =>
                          Validators.validateRequired(val, 'Business name'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _emailController,
                        labelText: 'email'.tr(),
                        hintText: 'e.g. info@shop.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: Validators.validateEmail,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        controller: _phoneController,
                        labelText: 'phone'.tr(),
                        hintText: '10 digit number',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Mobile number is required';
                          }
                          return Validators.validatePhone(val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // SECTION 2: ADDRESS
                _buildSectionTitle('Address'),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _addressController,
                  labelText: 'address'.tr(),
                  hintText: 'Building, Street name, Area',
                  prefixIcon: Icons.location_on_outlined,
                  validator:
                      (val) => Validators.validateRequired(val, 'Address'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _cityController,
                        labelText: 'city'.tr(),
                        hintText: 'City',
                        validator:
                            (val) => Validators.validateRequired(val, 'City'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _stateController,
                        labelText: 'state'.tr(),
                        hintText: 'State',
                        validator:
                            (val) => Validators.validateRequired(val, 'State'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _pincodeController,
                        labelText: 'pincode'.tr(),
                        hintText: '6 digits',
                        keyboardType: TextInputType.number,
                        validator:
                            (val) =>
                                Validators.validateRequired(val, 'Pincode'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // SECTION 3: TAX & INVOICE SETTINGS
                _buildSectionTitle('Tax & Invoice Settings'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _gstinController,
                        labelText: 'gstin'.tr(),
                        hintText: '15-digit GSTIN',
                        validator: Validators.validateGSTIN,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        controller: _panController,
                        labelText: 'pan'.tr(),
                        hintText: '10-digit PAN',
                        validator: Validators.validatePAN,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _prefixController,
                        labelText: 'invoice_prefix'.tr(),
                        hintText: 'e.g. INV',
                        validator:
                            (val) => Validators.validateRequired(
                              val,
                              'Invoice Prefix',
                            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'financial_year'.tr(),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyLarge?.color
                                  ?.withValues(alpha: 0.7),
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
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // SECTION 4: BANK DETAILS
                _buildSectionTitle('Bank / UPI Details'),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _bankNameController,
                  labelText: 'bank_name'.tr(),
                  hintText: 'Bank Name',
                  prefixIcon: Icons.account_balance_outlined,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _accNoController,
                        labelText: 'account_number'.tr(),
                        hintText: 'Account Number',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        controller: _ifscController,
                        labelText: 'ifsc_code'.tr(),
                        hintText: '11-digit IFSC',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _upiIdController,
                  labelText: 'upi_id'.tr(),
                  hintText: 'e.g. name@upi',
                  prefixIcon: Icons.qr_code_2_rounded,
                ),

                const SizedBox(height: 28),

                // SECTION 5: BRANDING
                _buildSectionTitle('Branding & Signature'),
                const SizedBox(height: 16),
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

                const SizedBox(height: 32),

                // SUBMIT BUTTON
                AppButton(
                  text:
                      _isEdit ? 'update_business'.tr() : 'create_business'.tr(),
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: isDark ? Colors.white : AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
