import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appButton.dart';
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
import 'package:vyaparsetu/screens/expenses/form.dart';
import 'package:vyaparsetu/screens/parties/detail.dart';
import 'package:vyaparsetu/screens/payments/detail.dart';
import 'package:vyaparsetu/screens/payments/form.dart';
import 'package:vyaparsetu/types/expense.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final String expenseId;

  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() =>
      context.read<Core>().expense.getExpense(widget.expenseId, refresh: true);

  void _push(Widget screen) => Navigator.of(context).push(getPageRoute(screen));

  Future<void> _cancel(Expense expense) async {
    final reason = await showReasonDialog(
      context,
      title: 'cancel_expense_title'.tr(),
      message: 'cancel_expense_message'.tr(),
      confirmText: 'cancel_expense'.tr(),
    );
    if (reason == null || !mounted) return;
    final expenses = context.read<Core>().expense;
    final saved = await expenses.cancelExpense(expense.id, reason: reason.isEmpty ? null : reason);
    if (saved == null) {
      showErrorToast(expenses.error ?? 'error_generic'.tr());
    } else {
      showSuccessToast('expense_cancelled'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final state = core.expense.detail(widget.expenseId);
    scheduleReload(state.needsReload, _refresh);
    final expense = state.value;
    final canManage = expense != null && !expense.isCancelled && core.can(MemberRole.accountant);

    return Scaffold(
      appBar: AppBar(
        title: Text(expense?.expenseNumber ?? 'expense'.tr()),
        actions: [
          if (canManage) ...[
            IconButton(
              tooltip: 'edit'.tr(),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _push(ExpenseFormScreen(expense: expense)),
            ),
            PopupMenuButton<String>(
              onSelected: (_) => _cancel(expense),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'cancel', child: Text('cancel_expense'.tr())),
              ],
            ),
          ],
        ],
      ),
      body: LoadStateBody<Expense>(
        state: state,
        onRetry: _refresh,
        builder: (context, expense) => RefreshIndicator(
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
                            expense.categoryName ?? 'uncategorised'.tr(),
                            style: context.text.labelMedium,
                          ),
                        ),
                        expense.isCancelled
                            ? StatusChip.forRecord(expense.status)
                            : StatusChip.forPayment(expense.paymentStatus),
                      ],
                    ),
                    AmountDisplay(
                      amount: expense.totalAmount,
                      style: context.text.headlineMedium?.copyWith(
                        decoration: expense.isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (!expense.isCancelled && expense.outstanding > 0.004)
                      Text(
                        'due_amount'.tr(namedArgs: {
                          'amount': Formatters.formatCurrency(expense.outstanding),
                        }),
                        style: context.text.bodyMedium?.copyWith(color: context.colors.warning),
                      ),
                    const Divider(height: AppTheme.space2xl),
                    InfoRow(label: 'date'.tr(), value: Formatters.formatDate(expense.expenseDate)),
                    InfoRow(
                      label: 'vendor'.tr(),
                      valueWidget: expense.partyId == null
                          ? null
                          : InkWell(
                              onTap: () => _push(PartyDetailScreen(partyId: expense.partyId!)),
                              child: Text(
                                expense.partyName ?? '',
                                style: context.text.titleSmall?.copyWith(
                                  color: context.colors.primary,
                                ),
                              ),
                            ),
                    ),
                    if (expense.taxMode == TaxMode.gst) ...[
                      InfoRow(
                        label: 'amount_before_tax'.tr(),
                        value: Formatters.formatCurrency(expense.taxableAmount),
                      ),
                      if (expense.cgstAmount > 0)
                        InfoRow(label: 'cgst'.tr(), value: Formatters.formatCurrency(expense.cgstAmount)),
                      if (expense.sgstAmount > 0)
                        InfoRow(label: 'sgst'.tr(), value: Formatters.formatCurrency(expense.sgstAmount)),
                      if (expense.igstAmount > 0)
                        InfoRow(label: 'igst'.tr(), value: Formatters.formatCurrency(expense.igstAmount)),
                      if (expense.cessAmount > 0)
                        InfoRow(label: 'cess'.tr(), value: Formatters.formatCurrency(expense.cessAmount)),
                      InfoRow(
                        label: 'itc_eligible'.tr(),
                        value: expense.itcEligible ? 'yes'.tr() : 'no'.tr(),
                      ),
                    ],
                    InfoRow(label: 'notes'.tr(), value: expense.notes),
                    if (expense.isCancelled)
                      InfoRow(
                        label: 'cancel_reason'.tr(),
                        value: expense.cancelReason ?? 'no_reason_given'.tr(),
                      ),
                  ],
                ),
              ),
              if (!expense.isCancelled && expense.outstanding > 0.004 && expense.partyId != null) ...[
                const SizedBox(height: AppTheme.spaceMd),
                AppButton(
                  text: 'record_payment'.tr(),
                  icon: Icons.call_made_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _push(const PaymentFormScreen(direction: PaymentDirection.paymentOut)),
                ),
              ],
              const SizedBox(height: AppTheme.spaceLg),
              SectionHeader(title: 'payments'.tr()),
              if (expense.payments.isEmpty)
                Text('no_payments_recorded'.tr(), style: context.text.bodyMedium)
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (index, link) in expense.payments.indexed) ...[
                        if (index > 0) const Divider(indent: AppTheme.spaceLg),
                        ListTile(
                          title: Text(link.paymentNumber),
                          subtitle: Text([
                            if (link.paymentDate != null) Formatters.formatDate(link.paymentDate!),
                            link.mode.displayName,
                          ].join(' · ')),
                          trailing: AmountDisplay(amount: link.amount, style: context.text.titleSmall),
                          onTap: () => _push(PaymentDetailScreen(paymentId: link.paymentId)),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
