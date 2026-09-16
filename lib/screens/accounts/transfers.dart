import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/formFields.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/pagedList.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/inputFormatters.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/screens/common/pickers.dart';
import 'package:vyaparsetu/types/account.dart';

/// Money moved between the business's own accounts (accountants).
class TransferListScreen extends StatefulWidget {
  const TransferListScreen({super.key});

  @override
  State<TransferListScreen> createState() => _TransferListScreenState();
}

class _TransferListScreenState extends State<TransferListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<Core>().account.fetchTransfers(refresh: true),
    );
  }

  void _new() => Navigator.of(context).push(getPageRoute(const TransferFormScreen()));

  Future<void> _cancel(Transfer transfer) async {
    final reason = await showReasonDialog(
      context,
      title: 'cancel_transfer_title'.tr(),
      message: 'cancel_transfer_message'.tr(namedArgs: {
        'amount': Formatters.formatCurrency(transfer.amount),
      }),
      confirmText: 'cancel_transfer'.tr(),
    );
    if (reason == null || !mounted) return;
    final accounts = context.read<Core>().account;
    if (await accounts.cancelTransfer(transfer.id, reason: reason.isEmpty ? null : reason)) {
      showSuccessToast('transfer_cancelled'.tr());
    } else {
      showErrorToast(accounts.error ?? 'error_generic'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final transfers = core.account.transfers;
    scheduleReload(transfers.needsReload, () => core.account.fetchTransfers(refresh: true));

    return Scaffold(
      appBar: AppBar(title: Text('transfers'.tr())),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-transfer',
        onPressed: _new,
        icon: const Icon(Icons.compare_arrows_rounded),
        label: Text('transfer_money'.tr()),
      ),
      body: PagedListView<Transfer>(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLg,
          AppTheme.spaceSm,
          AppTheme.spaceLg,
          AppTheme.fabClearance,
        ),
        items: transfers.items,
        isLoading: transfers.isLoading,
        isLoadingMore: transfers.isLoadingMore,
        hasMore: transfers.data.hasMore,
        error: transfers.error,
        onRefresh: () => core.account.fetchTransfers(refresh: true),
        onLoadMore: () => core.account.fetchTransfers(more: true),
        emptyState: EmptyState(
          icon: Icons.compare_arrows_rounded,
          title: 'no_transfers_yet'.tr(),
          description: 'transfers_hint'.tr(),
          buttonText: 'transfer_money'.tr(),
          onButtonPressed: _new,
        ),
        itemBuilder: (context, transfer) {
          final cancelled = transfer.status.value == 'cancelled';
          return AppCard(
            onLongPress: cancelled ? null : () => _cancel(transfer),
            onTap: cancelled ? null : () => _cancel(transfer),
            child: Row(
              children: [
                Icon(Icons.compare_arrows_rounded, color: context.colors.inkSecondary),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${transfer.fromAccountName} → ${transfer.toAccountName}',
                        style: context.text.titleSmall,
                      ),
                      Text(
                        [Formatters.formatDate(transfer.transferDate), ?transfer.notes].join(' · '),
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
                      amount: transfer.amount,
                      style: context.text.titleSmall?.copyWith(
                        decoration: cancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (cancelled) StatusChip.forRecord(transfer.status),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TransferFormScreen extends StatefulWidget {
  const TransferFormScreen({super.key});

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  Account? _from;
  Account? _to;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final accounts = context.read<Core>().account;
    final notes = _notes.text.trim();
    final navigator = Navigator.of(context);
    final saved = await accounts.createTransfer({
      'transfer_date': apiDate(_date),
      'from_account_id': _from!.id,
      'to_account_id': _to!.id,
      'amount': apiAmount(_amount.text),
      'notes': notes.isEmpty ? null : notes,
    });
    if (!mounted) return;
    if (saved == null) {
      showErrorToast(accounts.error ?? 'error_generic'.tr());
      return;
    }
    showSuccessToast('transfer_saved'.tr());
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<Core, bool>((c) => c.account.isSaving);

    return Scaffold(
      appBar: AppBar(title: Text('transfer_money'.tr())),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          children: [
            FormSection(
              title: 'transfer_details'.tr(),
              subtitle: 'transfers_hint'.tr(),
              children: [
                SelectField<Account>(
                  label: 'from_account'.tr(),
                  value: _from,
                  prefixIcon: Icons.logout_rounded,
                  labelOf: (account) => account.name,
                  onPick: () => pickAccount(context, selectedId: _from?.id, excludeId: _to?.id),
                  onChanged: (account) => setState(() => _from = account),
                  validator: (account) => account == null
                      ? 'validation_required'.tr(namedArgs: {'field': 'from_account'.tr()})
                      : null,
                ),
                SelectField<Account>(
                  label: 'to_account'.tr(),
                  value: _to,
                  prefixIcon: Icons.login_rounded,
                  labelOf: (account) => account.name,
                  onPick: () => pickAccount(context, selectedId: _to?.id, excludeId: _from?.id),
                  onChanged: (account) => setState(() => _to = account),
                  validator: (account) {
                    if (account == null) {
                      return 'validation_required'.tr(namedArgs: {'field': 'to_account'.tr()});
                    }
                    return account.id == _from?.id ? 'validation_same_account'.tr() : null;
                  },
                ),
                AppTextField(
                  controller: _amount,
                  labelText: 'amount'.tr(),
                  prefixText: '₹ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter()],
                  validator: (v) => Validators.amount(v, fieldLabel: 'amount'.tr(), allowZero: false),
                ),
                DateField(
                  label: 'date'.tr(),
                  value: _date,
                  lastDate: DateTime.now(),
                  onChanged: (date) => setState(() => _date = date ?? _date),
                ),
                AppTextField(
                  controller: _notes,
                  labelText: 'notes_optional'.tr(),
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: AppButton(text: 'save_transfer'.tr(), isLoading: isSaving, onPressed: _save),
        ),
      ),
    );
  }
}
