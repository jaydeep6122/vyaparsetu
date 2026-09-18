import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/avatar.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/auth/login.dart';
import 'package:vyaparsetu/screens/business/form.dart';
import 'package:vyaparsetu/screens/business/joinBusiness.dart';
import 'package:vyaparsetu/screens/home/home.dart';
import 'package:vyaparsetu/types/business.dart';

class BusinessListScreen extends StatefulWidget {
  /// Shown right after sign-in, with nothing to go back to.
  final bool isRoot;

  const BusinessListScreen({super.key, this.isRoot = false});

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.isRoot) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<Core>().business.fetchBusinesses(),
      );
    }
  }

  Future<void> _open(Business business) async {
    final navigator = Navigator.of(context);
    await context.read<Core>().business.selectBusiness(business);
    navigator.pushAndRemoveUntil(getPageRoute(const HomeScreen()), (_) => false);
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await context.read<Core>().auth.logout();
    navigator.pushAndRemoveUntil(getPageRoute(const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final businesses = core.business.businesses;
    final selectedId = core.business.selectedBusiness?.id;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isRoot,
        title: Text('your_businesses'.tr()),
        actions: [
          if (widget.isRoot)
            IconButton(
              tooltip: 'sign_out'.tr(),
              icon: const Icon(Icons.logout_rounded),
              onPressed: _logout,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: core.business.fetchBusinesses,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          children: [
            if (widget.isRoot) ...[
              Text('choose_business_hint'.tr(), style: context.text.bodyLarge),
              const SizedBox(height: AppTheme.spaceLg),
            ],
            if (core.business.isLoading && businesses.isEmpty)
              const SizedBox(height: 240, child: LoadingIndicator()),
            for (final business in businesses)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                child: AppCard(
                  onTap: () => _open(business),
                  borderColor: business.id == selectedId ? context.colors.primary : null,
                  child: Row(
                    children: [
                      BusinessLogo(logoUrl: business.logoUrl, name: business.name, size: 44),
                      const SizedBox(width: AppTheme.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              business.name,
                              style: context.text.titleSmall,
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
                      Icon(
                        business.id == selectedId
                            ? Icons.check_circle_rounded
                            : Icons.chevron_right_rounded,
                        color: business.id == selectedId
                            ? context.colors.primary
                            : context.colors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppTheme.spaceLg),
            AppButton(
              text: 'add_business'.tr(),
              icon: Icons.add_business_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(context).push(
                getPageRoute(const BusinessFormScreen()),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            AppButton(
              text: 'join_with_invite'.tr(),
              icon: Icons.group_add_outlined,
              variant: AppButtonVariant.text,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('coming_soon'.tr())),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
