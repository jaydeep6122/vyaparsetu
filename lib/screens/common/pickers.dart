import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/pickerSheet.dart';
import 'package:vyaparsetu/components/textInputDialog.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/screens/items/form.dart';
import 'package:vyaparsetu/screens/parties/form.dart';
import 'package:vyaparsetu/types/account.dart';
import 'package:vyaparsetu/types/item.dart';
import 'package:vyaparsetu/types/party.dart';

/// "GST 18%" (or the rate's own name).
String taxRateLabel(TaxRate rate) => rate.name.trim().isNotEmpty
    ? rate.name
    : 'gst_rate_label'.tr(namedArgs: {'rate': Formatters.formatPercent(rate.rate)});

/// Searches parties on the server; can add a new one without leaving.
Future<Party?> pickParty(
  BuildContext context, {
  PartyType? type,
  String? selectedId,
  String? title,
}) {
  final core = context.read<Core>();
  final text = context.text;

  return showPickerSheet<Party>(
    context: context,
    title: title ?? 'select_party'.tr(),
    labelOf: (party) => party.name,
    subtitleOf: (party) => [party.partyType.displayName, ?party.phone, ?party.gstin].join(' · '),
    trailingOf: (party) => party.isSettled
        ? null
        : AmountDisplay(
            amount: party.balance.abs(),
            tone: party.balance > 0 ? AmountTone.positive : AmountTone.negative,
            style: text.labelLarge,
          ),
    isSelected: (party) => party.id == selectedId,
    onSearch: (query) => core.party.searchParties(query, type: type),
    searchHint: 'search_parties'.tr(),
    emptyText: 'no_parties_found'.tr(),
    createLabel: 'add_new_party'.tr(),
    onCreate: (sheetContext) => Navigator.of(sheetContext).push<Party>(
      getPageRoute(PartyFormScreen(initialType: type ?? PartyType.customer)),
    ),
  );
}

/// Searches items on the server; can add a new one without leaving.
Future<Item?> pickItem(BuildContext context, {InvoiceType? priceFor}) {
  final core = context.read<Core>();

  return showPickerSheet<Item>(
    context: context,
    title: 'select_item'.tr(),
    labelOf: (item) => item.name,
    subtitleOf: (item) {
      final price = priceFor == null ? null : item.priceFor(priceFor);
      return [
        if (price != null) '${Formatters.formatCurrency(price)} / ${item.unitCode}',
        if (item.trackStock)
          'in_stock_quantity'.tr(namedArgs: {
            'quantity': Formatters.formatQuantity(item.quantityOnHand ?? 0, item.unitCode),
          }),
        if (item.taxRate != null) 'gst_rate_label'.tr(namedArgs: {'rate': Formatters.formatPercent(item.taxRate!)}),
      ].join(' · ');
    },
    onSearch: core.item.searchItems,
    searchHint: 'search_items'.tr(),
    emptyText: 'no_items_found'.tr(),
    createLabel: 'add_new_item'.tr(),
    onCreate: (sheetContext) => Navigator.of(sheetContext).push<Item>(
      getPageRoute(const ItemFormScreen()),
    ),
  );
}

Future<Category?> pickCategory(
  BuildContext context,
  CategoryKind kind, {
  String? selectedId,
}) async {
  final core = context.read<Core>();
  await core.master.fetchCategories(kind);
  if (!context.mounted) return null;

  return showPickerSheet<Category>(
    context: context,
    title: kind == CategoryKind.item
        ? 'select_item_category'.tr()
        : 'select_expense_category'.tr(),
    options: core.master.activeCategories(kind),
    labelOf: (category) => category.name,
    isSelected: (category) => category.id == selectedId,
    emptyText: 'no_categories_yet'.tr(),
    createLabel: 'add_new_category'.tr(),
    onCreate: (sheetContext) async {
      final name = await showTextInputDialog(
        sheetContext,
        title: 'new_category'.tr(),
        label: 'category_name'.tr(),
        textCapitalization: TextCapitalization.words,
      );
      if (name == null) return null;
      final created = await core.master.createCategory(kind, name);
      if (created == null) showErrorToast(core.master.error ?? 'error_generic'.tr());
      return created;
    },
  );
}

Future<TaxRate?> pickTaxRate(BuildContext context, {String? selectedId}) async {
  final core = context.read<Core>();
  await core.master.fetchTaxRates();
  if (!context.mounted) return null;

  final rates = [...core.master.activeTaxRates]..sort((a, b) => a.rate.compareTo(b.rate));
  return showPickerSheet<TaxRate>(
    context: context,
    title: 'select_gst_rate'.tr(),
    options: rates,
    searchable: false,
    labelOf: taxRateLabel,
    subtitleOf: (rate) => rate.cessRate > 0
        ? 'cess_rate_label'.tr(namedArgs: {'rate': Formatters.formatPercent(rate.cessRate)})
        : null,
    isSelected: (rate) => rate.id == selectedId,
    emptyText: 'no_tax_rates'.tr(),
  );
}

Future<Account?> pickAccount(
  BuildContext context, {
  String? selectedId,
  String? excludeId,
  String? title,
}) async {
  final core = context.read<Core>();
  await core.account.fetchAccounts();
  if (!context.mounted) return null;
  final text = context.text;

  return showPickerSheet<Account>(
    context: context,
    title: title ?? 'select_account'.tr(),
    options: core.account.activeAccounts.where((a) => a.id != excludeId).toList(),
    searchable: false,
    labelOf: (account) => account.name,
    subtitleOf: (account) => account.subtitle,
    trailingOf: (account) => AmountDisplay(
      amount: account.balance,
      showMinus: true,
      style: text.labelLarge,
    ),
    isSelected: (account) => account.id == selectedId,
    emptyText: 'no_accounts_yet'.tr(),
  );
}
