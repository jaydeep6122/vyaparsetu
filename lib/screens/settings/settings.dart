import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/screens/business/detail.dart';
import 'package:vyaparsetu/screens/business/form.dart';
import 'package:vyaparsetu/screens/expenses/list.dart';
import 'package:vyaparsetu/screens/payments/list.dart';
import 'package:vyaparsetu/screens/business/list.dart';
import 'package:vyaparsetu/screens/reports/reportCenter.dart';
import 'package:vyaparsetu/screens/auth/login.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/types/user.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/core/Core.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = context.select<Core, User?>((c) => c.auth.user);
    final selectedBusiness = context.select<Core, Business?>((c) => c.business.selectedBusiness);
    final hasMultipleBusinesses = context.select<Core, bool>((c) => c.business.businesses.length > 1);
    final locale = context.select<Core, Locale>((c) => c.settings.locale);
    final isDarkMode = context.select<Core, bool>((c) => c.settings.isDarkMode);

    final userInitials =
        user?.name.isNotEmpty == true
            ? user!.name
                .split(' ')
                .map((e) => e[0])
                .take(2)
                .join()
                .toUpperCase()
            : 'U';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : AppTheme.primary.withValues(alpha: 0.08),
                      child: Text(
                        userInitials,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'User Name',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'user@example.com',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            _buildSectionHeader('business'.tr(), context),
            const SizedBox(height: 8),
            _buildSettingTile(
              context,
              customLeading: _buildBusinessLogoWidget(selectedBusiness, isDark),
              title: selectedBusiness?.name ?? 'business_details'.tr(),
              subtitle:
                  selectedBusiness != null
                      ? '${selectedBusiness.city}, ${selectedBusiness.state}'
                      : 'manage_business_details'.tr(),
              onTap: () {
                if (selectedBusiness != null) {
                  Navigator.of(context).push(
                    getPageRoute(const BusinessDetailScreen()),
                  );
                } else {
                  Navigator.of(context).push(
                    getPageRoute(const BusinessFormScreen()),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              context,
              icon: Icons.money_off_csred_rounded,
              title: 'expenses'.tr(),
              subtitle: 'view_expenses_subtitle'.tr(),
              onTap:
                  () => Navigator.of(
                    context,
                  ).push(getPageRoute(const ExpenseListScreen())),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              context,
              icon: Icons.payments_rounded,
              title: 'payments'.tr(),
              subtitle: 'view_payments_subtitle'.tr(),
              onTap:
                  () => Navigator.of(
                    context,
                  ).push(getPageRoute(const PaymentListScreen())),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              context,
              icon: hasMultipleBusinesses ? Icons.switch_account_rounded : Icons.add_business_rounded,
              title: hasMultipleBusinesses ? 'switch_business'.tr() : 'add_business'.tr(),
              subtitle: hasMultipleBusinesses ? 'switch_business_subtitle'.tr() : 'add_business_subtitle'.tr(),
              onTap: () {
                Navigator.of(
                  context,
                ).push(getPageRoute(const BusinessListScreen()));
              },
            ),
            const SizedBox(height: 28),
            _buildSectionHeader('reports'.tr(), context),
            const SizedBox(height: 8),
            _buildSettingTile(
              context,
              icon: Icons.assessment_rounded,
              title: 'report_center'.tr(),
              subtitle: 'business_health_reports'.tr(),
              onTap:
                  () => Navigator.of(context).push(
                    getPageRoute(const ReportCenterScreen()),
                  ),
            ),
            const SizedBox(height: 28),
            _buildSectionHeader('preferences'.tr(), context),
            const SizedBox(height: 8),
            _buildSettingTile(
              context,
              icon: Icons.translate_rounded,
              title: 'language'.tr(),
              subtitle: _getLocaleName(locale.languageCode),
               onTap: () => _showLanguageSelector(context, locale),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              context,
              icon:
                  isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
              title: 'theme'.tr(),
              subtitle:
                  isDarkMode
                      ? 'dark_mode'.tr()
                      : 'light_mode'.tr(),
              trailing: Switch(
                value: isDarkMode,
                onChanged: (val) {
                  context.read<Core>().settings.toggleTheme();
                },
                activeColor: isDark ? Colors.white : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            _buildSectionHeader('support_section'.tr(), context),
            const SizedBox(height: 8),
            _buildSettingTile(
              context,
              icon: Icons.mail_outline_rounded,
              title: 'contact_us'.tr(),
              subtitle: 'jdsarvaiya281@gmail.com',
              trailing: const Icon(Icons.copy_rounded, size: 18),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'jdsarvaiya281@gmail.com'));
                showSuccessToast('email_copied'.tr());
              },
            ),
            const SizedBox(height: 28),
            _buildSectionHeader('system_section'.tr(), context),
            const SizedBox(height: 8),
            _buildSettingTile(
              context,
              icon: Icons.logout_rounded,
              title: 'logout'.tr(),
              titleColor: AppTheme.error,
              onTap:
                  () =>
                      _confirmLogout(context, allDevices: false),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              context,
              icon: Icons.phonelink_erase_rounded,
              title: 'logout_all_devices'.tr(),
              titleColor: AppTheme.error,
              onTap:
                  () => _confirmLogout(context, allDevices: true),
            ),
            const SizedBox(height: 32),
            Text(
              'app_version_label'.tr(),
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyMedium?.color,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    IconData? icon,
    Widget? customLeading,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final leadingWidget = customLeading ?? Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: titleColor?.withValues(alpha: 0.1) ??
                (isDark ? Colors.white.withValues(alpha: 0.12) : AppTheme.primary.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: icon != null ? Icon(
            icon,
            size: 20,
            color:
                titleColor ??
                (isDark ? Colors.white : AppTheme.primary),
          ) : null,
        );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: ListTile(
        onTap: onTap,
        leading: leadingWidget,
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: titleColor,
          ),
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                )
                : null,
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: theme.iconTheme.color?.withValues(alpha: 0.4),
            ),
      ),
    );
  }

  String _getLocaleName(String code) {
    switch (code) {
      case 'hi':
        return 'हिंदी (Hindi)';
      case 'gu':
        return 'ગુજરાતી (Gujarati)';
      case 'en':
      default:
        return 'English';
    }
  }

  void _showLanguageSelector(
    BuildContext context,
    Locale currentLocale,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
                    Text(
                      'select_language'.tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                title: Text(
                  'English',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                trailing:
                    currentLocale.languageCode == 'en'
                        ? Icon(Icons.check_circle, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primary)
                        : null,
                onTap: () {
                  context.read<Core>().settings.changeLocale(context, const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(
                  'हिंदी (Hindi)',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                trailing:
                    currentLocale.languageCode == 'hi'
                        ? Icon(Icons.check_circle, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primary)
                        : null,
                onTap: () {
                  context.read<Core>().settings.changeLocale(context, const Locale('hi'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(
                  'ગુજરાતી (Gujarati)',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                trailing:
                    currentLocale.languageCode == 'gu'
                        ? Icon(Icons.check_circle, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primary)
                        : null,
                onTap: () {
                  context.read<Core>().settings.changeLocale(context, const Locale('gu'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(
    BuildContext context, {
    required bool allDevices,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return ConfirmationDialog(
          title: 'logout'.tr(),
          content:
              allDevices
                      ? 'logout_all_devices_confirm'.tr()
                  : 'logout_confirm'.tr(),
          confirmText: 'logout'.tr(),
          isDestructive: true,
          icon: Icons.logout_rounded,
        );
      },
    );

    if (confirm == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      await context.read<Core>().auth.logout(allDevices: allDevices);
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.of(context).pushAndRemoveUntil(
          getPageRoute(const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildBusinessLogoWidget(Business? selectedBusiness, bool isDark) {
    if (selectedBusiness?.logoUrl != null && selectedBusiness!.logoUrl!.isNotEmpty) {
      if (selectedBusiness.logoUrl!.startsWith('data:image')) {
        try {
          final base64Str = selectedBusiness.logoUrl!.split(',')[1];
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Image.memory(
                base64Decode(base64Str),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _buildFallbackLogo(isDark),
              ),
            ),
          );
        } catch (_) {}
      } else {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Image.network(
              selectedBusiness.logoUrl!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => _buildFallbackLogo(isDark),
            ),
          ),
        );
      }
    }
    return _buildFallbackLogo(isDark);
  }

  Widget _buildFallbackLogo(bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.12) : AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Icon(
        Icons.business_center_rounded,
        size: 20,
        color: isDark ? Colors.white : AppTheme.primary,
      ),
    );
  }
}
