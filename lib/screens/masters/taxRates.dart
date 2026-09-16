import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/inputFormatters.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/screens/common/pickers.dart';
import 'package:vyaparsetu/types/item.dart';

class TaxRatesScreen extends StatefulWidget {
  const TaxRatesScreen({super.key});

  @override
  State<TaxRatesScreen> createState() => _TaxRatesScreenState();
}

class _TaxRatesScreenState extends State<TaxRatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() => context.read<Core>().master.fetchTaxRates(refresh: true);

  Future<void> _setActive(TaxRate rate, bool isActive) async {
    final master = context.read<Core>().master;
    if (!await master.setTaxRateActive(rate.id, isActive: isActive)) {
      showErrorToast(master.error ?? 'error_generic'.tr());
    }
  }

  void _add() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _TaxRateSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final isAdmin = core.can(MemberRole.admin);

    return Scaffold(
      appBar: AppBar(title: Text('tax_rates'.tr())),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'add-tax-rate',
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
              label: Text('add_tax_rate'.tr()),
            )
          : null,
      body: LoadStateBody<List<TaxRate>>(
        state: core.master.taxRates,
        onRetry: _refresh,
        builder: (context, rates) {
          final sorted = [...rates]..sort((a, b) => a.rate.compareTo(b.rate));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceSm,
                AppTheme.spaceLg,
                AppTheme.fabClearance,
              ),
              children: [
                Text('tax_rates_hint'.tr(), style: context.text.bodyMedium),
                const SizedBox(height: AppTheme.spaceLg),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (index, rate) in sorted.indexed) ...[
                        if (index > 0) const Divider(indent: AppTheme.spaceLg),
                        ListTile(
                          title: Text(taxRateLabel(rate)),
                          subtitle: rate.cessRate > 0
                              ? Text('cess_rate_label'.tr(namedArgs: {
                                  'rate': Formatters.formatPercent(rate.cessRate),
                                }))
                              : null,
                          trailing: isAdmin
                              ? Switch(
                                  value: rate.isActive,
                                  onChanged: (value) => _setActive(rate, value),
                                )
                              : StatusChip(
                                  label: rate.isActive ? 'active'.tr() : 'inactive'.tr(),
                                  tone: rate.isActive ? ChipTone.success : ChipTone.neutral,
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TaxRateSheet extends StatefulWidget {
  const _TaxRateSheet();

  @override
  State<_TaxRateSheet> createState() => _TaxRateSheetState();
}

class _TaxRateSheetState extends State<_TaxRateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _rate = TextEditingController();
  final _cess = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _rate.dispose();
    _cess.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final master = context.read<Core>().master;
    final name = _name.text.trim();
    final created = await master.createTaxRate(
      rate: apiAmount(_rate.text)!,
      cessRate: apiAmount(_cess.text),
      name: name.isEmpty ? null : name,
    );
    if (!mounted) return;
    if (created == null) {
      showErrorToast(master.error ?? 'error_generic'.tr());
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<Core, bool>((c) => c.master.isSaving);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spaceLg,
        0,
        AppTheme.spaceLg,
        MediaQuery.viewInsetsOf(context).bottom + AppTheme.spaceLg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('add_tax_rate'.tr(), style: context.text.titleLarge),
            const SizedBox(height: AppTheme.spaceLg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _rate,
                    labelText: 'gst_rate'.tr(),
                    suffixText: '%',
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalInputFormatter()],
                    validator: (v) => Validators.required(v, 'gst_rate'.tr()) ?? Validators.percent(v),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: AppTextField(
                    controller: _cess,
                    labelText: 'cess_optional'.tr(),
                    suffixText: '%',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalInputFormatter()],
                    validator: Validators.percent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            AppTextField(controller: _name, labelText: 'name_optional'.tr(), maxLength: 50),
            const SizedBox(height: AppTheme.space2xl),
            AppButton(text: 'save'.tr(), isLoading: isSaving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
