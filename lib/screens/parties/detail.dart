import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/avatar.dart';
import 'package:vyaparsetu/components/infoRow.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/gst.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/screens/common/ledgerView.dart';
import 'package:vyaparsetu/screens/invoices/form.dart';
import 'package:vyaparsetu/screens/invoices/widgets.dart';
import 'package:vyaparsetu/screens/parties/form.dart';
import 'package:vyaparsetu/screens/payments/form.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/types/party.dart';

class PartyDetailScreen extends StatefulWidget {
  final String partyId;

  const PartyDetailScreen({super.key, required this.partyId});

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  List<Invoice>? _bills;
  bool _showLedger = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(refresh: true));
  }

  Future<void> _load({bool refresh = false}) async {
    final core = context.read<Core>();
    await Future.wait([
      core.party.getParty(widget.partyId, refresh: refresh),
      _loadBills(core),
      if (core.can(MemberRole.accountant))
        core.party.fetchLedger(widget.partyId, refresh: refresh),
    ]);
  }

  Future<void> _loadBills(Core core) async {
    final bills = await core.invoice.invoicesForParty(widget.partyId);
    if (mounted) setState(() => _bills = bills);
  }

  void _push(Widget screen) => Navigator.of(context).push(getPageRoute(screen));

  static String? _whatsAppNumber(String? phone) {
    final digits = phone?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.length == 10) return '91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return digits;
    if (digits.length == 11 && digits.startsWith('0')) return '91${digits.substring(1)}';
    return null;
  }

  Future<void> _remind(Party party) async {
    final number = _whatsAppNumber(party.phone);
    if (number == null) return;
    final business = context.read<Core>().business.selectedBusiness?.name ?? '';
    final message = 'payment_reminder_message'.tr(namedArgs: {
      'name': party.name,
      'amount': Formatters.formatCurrency(party.balance),
      'business': business,
    });
    final uri = Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showErrorToast('whatsapp_open_failed'.tr());
    }
  }

  Future<void> _call(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _toggleArchive(Party party) async {
    final parties = context.read<Core>().party;
    final saved = await parties.setArchived(party.id, archived: !party.isArchived);
    if (saved == null) {
      showErrorToast(parties.error ?? 'error_generic'.tr());
    } else {
      showSuccessToast(saved.isArchived ? 'party_archived'.tr() : 'party_restored'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final state = core.party.detail(widget.partyId);
    final ledger = core.party.ledger(widget.partyId);
    final canSeeLedger = core.can(MemberRole.accountant);
    scheduleReload(
      state.needsReload || (canSeeLedger && ledger.needsReload),
      () => _load(refresh: true),
    );
    final party = state.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(party?.name ?? 'party'.tr()),
        actions: [
          if (party != null)
            IconButton(
              tooltip: 'edit'.tr(),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _push(PartyFormScreen(party: party)),
            ),
          if (party != null && canSeeLedger)
            PopupMenuButton<String>(
              onSelected: (_) => _toggleArchive(party),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'archive',
                  child: Text(party.isArchived ? 'restore'.tr() : 'archive'.tr()),
                ),
              ],
            ),
        ],
      ),
      body: LoadStateBody<Party>(
        state: state,
        onRetry: () => _load(refresh: true),
        builder: (context, party) => RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceLg,
              AppTheme.spaceSm,
              AppTheme.spaceLg,
              AppTheme.space3xl,
            ),
            children: [
              _buildHeader(context, party),
              if (party.addresses.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceMd),
                _buildAddresses(context, party),
              ],
              const SizedBox(height: AppTheme.spaceMd),
              _buildActions(party),
              const SizedBox(height: AppTheme.space2xl),
              if (canSeeLedger) ...[
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: Text('bills'.tr()),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text('ledger'.tr()),
                    ),
                  ],
                  selected: {_showLedger},
                  onSelectionChanged: (selection) => setState(() => _showLedger = selection.first),
                ),
                const SizedBox(height: AppTheme.spaceMd),
              ],
              if (_showLedger && canSeeLedger)
                LedgerView(
                  state: ledger,
                  isAccount: false,
                  onRetry: () => core.party.fetchLedger(widget.partyId, refresh: true),
                )
              else
                ..._buildBills(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Party party) {
    final phone = party.phone;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialsAvatar(name: party.name, size: 48),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(party.name, style: context.text.titleLarge),
                    Text(
                      [party.partyType.displayName, party.gstType.displayName].join(' · '),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (party.isArchived) StatusChip(label: 'archived'.tr()),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLg),
          Text(
            party.isSettled
                ? 'settled'.tr()
                : party.balance > 0
                ? 'you_will_get'.tr()
                : 'you_will_give'.tr(),
            style: context.text.labelMedium,
          ),
          if (!party.isSettled)
            AmountDisplay(
              amount: party.balance.abs(),
              tone: party.balance > 0 ? AmountTone.positive : AmountTone.negative,
              style: context.text.headlineSmall,
            ),
          const Divider(height: AppTheme.space2xl),
          InfoRow(
            label: 'phone'.tr(),
            icon: Icons.phone_outlined,
            valueWidget: phone == null
                ? null
                : InkWell(
                    onTap: () => _call(phone),
                    child: Text(
                      phone,
                      style: context.text.titleSmall?.copyWith(color: context.colors.primary),
                    ),
                  ),
          ),
          InfoRow(label: 'email'.tr(), icon: Icons.mail_outline_rounded, value: party.email),
          InfoRow(label: 'gstin'.tr(), icon: Icons.verified_outlined, value: party.gstin),
          InfoRow(label: 'state'.tr(), icon: Icons.place_outlined, value: stateNameFromCode(party.stateCode)),
          InfoRow(
            label: 'credit_days'.tr(),
            icon: Icons.schedule_outlined,
            value: party.creditDays == null
                ? null
                : 'days_count'.tr(namedArgs: {'count': '${party.creditDays}'}),
          ),
          InfoRow(
            label: 'credit_limit'.tr(),
            icon: Icons.speed_outlined,
            value: party.creditLimit == null ? null : Formatters.formatCurrency(party.creditLimit!),
          ),
        ],
      ),
    );
  }

  Widget _buildAddresses(BuildContext context, Party party) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, address) in party.addresses.indexed) ...[
            if (index > 0) const Divider(indent: 56),
            ListTile(
              leading: Icon(
                address.kind == AddressKind.billing
                    ? Icons.receipt_long_outlined
                    : Icons.local_shipping_outlined,
                color: context.colors.inkSecondary,
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(address.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (address.isDefault) ...[
                    const SizedBox(width: AppTheme.spaceSm),
                    StatusChip(label: 'default_address'.tr(), tone: ChipTone.primary),
                  ],
                ],
              ),
              subtitle: Text('${address.kind.displayName} · ${address.address.singleLine}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(Party party) {
    final paysUs = party.balance > 0 || (party.partyType.canSell && party.balance >= 0);
    final canRemind = party.balance > 0 && _whatsAppNumber(party.phone) != null;

    return Wrap(
      spacing: AppTheme.spaceSm,
      runSpacing: AppTheme.spaceSm,
      children: [
        if (party.partyType.canSell)
          AppButton(
            text: 'new_sale'.tr(),
            icon: Icons.receipt_long_rounded,
            compact: true,
            expand: false,
            onPressed: () => _push(InvoiceFormScreen(type: InvoiceType.sale, party: party)),
          ),
        if (party.partyType.canBuy)
          AppButton(
            text: 'new_purchase'.tr(),
            icon: Icons.shopping_bag_outlined,
            compact: true,
            expand: false,
            variant: party.partyType.canSell ? AppButtonVariant.secondary : AppButtonVariant.primary,
            onPressed: () => _push(InvoiceFormScreen(type: InvoiceType.purchase, party: party)),
          ),
        AppButton(
          text: paysUs ? 'receive_payment'.tr() : 'make_payment'.tr(),
          icon: paysUs ? Icons.call_received_rounded : Icons.call_made_rounded,
          compact: true,
          expand: false,
          variant: AppButtonVariant.outline,
          onPressed: () => _push(PaymentFormScreen(
            direction: paysUs ? PaymentDirection.paymentIn : PaymentDirection.paymentOut,
            party: party,
          )),
        ),
        if (canRemind)
          AppButton(
            text: 'send_reminder'.tr(),
            icon: Icons.chat_outlined,
            compact: true,
            expand: false,
            variant: AppButtonVariant.outline,
            onPressed: () => _remind(party),
          ),
      ],
    );
  }

  List<Widget> _buildBills(BuildContext context) {
    final bills = _bills;
    if (bills == null) return const [SizedBox(height: 160, child: LoadingIndicator())];
    if (bills.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(AppTheme.space2xl),
          child: Text(
            'no_bills_for_party'.tr(),
            style: context.text.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }
    return [
      for (final bill in bills)
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
          child: InvoiceTile(invoice: bill),
        ),
    ];
  }
}
