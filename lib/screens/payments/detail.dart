import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/components/infoRow.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/sectionHeader.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/screens/expenses/detail.dart';
import 'package:vyaparsetu/screens/invoices/detail.dart';
import 'package:vyaparsetu/screens/parties/detail.dart';
import 'package:vyaparsetu/screens/payments/form.dart';
import 'package:vyaparsetu/types/payment.dart';

class PaymentDetailScreen extends StatefulWidget {
  final String paymentId;

  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() =>
      context.read<Core>().payment.getPayment(widget.paymentId, refresh: true);

  void _push(Widget screen) => Navigator.of(context).push(getPageRoute(screen));

  Future<void> _cancel(Payment payment) async {
    final reason = await showReasonDialog(
      context,
      title: 'cancel_payment_title'.tr(),
      message: 'cancel_payment_message'.tr(namedArgs: {
        'amount': Formatters.formatCurrency(payment.amount),
      }),
      confirmText: 'cancel_payment'.tr(),
    );
    if (reason == null || !mounted) return;
    final payments = context.read<Core>().payment;
    final saved = await payments.cancelPayment(payment.id, reason: reason.isEmpty ? null : reason);
    if (saved == null) {
      showErrorToast(payments.error ?? 'error_generic'.tr());
    } else {
      showSuccessToast('payment_cancelled'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final state = core.payment.detail(widget.paymentId);
    scheduleReload(state.needsReload, _refresh);
    final payment = state.value;
    final canManage = payment != null && !payment.isCancelled && core.can(MemberRole.accountant);

    return Scaffold(
      appBar: AppBar(
        title: Text(payment?.paymentNumber ?? 'payment'.tr()),
        actions: [
          if (canManage) ...[
            IconButton(
              tooltip: 'edit'.tr(),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _push(PaymentFormScreen(payment: payment)),
            ),
            PopupMenuButton<String>(
              onSelected: (_) => _cancel(payment),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'cancel', child: Text('cancel_payment'.tr())),
              ],
            ),
          ],
        ],
      ),
      body: LoadStateBody<Payment>(
        state: state,
        onRetry: _refresh,
        builder: (context, payment) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceLg,
              AppTheme.spaceSm,
              AppTheme.spaceLg,
              AppTheme.space3xl,
            ),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            payment.isIn ? 'payment_received'.tr() : 'payment_made'.tr(),
                            style: context.text.labelMedium,
                          ),
                        ),
                        StatusChip.forRecord(payment.status),
                      ],
                    ),
                    AmountDisplay(
                      amount: payment.amount,
                      tone: payment.isIn ? AmountTone.positive : AmountTone.negative,
                      style: context.text.headlineMedium?.copyWith(
                        decoration: payment.isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const Divider(height: AppTheme.space2xl),
                    InfoRow(
                      label: payment.isIn ? 'received_from'.tr() : 'paid_to'.tr(),
                      valueWidget: payment.partyId == null
                          ? Text('no_party'.tr())
                          : InkWell(
                              onTap: () => _push(PartyDetailScreen(partyId: payment.partyId!)),
                              child: Text(
                                payment.partyName ?? '',
                                style: context.text.titleSmall?.copyWith(
                                  color: context.colors.primary,
                                ),
                              ),
                            ),
                    ),
                    InfoRow(label: 'date'.tr(), value: Formatters.formatDate(payment.paymentDate)),
                    InfoRow(label: 'payment_mode'.tr(), value: payment.mode.displayName),
                    InfoRow(
                      label: payment.isIn ? 'deposit_to'.tr() : 'paid_from'.tr(),
                      value: payment.accountName,
                    ),
                    InfoRow(label: 'reference'.tr(), value: payment.referenceNo),
                    InfoRow(label: 'cheque_number'.tr(), value: payment.chequeNo),
                    InfoRow(
                      label: 'cheque_date'.tr(),
                      value: payment.chequeDate == null ? null : Formatters.formatDate(payment.chequeDate!),
                    ),
                    InfoRow(label: 'notes'.tr(), value: payment.notes),
                    if (payment.isCancelled)
                      InfoRow(
                        label: 'cancel_reason'.tr(),
                        value: payment.cancelReason ?? 'no_reason_given'.tr(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              SectionHeader(title: 'settled_bills'.tr()),
              if (payment.allocations.isEmpty)
                Text('payment_not_allocated'.tr(), style: context.text.bodyMedium)
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (index, allocation) in payment.allocations.indexed) ...[
                        if (index > 0) const Divider(indent: AppTheme.spaceLg),
                        ListTile(
                          title: Text(allocation.documentNumber ?? ''),
                          subtitle: Text([
                            if (allocation.invoiceChargeId != null)
                              'freight_charge'.tr()
                            else if (allocation.expenseId != null)
                              'expense'.tr()
                            else
                              'bill'.tr(),
                            if (allocation.documentDate != null)
                              Formatters.formatDate(allocation.documentDate!),
                          ].join(' · ')),
                          trailing: AmountDisplay(
                            amount: allocation.amount,
                            style: context.text.titleSmall,
                          ),
                          onTap: allocation.expenseId != null
                              ? () => _push(ExpenseDetailScreen(expenseId: allocation.expenseId!))
                              : allocation.invoiceId != null
                              ? () => _push(InvoiceDetailScreen(invoiceId: allocation.invoiceId!))
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              if (payment.unallocatedAmount > 0.004) ...[
                const SizedBox(height: AppTheme.spaceMd),
                AppCard(
                  color: context.colors.infoSoft,
                  borderColor: Colors.transparent,
                  child: Text(
                    'advance_note'.tr(namedArgs: {
                      'amount': Formatters.formatCurrency(payment.unallocatedAmount),
                    }),
                    style: context.text.bodyMedium?.copyWith(color: context.colors.info),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
