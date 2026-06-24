import 'package:easy_localization/easy_localization.dart';

String userFriendlyError(String message) {
  if (message.contains(': ')) {
    final parts = message.split(': ');
    if (parts.length >= 2) {
      final field = _friendlyFieldName(parts[0]);
      final msg = parts.sublist(1).join(': ');
      if (msg.endsWith('is required') || msg.endsWith('are required')) {
        return '$field ${'required_field'.tr().toLowerCase()}';
      }
      if (msg.contains('Invalid email')) return 'invalid_email_msg'.tr();
      if (msg.contains('Invalid phone')) return 'invalid_phone_msg'.tr();
      if (msg.contains('Invalid GSTIN')) return 'invalid_gstin_msg'.tr();
      if (msg.contains('Invalid PAN')) return 'invalid_pan_msg'.tr();
      if (msg.contains('at least 6')) return 'password_min_length'.tr();
      if (msg.contains('enum') || msg.contains('business_type')) return 'select_valid_business_type'.tr();
      return msg;
    }
  }

  if (message == 'Invalid email or password') return 'invalid_credentials'.tr();
  if (message == 'Email and password are required') return 'enter_email_password'.tr();
  if (message == 'Name, email, and password are required') return 'fill_name_email_password'.tr();
  if (message == 'Password and confirm password do not match') return 'passwords_no_match'.tr();
  if (message.contains('users_email_key') || message == 'Email already exists') return 'email_already_exists'.tr();

  if (message == 'Authorization token is required') return 'session_expired'.tr();
  if (message == 'Access token expired') return 'session_expired'.tr();
  if (message == 'Invalid access token') return 'session_expired'.tr();
  if (message == 'User not found') return 'account_not_found'.tr();
  if (message == 'User account is suspended') return 'account_suspended'.tr();
  if (message.contains('do not have permission')) return 'no_access_to_business'.tr();

  if (message.contains('GSTIN already exists')) return 'gstin_already_exists'.tr();
  if (message == 'Required fields cannot be empty') return 'fill_required_fields'.tr();
  if (message == 'Business ID is required') return 'business_id_required_error'.tr();
  if (message == 'Business not found') return 'business_not_found_error'.tr();
  if (message == 'Internal server error') return 'server_error'.tr();

  // ── Party Errors ──
  if (message == 'Name and party_type are required') return 'name_party_type_required'.tr();
  if (message == 'Invalid party_type. Must be one of: customer, supplier, both' || message == 'Invalid party_type') return 'select_valid_party_type'.tr();
  if (message == 'Invalid opening_balance_type. Must be one of: receive, pay' || message == 'Invalid opening_balance_type') return 'select_valid_balance_type'.tr();
  if (message == 'A party with this name already exists in this business') return 'party_name_exists'.tr();
  if (message == 'Party not found') return 'party_not_found_error'.tr();
  if (message == 'Name cannot be empty') return 'name_cannot_be_empty'.tr();

  // ── Invoice Errors ──
  if (message == 'invoice_number is required') return 'invoice_number_required'.tr();
  if (message == 'invoice_type and payment_mode are required') return 'invoice_type_payment_required'.tr();
  if (message.contains('Invalid invoice_type')) return 'select_valid_invoice_type'.tr();
  if (message == 'Invoice must contain at least one item') return 'invoice_min_one_item'.tr();
  if (message.contains('already exists') && message.contains('Invoice number')) return 'invoice_number_in_use'.tr();
  if (message == 'Selected party not found for this business') return 'party_not_found_business'.tr();
  if (message == 'Each item must have a name, quantity, and unit_price') return 'line_item_required_fields'.tr();
  if (message.contains('Item with ID') && message.contains('not found')) return 'item_not_found_error'.tr();
  if (message.contains('Paid amount') && message.contains('cannot be greater than')) return 'paid_exceeds_invoice_total'.tr();
  if (message == 'Invoice not found') return 'invoice_not_found_error'.tr();

  return message;
}

String _friendlyFieldName(String field) {
  switch (field) {
    case 'name': return 'name'.tr();
    case 'email': return 'email'.tr();
    case 'password': return 'password'.tr();
    case 'phone': return 'phone'.tr();
    case 'address': return 'address'.tr();
    case 'city': return 'city'.tr();
    case 'state': return 'state'.tr();
    case 'pincode': return 'pincode'.tr();
    case 'gstin': return 'gstin'.tr();
    case 'pan_number': return 'pan'.tr();
    case 'business_type': return 'business_type'.tr();
    case 'invoice_prefix': return 'invoice_prefix'.tr();
    default: return field[0].toUpperCase() + field.substring(1);
  }
}
