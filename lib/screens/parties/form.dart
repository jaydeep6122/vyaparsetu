import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/core/Core.dart';

class PartyFormScreen extends StatefulWidget {
  final Party? existingParty;
  final PartyType? initialPartyType;
  const PartyFormScreen({super.key, this.existingParty, this.initialPartyType});

  @override
  State<PartyFormScreen> createState() => _PartyFormScreenState();
}

class _PartyFormScreenState extends State<PartyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Party? _existingParty;
  bool _isEdit = false;
  bool _isInitialized = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();
  final List<TextEditingController> _billingAddressControllers = [];
  final List<TextEditingController> _shippingAddressControllers = [];
  final _openingBalanceController = TextEditingController();

  PartyType _partyType = PartyType.customer;
  OpeningBalanceType _balanceType = OpeningBalanceType.receive;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      final args = widget.existingParty;
      if (args is Party) {
        _existingParty = args;
        _isEdit = true;
        _initForm();
      } else {
        if (widget.initialPartyType != null) {
          _partyType = widget.initialPartyType!;
        }
        _billingAddressControllers.add(TextEditingController());
        _shippingAddressControllers.add(TextEditingController());
      }
    }
  }

  void _initForm() {
    if (_existingParty == null) return;
    final p = _existingParty!;
    _nameController.text = p.name;
    _phoneController.text = p.phone ?? '';
    _emailController.text = p.email ?? '';
    _gstinController.text = p.gstin ?? '';
    
    _billingAddressControllers.clear();
    for (final addr in p.billingAddresses) {
      _billingAddressControllers.add(TextEditingController(text: addr));
    }
    if (_billingAddressControllers.isEmpty) {
      _billingAddressControllers.add(TextEditingController());
    }

    _shippingAddressControllers.clear();
    for (final addr in p.shippingAddresses) {
      _shippingAddressControllers.add(TextEditingController(text: addr));
    }
    if (_shippingAddressControllers.isEmpty) {
      _shippingAddressControllers.add(TextEditingController());
    }

    _openingBalanceController.text = p.openingBalance.toString();
    _partyType = p.partyType;
    _balanceType = p.openingBalanceType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    for (final c in _billingAddressControllers) {
      c.dispose();
    }
    for (final c in _shippingAddressControllers) {
      c.dispose();
    }
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId == null) return;

    final partyProvider = context.read<Core>().party;

    final billingAddressesList = _billingAddressControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final shippingAddressesList = _shippingAddressControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final data = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'gstin': _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim().toUpperCase(),
      'billing_address': billingAddressesList.isEmpty ? null : jsonEncode(billingAddressesList),
      'shipping_address': shippingAddressesList.isEmpty ? null : jsonEncode(shippingAddressesList),
      'party_type': _partyType.value,
      'opening_balance': _openingBalanceController.text.trim().isEmpty 
          ? 0.0 
          : double.parse(_openingBalanceController.text.trim()),
      'opening_balance_type': _balanceType.value,
    };

    bool success;
    if (_isEdit) {
      success = await partyProvider.updateParty(businessId, _existingParty!.id, data);
    } else {
      success = await partyProvider.createParty(businessId, data);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSuccessToast(_isEdit ? 'Party updated successfully' : 'Party added successfully');
      });
    } else if (mounted) {
      showErrorToast(partyProvider.error ?? 'Failed to save party');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'edit_party'.tr() : 'add_party'.tr(),
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
                // Name & Contact
                AppTextField(
                  controller: _nameController,
                  labelText: 'party_name'.tr(),
                  hintText: 'Enter contact/party name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) => Validators.validateRequired(val, 'Party name'),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _phoneController,
                        labelText: 'phone'.tr(),
                        hintText: '10 digits mobile',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: Validators.validatePhone,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        controller: _emailController,
                        labelText: 'email'.tr(),
                        hintText: 'e.g. contact@party.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return null;
                          return Validators.validateEmail(val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),



                // GSTIN
                AppTextField(
                  controller: _gstinController,
                  labelText: 'gstin'.tr(),
                  hintText: '15-digit GSTIN number',
                  validator: Validators.validateGSTIN,
                ),
                const SizedBox(height: 16),

                // Opening Balance (Only for creation)
                if (!_isEdit) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 2,
                        child: AppTextField(
                          controller: _openingBalanceController,
                          labelText: 'opening_balance'.tr(),
                          hintText: 'e.g. 5000',
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return null;
                            return Validators.validateAmount(val, 'Opening Balance');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'opening_balance_type'.tr(),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<OpeningBalanceType>(
                              value: _balanceType,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: OpeningBalanceType.receive,
                                  child: Text('Receive'),
                                ),
                                DropdownMenuItem(
                                  value: OpeningBalanceType.pay,
                                  child: Text('Pay'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _balanceType = val;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Addresses
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Billing Addresses',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _billingAddressControllers.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          key: ValueKey('billing_addr_$index'),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _billingAddressControllers[index],
                                  labelText: 'Billing Address ${index + 1}',
                                  hintText: 'Street, city, pincode',
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  prefixIcon: Icons.receipt_outlined,
                                ),
                              ),
                              if (_billingAddressControllers.length > 1) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      _billingAddressControllers[index].dispose();
                                      _billingAddressControllers.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _billingAddressControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: Text('Add Billing Address', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shipping Addresses',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _shippingAddressControllers.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          key: ValueKey('shipping_addr_$index'),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _shippingAddressControllers[index],
                                  labelText: 'Shipping Address ${index + 1}',
                                  hintText: 'Delivery address (Leave blank if same as billing)',
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  prefixIcon: Icons.local_shipping_outlined,
                                ),
                              ),
                              if (_shippingAddressControllers.length > 1) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      _shippingAddressControllers[index].dispose();
                                      _shippingAddressControllers.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _shippingAddressControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: Text('Add Shipping Address', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Submit Button
                AppButton(
                  text: 'save'.tr(),
                  isLoading: context.select<Core, bool>((c) => c.party.isLoading),
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
