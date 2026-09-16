import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/avatar.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/infoRow.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/sectionHeader.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/components/summaryCard.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/core/components/moduleBase.dart';
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
import 'package:vyaparsetu/screens/items/form.dart';
import 'package:vyaparsetu/screens/parties/form.dart';
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
      if (core.can(MemberRole.accountant)) core.report.fetchDashboard(refresh: refresh),
      core.invoice.fetchInvoices(refresh: refresh),
    ]);
  }

  void _push(Widget screen) => Navigator.of(context).push(getPageRoute(screen));

  void _showOverdue() {
    context.read<Core>().invoice.setFilter(const InvoiceFilter(overdueOnly: true));
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
      (canSeeReports && dashboard.needsReload) || core.invoice.list.needsReload,
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
              if (canSeeReports) ..._buildReportCards(context, dashboard),
              SectionHeader(title: 'quick_actions'.tr()),
              _QuickActions(onOpen: _push),
              const SizedBox(height: AppTheme.spaceXl),
              SectionHeader(
                title: 'recent_bills'.tr(),
                actionLabel: 'see_all'.tr(),
                onActionTap: () => HomeScreenState.of(context)?.setTab(1),
              ),
              ..._buildRecentBills(context, core),
              if (canSeeReports && (dashboard.value?.lowStock.isNotEmpty ?? false)) ...[
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

  List<Widget> _buildReportCards(
    BuildContext context,
    LoadState<DashboardData> dashboardState,
  ) {
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
                TextButton(onPressed: () => _load(refresh: true), child: Text('retry'.tr())),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceXl),
        ];
      }
      return const [SizedBox(height: 200, child: LoadingIndicator())];
    }

    return [
      Row(
        children: [
          Expanded(
            child: SummaryCard(
              title: 'to_collect'.tr(),
              value: Formatters.formatCurrency(data.receivable),
              icon: Icons.call_received_rounded,
              tone: ChipTone.success,
              onTap: () => _push(const OutstandingScreen(type: OutstandingType.receivable)),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: SummaryCard(
              title: 'to_pay'.tr(),
              value: Formatters.formatCurrency(data.payable),
              icon: Icons.call_made_rounded,
              tone: ChipTone.danger,
              onTap: () => _push(const OutstandingScreen(type: OutstandingType.payable)),
            ),
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
                  'overdue_bills_message'.tr(namedArgs: {
                    'count': '${data.overdueCount}',
                    'amount': Formatters.formatCurrency(data.overdueAmount),
                  }),
                  style: context.text.bodyMedium?.copyWith(color: context.colors.danger),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.colors.danger),
            ],
          ),
        ),
      ],
      const SizedBox(height: AppTheme.spaceMd),
      AppCard(
        onTap: () => _push(const AccountListScreen()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('cash_and_bank'.tr(), style: context.text.titleSmall)),
                Icon(Icons.chevron_right_rounded, color: context.colors.muted),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.payments_outlined,
                    label: 'cash_in_hand'.tr(),
                    amount: data.cashBalance,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.account_balance_outlined,
                    label: 'in_bank'.tr(),
                    amount: data.bankBalance,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: AppTheme.spaceMd),
      AppCard(
        onTap: () => _push(const ProfitLossScreen()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('this_year'.tr(), style: context.text.titleSmall)),
                Text(
                  '${Formatters.formatDateShort(data.period.from)} – ${Formatters.formatDateShort(data.period.to)}',
                  style: context.text.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            InfoRow(
              label: 'net_sales'.tr(),
              valueWidget: AmountDisplay(amount: data.sales.net, style: context.text.titleSmall),
            ),
            InfoRow(
              label: 'net_purchases'.tr(),
              valueWidget: AmountDisplay(amount: data.purchases.net, style: context.text.titleSmall),
            ),
            InfoRow(
              label: 'money_received'.tr(),
              valueWidget: AmountDisplay(
                amount: data.received,
                tone: AmountTone.positive,
                style: context.text.titleSmall,
              ),
            ),
            InfoRow(
              label: 'money_paid'.tr(),
              valueWidget: AmountDisplay(amount: data.paid, style: context.text.titleSmall),
            ),
            InfoRow(
              label: 'expenses'.tr(),
              valueWidget: AmountDisplay(amount: data.expenses, style: context.text.titleSmall),
            ),
          ],
        ),
      ),
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

  const _Header({required this.business, required this.userName, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greetingKey = hour < 12
        ? 'greeting_morning'
        : hour < 17
        ? 'greeting_afternoon'
        : 'greeting_evening';
    final firstName = userName.trim().split(' ').first;

    return Row(
      children: [
        BusinessLogo(logoUrl: business.logoUrl, name: business.name, size: 44),
        const SizedBox(width: AppTheme.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingKey.tr(namedArgs: {'name': firstName}),
                style: context.text.bodySmall,
              ),
              Text(
                business.name,
                style: context.text.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'switch_business'.tr(),
          icon: const Icon(Icons.swap_horiz_rounded),
          onPressed: onSwitch,
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;

  const _MiniStat({required this.icon, required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.colors.muted),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.text.bodySmall),
              AmountDisplay(amount: amount, showMinus: true, style: context.text.titleMedium),
            ],
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(Icons.receipt_long_rounded, 'action_sale'.tr(), ChipTone.primary,
          const InvoiceFormScreen(type: InvoiceType.sale)),
      _QuickAction(Icons.shopping_bag_outlined, 'action_purchase'.tr(), ChipTone.info,
          const InvoiceFormScreen(type: InvoiceType.purchase)),
      _QuickAction(Icons.call_received_rounded, 'action_payment_in'.tr(), ChipTone.success,
          const PaymentFormScreen(direction: PaymentDirection.paymentIn)),
      _QuickAction(Icons.call_made_rounded, 'action_payment_out'.tr(), ChipTone.danger,
          const PaymentFormScreen(direction: PaymentDirection.paymentOut)),
      _QuickAction(Icons.account_balance_wallet_outlined, 'action_expense'.tr(), ChipTone.warning,
          const ExpenseFormScreen()),
      _QuickAction(Icons.person_add_alt_1_outlined, 'action_party'.tr(), ChipTone.primary,
          const PartyFormScreen()),
      _QuickAction(Icons.add_box_outlined, 'action_item'.tr(), ChipTone.info, const ItemFormScreen()),
      _QuickAction(Icons.assignment_return_outlined, 'action_sale_return'.tr(), ChipTone.neutral,
          const InvoiceFormScreen(type: InvoiceType.saleReturn)),
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceXs,
        vertical: AppTheme.spaceMd,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / 4;
          return Wrap(
            runSpacing: AppTheme.spaceMd,
            children: [
              for (final action in actions)
                SizedBox(
                  width: width,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    onTap: () => onOpen(action.screen),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs),
                      child: Column(
                        children: [
                          Builder(builder: (context) {
                            final (background, foreground) = toneColors(context, action.tone);
                            return Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: background,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Icon(action.icon, color: foreground, size: 22),
                            );
                          }),
                          const SizedBox(height: AppTheme.spaceXs + 2),
                          Text(
                            action.label,
                            style: context.text.labelSmall,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
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
              title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                'reorder_at'.tr(namedArgs: {
                  'quantity': Formatters.formatQuantity(item.lowStockThreshold, item.unitCode),
                }),
              ),
              trailing: Text(
                Formatters.formatQuantity(item.quantityOnHand, item.unitCode),
                style: context.text.titleSmall?.copyWith(color: context.colors.danger),
              ),
              onTap: () => onOpen(item.id),
            ),
          ],
        ],
      ),
    );
  }
}
