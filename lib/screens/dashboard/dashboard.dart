import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/avatar.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/sectionHeader.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/core/modules/invoiceModule.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/accounts/list.dart';
import 'package:vyaparsetu/screens/business/list.dart';
import 'package:vyaparsetu/screens/expenses/form.dart';
import 'package:vyaparsetu/screens/home/home.dart';
import 'package:vyaparsetu/screens/invoices/form.dart';
import 'package:vyaparsetu/screens/invoices/widgets.dart';
import 'package:vyaparsetu/screens/items/detail.dart';
import 'package:vyaparsetu/screens/payments/form.dart';
import 'package:vyaparsetu/screens/reports/outstanding.dart';
import 'package:vyaparsetu/screens/reports/profitLoss.dart';
import 'package:vyaparsetu/screens/reports/stockSummary.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/types/reports.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool refresh = false}) async {
    final core = context.read<Core>();
    if (!core.hasActiveBusiness) return;
    await Future.wait([
      if (core.can(MemberRole.accountant)) ...[
        core.report.fetchDashboard(refresh: refresh),
        core.report.fetchProfitLoss(),
      ],
      core.invoice.fetchInvoices(refresh: refresh),
    ]);
  }

  void _push(Widget screen) => Navigator.of(context).push(getPageRoute(screen));

  void _showOverdue() {
    context.read<Core>().invoice.setFilter(
      const InvoiceFilter(overdueOnly: true),
    );
    HomeScreenState.of(context)?.setTab(1);
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final business = core.business.selectedBusiness;
    if (business == null) return const SizedBox.shrink();

    final canSeeReports = core.can(MemberRole.accountant);
    final dashboard = core.report.dashboard;
    scheduleReload(
      (canSeeReports && dashboard.needsReload) ||
          core.invoice.list.needsReload ||
          (canSeeReports && core.report.profitLoss.needsReload),
      _load,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceLg,
              AppTheme.spaceSm,
              AppTheme.spaceLg,
              AppTheme.fabClearance,
            ),
            children: [
              _Header(
                business: business,
                userName: core.auth.user?.name ?? '',
                onSwitch: () => _push(const BusinessListScreen()),
              ),
              const SizedBox(height: AppTheme.spaceXl),
              if (canSeeReports) ..._buildReportCards(context, core),
              SectionHeader(title: 'quick_actions'.tr()),
              _QuickActions(onOpen: _push),
              const SizedBox(height: AppTheme.spaceXl),
              SectionHeader(
                title: 'recent_bills'.tr(),
                actionLabel: 'see_all'.tr(),
                onActionTap: () => HomeScreenState.of(context)?.setTab(1),
              ),
              ..._buildRecentBills(context, core),
              if (canSeeReports &&
                  (dashboard.value?.lowStock.isNotEmpty ?? false)) ...[
                const SizedBox(height: AppTheme.spaceXl),
                SectionHeader(
                  title: 'low_stock'.tr(),
                  actionLabel: 'see_all'.tr(),
                  onActionTap: () => _push(const StockSummaryScreen()),
                ),
                _LowStockCard(
                  items: dashboard.value!.lowStock,
                  onOpen: (id) => _push(ItemDetailScreen(itemId: id)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: context.colors.border.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: Text(
                        title,
                        style: context.text.labelMedium?.copyWith(
                          color: context.colors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceLg),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AmountDisplay(
                    amount: amount,
                    tone: AmountTone.neutral,
                    style: context.text.titleLarge?.copyWith(
                      color: context.colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildReportCards(BuildContext context, Core core) {
    final dashboardState = core.report.dashboard;
    final data = dashboardState.value;
    final error = dashboardState.error;

    if (data == null) {
      if (error != null) {
        return [
          AppCard(
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: context.colors.danger),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(child: Text(error, style: context.text.bodyMedium)),
                TextButton(
                  onPressed: () => _load(refresh: true),
                  child: Text('retry'.tr()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceXl),
        ];
      }
      return const [SizedBox(height: 200, child: LoadingIndicator())];
    }

    return [
      Builder(
        builder: (context) {
          final profitLoss = core.report.profitLoss.value;
          final netProfit =
              profitLoss?.netProfit ??
              (data.sales.net - data.purchases.net - data.expenses);
          final isProfit = netProfit >= 0;

          final isDark = Theme.of(context).brightness == Brightness.dark;

          final gradient = isProfit
              ? LinearGradient(
                  colors: isDark
                      ? const [
                          Color(0xFF0F524F),
                          Color(0xFF10736B),
                        ] // Toned down teal
                      : const [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: isDark
                      ? const [
                          Color(0xFF881337),
                          Color(0xFFBE123C),
                        ] // Toned down red
                      : const [Color(0xFFBE123C), Color(0xFFF43F5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                );

          return GestureDetector(
            onTap: () => _push(const ProfitLossScreen()),
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      bottom: -30,
                      child: Icon(
                        isProfit
                            ? Icons.auto_graph_rounded
                            : Icons.trending_down_rounded,
                        size: 140,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spaceSm,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusFull,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isProfit
                                          ? Icons.trending_up_rounded
                                          : Icons.trending_down_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isProfit
                                          ? 'net_profit'.tr()
                                          : 'net_loss'.tr(),
                                      style: context.text.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceSm),
                              Text(
                                '${Formatters.formatDateShort(data.period.from)} – ${Formatters.formatDateShort(data.period.to)}',
                                style: context.text.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceSm),
                          AmountDisplay(
                            amount: netProfit.abs(),
                            tone: AmountTone.neutral,
                            style: context.text.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: AppTheme.spaceMd),
      Column(
        children: [
          Row(
            children: [
              _buildSummaryCard(
                context,
                title: 'to_collect'.tr(),
                amount: data.receivable,
                icon: Icons.call_received_rounded,
                color: context.colors.success,
                onTap: () => _push(
                  const OutstandingScreen(type: OutstandingType.receivable),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              _buildSummaryCard(
                context,
                title: 'to_pay'.tr(),
                amount: data.payable,
                icon: Icons.call_made_rounded,
                color: context.colors.danger,
                onTap: () => _push(
                  const OutstandingScreen(type: OutstandingType.payable),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              _buildSummaryCard(
                context,
                title: 'cash_in_hand'.tr(),
                amount: data.cashBalance,
                icon: Icons.account_balance_wallet_rounded,
                color: context.colors.info,
                onTap: () => _push(const AccountListScreen()),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              _buildSummaryCard(
                context,
                title: 'in_bank'.tr(),
                amount: data.bankBalance,
                icon: Icons.account_balance_rounded,
                color: context.colors.primary,
                onTap: () => _push(const AccountListScreen()),
              ),
            ],
          ),
        ],
      ),
      if (data.overdueCount > 0) ...[
        const SizedBox(height: AppTheme.spaceMd),
        AppCard(
          color: context.colors.dangerSoft,
          borderColor: Colors.transparent,
          onTap: _showOverdue,
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: context.colors.danger),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Text(
                  'overdue_bills_message'.tr(
                    namedArgs: {
                      'count': '${data.overdueCount}',
                      'amount': Formatters.formatCurrency(data.overdueAmount),
                    },
                  ),
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.danger,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.colors.danger),
            ],
          ),
        ),
      ],
      const SizedBox(height: AppTheme.spaceXl),
    ];
  }

  List<Widget> _buildRecentBills(BuildContext context, Core core) {
    final list = core.invoice.list;
    if (list.isLoading && list.items.isEmpty) {
      return const [SizedBox(height: 120, child: LoadingIndicator())];
    }
    if (list.items.isEmpty) {
      return [
        AppCard(
          child: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'no_bills_yet'.tr(),
            description: 'no_bills_yet_hint'.tr(),
          ),
        ),
      ];
    }
    return [
      for (final invoice in list.items.take(5))
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
          child: InvoiceTile(invoice: invoice),
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  final Business business;
  final String userName;
  final VoidCallback onSwitch;

  const _Header({
    required this.business,
    required this.userName,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greetingKey = hour < 12
        ? 'greeting_morning'
        : hour < 17
        ? 'greeting_afternoon'
        : 'greeting_evening';
    final firstName = userName.trim().split(' ').first;

    final fullGreeting = greetingKey.tr(namedArgs: {'name': firstName});
    final simpleGreeting = fullGreeting.split(',').first.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSwitch,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        splashColor: context.colors.ink.withValues(alpha: 0.05),
        highlightColor: context.colors.ink.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          child: Row(
            children: [
              BusinessLogo(
                logoUrl: business.logoUrl,
                name: business.name,
                size: 42,
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      simpleGreeting,
                      style: context.text.labelMedium?.copyWith(
                        color: context.colors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      business.name,
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.colors.ink,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  color: context.colors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final ChipTone tone;
  final Widget screen;

  const _QuickAction(this.icon, this.label, this.tone, this.screen);
}

class _QuickActions extends StatelessWidget {
  final void Function(Widget screen) onOpen;

  const _QuickActions({required this.onOpen});

  Widget _buildActionChip(BuildContext context, _QuickAction action) {
    final (background, foreground) = toneColors(context, action.tone);
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: context.colors.border.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => onOpen(action.screen),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: background.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: foreground, size: 16),
              ),
              const SizedBox(width: 8.0),
              Flexible(
                child: Text(
                  action.label,
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        Icons.receipt_long_rounded,
        'action_sale'.tr(),
        ChipTone.primary,
        const InvoiceFormScreen(type: InvoiceType.sale),
      ),
      _QuickAction(
        Icons.shopping_bag_outlined,
        'action_purchase'.tr(),
        ChipTone.info,
        const InvoiceFormScreen(type: InvoiceType.purchase),
      ),
      _QuickAction(
        Icons.account_balance_wallet_outlined,
        'action_expense'.tr(),
        ChipTone.warning,
        const ExpenseFormScreen(),
      ),
      _QuickAction(
        Icons.call_received_rounded,
        'action_payment_in'.tr(),
        ChipTone.success,
        const PaymentFormScreen(direction: PaymentDirection.paymentIn),
      ),
      _QuickAction(
        Icons.call_made_rounded,
        'action_payment_out'.tr(),
        ChipTone.danger,
        const PaymentFormScreen(direction: PaymentDirection.paymentOut),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildActionChip(context, actions[0])), // Sale
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: _buildActionChip(context, actions[1]),
              ), // Purchase
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Row(
            children: [
              Expanded(
                child: _buildActionChip(context, actions[3]),
              ), // Payment In
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: _buildActionChip(context, actions[4]),
              ), // Payment Out
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          SizedBox(
            width: double.infinity,
            child: _buildActionChip(context, actions[2]), // Expense
          ),
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  final List<LowStockItem> items;
  final void Function(String itemId) onOpen;

  const _LowStockCard({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, item) in items.take(5).indexed) ...[
            if (index > 0) const Divider(indent: AppTheme.spaceLg),
            ListTile(
              title: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'reorder_at'.tr(
                  namedArgs: {
                    'quantity': Formatters.formatQuantity(
                      item.lowStockThreshold,
                      item.unitCode,
                    ),
                  },
                ),
              ),
              trailing: Text(
                Formatters.formatQuantity(item.quantityOnHand, item.unitCode),
                style: context.text.titleSmall?.copyWith(
                  color: context.colors.danger,
                ),
              ),
              onTap: () => onOpen(item.id),
            ),
          ],
        ],
      ),
    );
  }
}
