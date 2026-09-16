import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/pagedList.dart';
import 'package:vyaparsetu/components/searchBar.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/modules/invoiceModule.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/invoices/form.dart';
import 'package:vyaparsetu/screens/invoices/widgets.dart';
import 'package:vyaparsetu/types/invoice.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<Core>().invoice.fetchInvoices(),
    );
  }

  void _newBill(InvoiceType type) =>
      Navigator.of(context).push(getPageRoute(InvoiceFormScreen(type: type)));

  Future<void> _chooseType() async {
    final type = await showModalBottomSheet<InvoiceType>(
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
              child: Text('new_bill'.tr(), style: sheetContext.text.titleLarge),
            ),
            for (final type in InvoiceType.values)
              ListTile(
                leading: Icon(switch (type) {
                  InvoiceType.sale => Icons.receipt_long_rounded,
                  InvoiceType.purchase => Icons.shopping_bag_outlined,
                  InvoiceType.saleReturn => Icons.assignment_return_outlined,
                  InvoiceType.purchaseReturn => Icons.keyboard_return_rounded,
                }),
                title: Text(type.displayName),
                subtitle: Text('invoice_type_${type.value}_hint'.tr()),
                onTap: () => Navigator.of(sheetContext).pop(type),
              ),
            const SizedBox(height: AppTheme.spaceSm),
          ],
        ),
      ),
    );
    if (type != null && mounted) _newBill(type);
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final invoices = core.invoice;
    final filter = invoices.filter;
    scheduleReload(invoices.list.needsReload, () => invoices.fetchInvoices(refresh: true));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('tab_bills'.tr()),
        actions: [
          if (filter.isActive)
            TextButton(
              onPressed: () => invoices.setFilter(InvoiceFilter(search: filter.search)),
              child: Text('clear_filters'.tr()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-bill-list',
        onPressed: _chooseType,
        icon: const Icon(Icons.add_rounded),
        label: Text('new_bill'.tr()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceLg,
              0,
              AppTheme.spaceLg,
              AppTheme.spaceSm,
            ),
            child: AppSearchBar(
              hintText: 'search_bills'.tr(),
              initialValue: filter.search,
              onChanged: (query) => invoices.setFilter(filter.copyWith(search: query)),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              children: [
                ChoiceChip(
                  label: Text('filter_all'.tr()),
                  selected: filter.type == null,
                  showCheckmark: false,
                  onSelected: (_) => invoices.setFilter(filter.copyWith(clearType: true)),
                ),
                for (final type in InvoiceType.values)
                  Padding(
                    padding: const EdgeInsets.only(left: AppTheme.spaceSm),
                    child: ChoiceChip(
                      label: Text(type.displayName),
                      selected: filter.type == type,
                      showCheckmark: false,
                      onSelected: (_) => invoices.setFilter(filter.copyWith(type: type)),
                    ),
                  ),
                const SizedBox(width: AppTheme.spaceLg),
                FilterChip(
                  label: Text('status_overdue'.tr()),
                  selected: filter.overdueOnly,
                  onSelected: (value) => invoices.setFilter(filter.copyWith(overdueOnly: value)),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                FilterChip(
                  label: Text('payment_status_unpaid'.tr()),
                  selected: filter.paymentStatus == PaymentStatus.unpaid,
                  onSelected: (value) => invoices.setFilter(
                    value
                        ? filter.copyWith(paymentStatus: PaymentStatus.unpaid)
                        : filter.copyWith(clearPaymentStatus: true),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                FilterChip(
                  label: Text('invoice_status_draft'.tr()),
                  selected: filter.status == InvoiceStatus.draft,
                  onSelected: (value) => invoices.setFilter(
                    value
                        ? filter.copyWith(status: InvoiceStatus.draft)
                        : filter.copyWith(clearStatus: true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PagedListView<Invoice>(
              items: invoices.list.items,
              isLoading: invoices.list.isLoading,
              isLoadingMore: invoices.list.isLoadingMore,
              hasMore: invoices.list.data.hasMore,
              error: invoices.list.error,
              onRefresh: () => invoices.fetchInvoices(refresh: true),
              onLoadMore: invoices.loadMore,
              itemBuilder: (context, invoice) => InvoiceTile(invoice: invoice),
              emptyState: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: filter.isActive || filter.search.isNotEmpty
                    ? 'no_bills_match'.tr()
                    : 'no_bills_yet'.tr(),
                description: 'no_bills_yet_hint'.tr(),
                buttonText: 'new_bill'.tr(),
                buttonIcon: Icons.add_rounded,
                onButtonPressed: _chooseType,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
