import 'package:easy_localization/easy_localization.dart';

/// Unique constraints the server reports on a 409, mapped to what went wrong.
const Map<String, String> _constraintMessages = {
  'parties_name_unique': 'error_party_name_exists',
  'items_name_unique': 'error_item_name_exists',
  'items_sku_unique': 'error_item_sku_exists',
  'items_barcode_unique': 'error_item_barcode_exists',
  'item_categories_name_unique': 'error_category_name_exists',
  'expense_categories_name_unique': 'error_category_name_exists',
  'accounts_name_unique': 'error_account_name_exists',
  'invoices_number_unique': 'error_invoice_number_exists',
  'invoices_supplier_number_unique': 'error_supplier_bill_exists',
  'payments_number_unique': 'error_payment_number_exists',
  'expenses_number_unique': 'error_expense_number_exists',
  'tax_rates_business_id_rate_cess_rate_key': 'error_tax_rate_exists',
};

/// Turns a server message into text for the user.
///
/// The server already writes most messages for people ("A sale without a
/// party must be paid in full ..."), so those pass through. Validation errors
/// arrive as "lines.0.quantity: Must be greater than 0"; the field path is
/// rewritten to "Line 1 · Quantity: ...".
String userFriendlyError(String message, {String? constraint}) {
  final known = constraint == null ? null : _constraintMessages[constraint];
  if (known != null) return known.tr();

  // Several validation issues are joined with ", "; split only where a new
  // "field.path: " starts, since messages themselves may contain commas.
  final issues = message.split(RegExp(r', (?=[a-z_][a-z0-9_.]*: )'));
  final described = issues.map(_describeIssue).toList();
  return described.join('\n');
}

String _describeIssue(String issue) {
  final match = RegExp(r'^([a-z_][a-z0-9_.]*): (.+)$').firstMatch(issue);
  if (match == null) return issue;

  final path = match.group(1)!.split('.');
  final text = match.group(2)!;
  final field = path.lastWhere((part) => int.tryParse(part) == null);

  // A list index names which row is wrong ("lines.2.quantity").
  final indexPart = path.lastWhere(
    (part) => int.tryParse(part) != null,
    orElse: () => '',
  );
  final row = indexPart.isEmpty
      ? ''
      : '${'error_row_prefix'.tr(namedArgs: {'number': '${int.parse(indexPart) + 1}'})} · ';

  return '$row${_fieldLabel(field)}: ${_lowerFirst(text)}';
}

String _fieldLabel(String field) {
  final key = 'field_$field';
  final translated = key.tr();
  if (translated != key) return translated;
  final words = field.replaceAll('_', ' ');
  return words[0].toUpperCase() + words.substring(1);
}

String _lowerFirst(String text) =>
    text.isEmpty ? text : text[0].toLowerCase() + text.substring(1);
