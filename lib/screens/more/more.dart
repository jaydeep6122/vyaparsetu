import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/avatar.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/accounts/list.dart';
import 'package:vyaparsetu/screens/accounts/transfers.dart';
import 'package:vyaparsetu/screens/auth/login.dart';
import 'package:vyaparsetu/screens/business/documentSeries.dart';
import 'package:vyaparsetu/screens/business/form.dart';
import 'package:vyaparsetu/screens/business/list.dart';
import 'package:vyaparsetu/screens/business/team.dart';
import 'package:vyaparsetu/screens/expenses/list.dart';
import 'package:vyaparsetu/screens/masters/categories.dart';
import 'package:vyaparsetu/screens/masters/taxRates.dart';
import 'package:vyaparsetu/screens/more/changePassword.dart';
import 'package:vyaparsetu/screens/more/profile.dart';
import 'package:vyaparsetu/screens/payments/list.dart';
import 'package:vyaparsetu/screens/reports/dayBook.dart';
import 'package:vyaparsetu/screens/reports/gstSummary.dart';
import 'package:vyaparsetu/screens/reports/outstanding.dart';
import 'package:vyaparsetu/screens/reports/profitLoss.dart';
import 'package:vyaparsetu/screens/reports/reportCenter.dart';
import 'package:vyaparsetu/screens/reports/stockSummary.dart';
import 'package:vyaparsetu/screens/stock/list.dart';

final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

class _MenuEntry {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _MenuEntry(this.icon, this.label, this.onTap, {this.subtitle, this.danger = false});
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _showThemeSheet(BuildContext context) {
    final settings = context.read<Core>().settings;
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                0,
                AppTheme.spaceLg,
                AppTheme.spaceSm,
              ),
              child: Text('appearance'.tr(), style: sheetContext.text.titleLarge),
            ),
            for (final (mode, icon) in const [
              (ThemeMode.system, Icons.brightness_auto_outlined),
              (ThemeMode.light, Icons.light_mode_outlined),
              (ThemeMode.dark, Icons.dark_mode_outlined),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text('theme_${mode.name}'.tr()),
                trailing: settings.themeMode == mode
                    ? Icon(Icons.check_rounded, color: sheetContext.colors.primary)
                    : null,
                onTap: () {
                  settings.setThemeMode(mode);
                  Navigator.of(sheetContext).pop();
                },
              ),
            const SizedBox(height: AppTheme.spaceSm),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'sign_out_title'.tr(),
      message: 'sign_out_message'.tr(),
      confirmText: 'sign_out'.tr(),
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !context.mounted) return;
    final navigator = Navigator.of(context);
    await context.read<Core>().auth.logout();
    navigator.pushAndRemoveUntil(getPageRoute(const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final business = core.business.selectedBusiness;
    if (business == null) return const SizedBox.shrink();

    void push(Widget screen) => Navigator.of(context).push(getPageRoute(screen));
    final isAccountant = core.can(MemberRole.accountant);
    final isAdmin = core.can(MemberRole.admin);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('tab_more'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLg,
          AppTheme.spaceSm,
          AppTheme.spaceLg,
          AppTheme.space3xl,
        ),
        children: [
          AppCard(
            onTap: isAdmin ? () => push(BusinessFormScreen(business: business)) : null,
            child: Row(
              children: [
                BusinessLogo(logoUrl: business.logoUrl, name: business.name, size: 48),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: context.text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [business.role.displayName, ?business.gstin].join(' · '),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => push(const BusinessListScreen()),
                  child: Text('switch'.tr()),
                ),
              ],
            ),
          ),
          _MenuGroup(
            title: 'menu_money'.tr(),
            entries: [
              _MenuEntry(Icons.swap_vert_rounded, 'payments'.tr(), () => push(const PaymentListScreen())),
              _MenuEntry(Icons.account_balance_wallet_outlined, 'expenses'.tr(), () => push(const ExpenseListScreen())),
              _MenuEntry(Icons.account_balance_outlined, 'cash_and_bank'.tr(), () => push(const AccountListScreen())),
              if (isAccountant)
                _MenuEntry(Icons.compare_arrows_rounded, 'transfers'.tr(), () => push(const TransferListScreen())),
            ],
          ),
          _MenuGroup(
            title: 'menu_stock'.tr(),
            entries: [
              _MenuEntry(Icons.inventory_outlined, 'stock_summary'.tr(), () => push(const StockSummaryScreen())),
              _MenuEntry(Icons.tune_rounded, 'stock_adjustments'.tr(), () => push(const StockAdjustmentListScreen())),
            ],
          ),
          if (isAccountant)
            _MenuGroup(
              title: 'menu_reports'.tr(),
              entries: [
                _MenuEntry(Icons.call_received_rounded, 'report_receivables'.tr(),
                    () => push(const OutstandingScreen(type: OutstandingType.receivable))),
                _MenuEntry(Icons.call_made_rounded, 'report_payables'.tr(),
                    () => push(const OutstandingScreen(type: OutstandingType.payable))),
                _MenuEntry(Icons.trending_up_rounded, 'report_profit_loss'.tr(), () => push(const ProfitLossScreen())),
                _MenuEntry(Icons.receipt_outlined, 'report_gst_summary'.tr(), () => push(const GstSummaryScreen())),
                _MenuEntry(Icons.today_outlined, 'report_day_book'.tr(), () => push(const DayBookScreen())),
                _MenuEntry(Icons.bar_chart_rounded, 'all_reports'.tr(), () => push(const ReportCenterScreen())),
              ],
            ),
          _MenuGroup(
            title: 'menu_business'.tr(),
            entries: [
              if (isAdmin)
                _MenuEntry(Icons.storefront_outlined, 'business_profile'.tr(),
                    () => push(BusinessFormScreen(business: business))),
              _MenuEntry(Icons.groups_outlined, 'team'.tr(), () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('coming_soon'.tr())),
                );
              }),
              if (isAdmin)
                _MenuEntry(Icons.numbers_rounded, 'invoice_numbering'.tr(), () => push(const DocumentSeriesScreen())),
              _MenuEntry(Icons.percent_rounded, 'tax_rates'.tr(), () => push(const TaxRatesScreen())),
              _MenuEntry(Icons.category_outlined, 'item_categories'.tr(),
                  () => push(const CategoriesScreen(kind: CategoryKind.item))),
              _MenuEntry(Icons.label_outline_rounded, 'expense_categories'.tr(),
                  () => push(const CategoriesScreen(kind: CategoryKind.expense))),
            ],
          ),
          _MenuGroup(
            title: 'menu_app'.tr(),
            entries: [
              _MenuEntry(
                Icons.palette_outlined,
                'appearance'.tr(),
                () => _showThemeSheet(context),
                subtitle: 'theme_${core.settings.themeMode.name}'.tr(),
              ),
              _MenuEntry(Icons.person_outline_rounded, 'my_profile'.tr(), () => push(const ProfileScreen()),
                  subtitle: core.auth.user?.email),
              _MenuEntry(Icons.lock_outline_rounded, 'change_password'.tr(), () => push(const ChangePasswordScreen())),
              _MenuEntry(Icons.logout_rounded, 'sign_out'.tr(), () => _logout(context), danger: true),
            ],
          ),
          const SizedBox(height: AppTheme.space2xl),
          FutureBuilder<PackageInfo>(
            future: _packageInfo,
            builder: (context, snapshot) => Text(
              snapshot.hasData
                  ? 'app_version'.tr(namedArgs: {
                      'name': AppConstants.appName,
                      'version': snapshot.data!.version,
                    })
                  : AppConstants.appName,
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final String title;
  final List<_MenuEntry> entries;

  const _MenuGroup({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceXs,
            AppTheme.space2xl,
            0,
            AppTheme.spaceSm,
          ),
          child: Text(title, style: context.text.labelMedium),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (index, entry) in entries.indexed) ...[
                if (index > 0) const Divider(indent: 56),
                ListTile(
                  leading: Icon(
                    entry.icon,
                    color: entry.danger ? colors.danger : colors.inkSecondary,
                  ),
                  title: Text(
                    entry.label,
                    style: entry.danger ? TextStyle(color: colors.danger) : null,
                  ),
                  subtitle: entry.subtitle == null ? null : Text(entry.subtitle!),
                  trailing: entry.danger
                      ? null
                      : Icon(Icons.chevron_right_rounded, color: colors.muted),
                  onTap: entry.onTap,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
