import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/avatar.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/infoRow.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/expenses/detail.dart';
import 'package:vyaparsetu/screens/invoices/detail.dart';
import 'package:vyaparsetu/screens/parties/detail.dart';
import 'package:vyaparsetu/types/reports.dart';

/// Who owes the business (receivables) or whom it owes (payables), by age.
class OutstandingScreen extends StatefulWidget {
  final OutstandingType type;

  const OutstandingScreen({super.key, required this.type});

  @override
  State<OutstandingScreen> createState() => _OutstandingScreenState();
}

class _OutstandingScreenState extends State<OutstandingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() =>
      context.read<Core>().report.fetchOutstanding(widget.type, refresh: true);

  void _push(Widget screen) => Navigator.of(context).push(getPageRoute(screen));

  void _openDocument(OutstandingDocument doc) {
    switch (doc.kind) {
      case 'invoice':
        _push(InvoiceDetailScreen(invoiceId: doc.id));
      case 'expense':
        _push(ExpenseDetailScreen(expenseId: doc.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final isReceivable = widget.type == OutstandingType.receivable;
    final state = core.report.outstanding(widget.type);
    scheduleReload(state.needsReload, _refresh);

    return Scaffold(
      appBar: AppBar(
        title: Text(isReceivable ? 'report_receivables'.tr() : 'report_payables'.tr()),
      ),
      body: LoadStateBody<OutstandingReport>(
        state: state,
        onRetry: _refresh,
        builder: (context, report) {
          final groups = <String, List<OutstandingDocument>>{};
          for (final doc in report.documents) {
            groups.putIfAbsent(doc.partyId ?? doc.partyName, () => []).add(doc);
          }
          final sortedGroups = groups.entries.toList()
            ..sort((a, b) => _sum(b.value).compareTo(_sum(a.value)));

          return RefreshIndicator(
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
                      Text(
                        isReceivable ? 'to_collect'.tr() : 'to_pay'.tr(),
                        style: context.text.labelMedium,
                      ),
                      AmountDisplay(
                        amount: report.total,
                        tone: isReceivable ? AmountTone.positive : AmountTone.negative,
                        style: context.text.headlineMedium,
                      ),
                      const Divider(height: AppTheme.space2xl),
                      for (final key in OutstandingReport.bucketKeys)
                        InfoRow(
                          label: 'bucket_$key'.tr(),
                          valueWidget: Text(
                            Formatters.formatCurrency(report.buckets[key] ?? 0),
                            style: context.text.titleSmall?.copyWith(
                              color: key != 'not_due' && (report.buckets[key] ?? 0) > 0
                                  ? context.colors.danger
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),
                if (report.documents.isEmpty)
                  EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: isReceivable ? 'nothing_to_collect'.tr() : 'nothing_to_pay'.tr(),
                    description: 'all_settled_hint'.tr(),
                  ),
                for (final group in sortedGroups)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            leading: InitialsAvatar(name: group.value.first.partyName, size: 36),
                            title: Text(
                              group.value.first.partyName.isEmpty
                                  ? 'walk_in_customer'.tr()
                                  : group.value.first.partyName,
                              style: context.text.titleSmall,
                            ),
                            trailing: AmountDisplay(
                              amount: _sum(group.value),
                              tone: isReceivable ? AmountTone.positive : AmountTone.negative,
                              style: context.text.titleSmall,
                            ),
                            onTap: group.value.first.partyId == null
                                ? null
                                : () => _push(PartyDetailScreen(partyId: group.value.first.partyId!)),
                          ),
                          const Divider(height: 1),
                          for (final doc in group.value)
                            ListTile(
                              dense: true,
                              onTap: doc.kind == 'charge' ? null : () => _openDocument(doc),
                              title: Text(
                                '${doc.kind == 'charge' ? 'freight_charge'.tr() : doc.kind == 'expense' ? 'expense'.tr() : InvoiceType.fromString(doc.documentType).displayName} · ${doc.number}',
                              ),
                              subtitle: Text(
                                [
                                  if (doc.documentDate != null) Formatters.formatDate(doc.documentDate!),
                                  doc.daysOverdue > 0
                                      ? 'days_overdue'.tr(namedArgs: {'count': '${doc.daysOverdue}'})
                                      : 'not_due_yet'.tr(),
                                ].join(' · '),
                                style: doc.daysOverdue > 0
                                    ? TextStyle(color: context.colors.danger)
                                    : null,
                              ),
                              trailing: Text(
                                Formatters.formatCurrency(doc.outstanding),
                                style: context.text.labelLarge,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static double _sum(List<OutstandingDocument> docs) =>
      docs.fold(0.0, (sum, doc) => sum + doc.outstanding);
}
