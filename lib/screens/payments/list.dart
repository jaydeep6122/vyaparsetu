import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/pagedList.dart';
import 'package:vyaparsetu/components/searchBar.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/payments/detail.dart';
import 'package:vyaparsetu/screens/payments/form.dart';
import 'package:vyaparsetu/types/payment.dart';

/// Asks whether money is coming in or going out, then opens the form.
Future<void> startNewPayment(BuildContext context) async {
  final direction = await showModalBottomSheet<PaymentDirection>(
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
            child: Text('new_payment'.tr(), style: sheetContext.text.titleLarge),
          ),
          ListTile(
            leading: Icon(Icons.call_received_rounded, color: sheetContext.colors.success),
            title: Text('payment_in_title'.tr()),
            subtitle: Text('payment_in_hint'.tr()),
            onTap: () => Navigator.of(sheetContext).pop(PaymentDirection.paymentIn),
          ),
          ListTile(
            leading: Icon(Icons.call_made_rounded, color: sheetContext.colors.danger),
            title: Text('payment_out_title'.tr()),
            subtitle: Text('payment_out_hint'.tr()),
            onTap: () => Navigator.of(sheetContext).pop(PaymentDirection.paymentOut),
          ),
          const SizedBox(height: AppTheme.spaceSm),
        ],
      ),
    ),
  );
  if (direction == null || !context.mounted) return;
  await Navigator.of(context).push(getPageRoute(PaymentFormScreen(direction: direction)));
}

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<Core>().payment.fetchPayments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final payments = core.payment;
    scheduleReload(payments.list.needsReload, () => payments.fetchPayments(refresh: true));

    return Scaffold(
      appBar: AppBar(title: Text('payments'.tr())),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-payment',
        onPressed: () => startNewPayment(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('new_payment'.tr()),
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
              hintText: 'search_payments'.tr(),
              initialValue: payments.search,
              onChanged: (query) => payments.setFilters(search: query),
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
                  selected: payments.direction == null,
                  showCheckmark: false,
                  onSelected: (_) => payments.setFilters(clearDirection: true),
                ),
                for (final direction in PaymentDirection.values)
                  Padding(
                    padding: const EdgeInsets.only(left: AppTheme.spaceSm),
                    child: ChoiceChip(
                      label: Text(direction.displayName),
                      selected: payments.direction == direction,
                      showCheckmark: false,
                      onSelected: (_) => payments.setFilters(direction: direction),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PagedListView<Payment>(
              items: payments.list.items,
              isLoading: payments.list.isLoading,
              isLoadingMore: payments.list.isLoadingMore,
              hasMore: payments.list.data.hasMore,
              error: payments.list.error,
              onRefresh: () => payments.fetchPayments(refresh: true),
              onLoadMore: payments.loadMore,
              emptyState: EmptyState(
                icon: Icons.swap_vert_rounded,
                title: 'no_payments_yet'.tr(),
                description: 'no_payments_yet_hint'.tr(),
                buttonText: 'new_payment'.tr(),
                onButtonPressed: () => startNewPayment(context),
              ),
              itemBuilder: (context, payment) => PaymentTile(payment: payment),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentTile extends StatelessWidget {
  final Payment payment;

  const PaymentTile({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = toneColors(
      context,
      payment.isIn ? ChipTone.success : ChipTone.danger,
    );

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      onTap: () => Navigator.of(context).push(
        getPageRoute(PaymentDetailScreen(paymentId: payment.id)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(
              payment.isIn ? Icons.call_received_rounded : Icons.call_made_rounded,
              color: foreground,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.partyName ?? 'no_party'.tr(),
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    payment.paymentNumber,
                    Formatters.formatDate(payment.paymentDate),
                    payment.mode.displayName,
                  ].join(' · '),
                  style: context.text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountDisplay(
                amount: payment.amount,
                tone: payment.isCancelled
                    ? AmountTone.neutral
                    : payment.isIn
                    ? AmountTone.positive
                    : AmountTone.negative,
                style: context.text.titleSmall?.copyWith(
                  decoration: payment.isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              if (payment.isCancelled) StatusChip.forRecord(payment.status),
            ],
          ),
        ],
      ),
    );
  }
}
