import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/business/form.dart';
import 'package:vyaparsetu/screens/business/list.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/core/Core.dart';

class BusinessDetailScreen extends StatefulWidget {
  const BusinessDetailScreen({super.key});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  bool _isDeleting = false;

  Future<void> _deleteBusiness() async {
    final businessProvider = context.read<Core>().business;
    final business = businessProvider.selectedBusiness;
    if (business == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'delete_business'.tr(),
        content: 'delete_business_confirm'.tr(),
        confirmText: 'delete'.tr(),
        isDestructive: true,
        icon: Icons.delete_outline_rounded,
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        final success = await businessProvider.deleteBusiness(business.id);
        if (success && mounted) {
          if (businessProvider.businesses.isEmpty) {
            Navigator.of(context).pushAndRemoveUntil(
              getPageRoute(const BusinessFormScreen()),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              getPageRoute(const BusinessListScreen()),
              (route) => false,
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_isDeleting,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'business_details'.tr(),
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          actions: [
            Consumer<Core>(
              builder: (context, core, child) {
                final b = core.business.selectedBusiness;
                if (b == null) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      getPageRoute(BusinessFormScreen(existingBusiness: b)),
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: Consumer<Core>(
          builder: (context, core, child) {
            final b = core.business.selectedBusiness;
            if (b == null) {
              return Center(
                child: Text(
                  'no_business_selected'.tr(),
                  style: GoogleFonts.outfit(fontSize: 16),
                ),
              );
            }

            Widget logoWidget = Icon(
              Icons.store_rounded,
              size: 48,
              color: isDark ? Colors.white : AppTheme.primary,
            );

            if (b.logoUrl != null && b.logoUrl!.isNotEmpty) {
              if (b.logoUrl!.startsWith('data:image')) {
                try {
                  final base64Str = b.logoUrl!.split(',')[1];
                  logoWidget = Image.memory(
                    base64Decode(base64Str),
                    fit: BoxFit.contain,
                  );
                } catch (_) {}
              } else {
                logoWidget = Image.network(
                  b.logoUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.store_rounded, size: 48),
                );
              }
            }

            Widget signatureWidget = Text(
              'no_signature'.tr(),
              style: GoogleFonts.outfit(
                color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                fontSize: 13,
              ),
            );

            if (b.signatureUrl != null && b.signatureUrl!.isNotEmpty) {
              if (b.signatureUrl!.startsWith('data:image')) {
                try {
                  final base64Str = b.signatureUrl!.split(',')[1];
                  signatureWidget = Image.memory(
                    base64Decode(base64Str),
                    fit: BoxFit.contain,
                  );
                } catch (_) {}
              } else {
                signatureWidget = Image.network(
                  b.signatureUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.edit_outlined),
                );
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Logo
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.cardDark
                                : AppTheme.gray100,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg,
                            ),
                          ),
                          child: logoWidget,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          b.name,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          b.businessType.displayName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Info Cards
                  _buildInfoCard(
                    context,
                    title: 'contact_details'.tr(),
                    items: {
                      'email_label'.tr(): b.email ?? 'not_provided'.tr(),
                      'phone_label'.tr(): b.phone ?? 'not_provided'.tr(),
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildInfoCard(
                    context,
                    title: 'address_info'.tr(),
                    items: {
                      'Address': b.address,
                      'City / State': '${b.city}, ${b.state}',
                      'Pincode': b.pincode,
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildInfoCard(
                    context,
                    title: 'taxation_settings'.tr(),
                    items: {
                      'GSTIN': b.gstin ?? 'not_provided'.tr(),
                      'PAN Number': b.panNumber ?? 'not_provided'.tr(),
                      'Invoice Prefix': b.invoicePrefix,
                      'Financial Year': b.financialYear,
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildInfoCard(
                    context,
                    title: 'bank_information'.tr(),
                    items: {
                      'Bank Name': b.bankName ?? 'not_provided'.tr(),
                      'Account Number': b.accountNumber ?? 'not_provided'.tr(),
                      'IFSC Code': b.ifscCode ?? 'not_provided'.tr(),
                      'UPI ID': b.upiId ?? 'not_provided'.tr(),
                    },
                  ),
                  const SizedBox(height: 16),

                  // Signature Card
                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Authorized Signature',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.gray800 : Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.gray700
                                    : AppTheme.gray200,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: signatureWidget,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Delete Action Button
                  AppButton(
                    text: 'Delete Business Profile',
                    isSecondary: true,
                    isLoading: _isDeleting,
                    onPressed: _isDeleting ? null : _deleteBusiness,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required Map<String, String> items,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            ...items.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        entry.key,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color?.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
