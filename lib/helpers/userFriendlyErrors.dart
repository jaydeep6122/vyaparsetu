String userFriendlyError(String message) {
  if (message.contains(': ')) {
    final parts = message.split(': ');
    if (parts.length >= 2) {
      final field = _friendlyFieldName(parts[0]);
      final msg = parts.sublist(1).join(': ');
      if (msg.endsWith('is required') || msg.endsWith('are required')) {
        return '$field is required';
      }
      if (msg.contains('Invalid email')) return 'Please enter a valid email address';
      if (msg.contains('Invalid phone')) return 'Please enter a valid 10-digit phone number';
      if (msg.contains('Invalid GSTIN')) return 'Please enter a valid GSTIN (e.g. 22AAAAA1111A1Z1)';
      if (msg.contains('Invalid PAN')) return 'Please enter a valid PAN (e.g. ABCDE1234F)';
      if (msg.contains('at least 6')) return 'Password must be at least 6 characters';
      if (msg.contains('enum') || msg.contains('business_type')) return 'Please select a valid business type';
      return msg;
    }
  }

  if (message == 'Invalid email or password') return 'Incorrect email or password. Please try again.';
  if (message == 'Email and password are required') return 'Please enter your email and password';
  if (message == 'Name, email, and password are required') return 'Please fill in name, email, and password';
  if (message == 'Password and confirm password do not match') return 'Passwords do not match';
  if (message.contains('users_email_key') || message == 'Email already exists') return 'An account with this email already exists';

  if (message == 'Authorization token is required') return 'Session expired. Please log in again.';
  if (message == 'Access token expired') return 'Session expired. Please log in again.';
  if (message == 'Invalid access token') return 'Session expired. Please log in again.';
  if (message == 'User not found') return 'Account not found. Please log in again.';
  if (message == 'User account is suspended') return 'Your account has been suspended. Please contact support.';
  if (message.contains('do not have permission')) return 'You don\'t have access to this business.';

  if (message.contains('GSTIN already exists')) return 'This GSTIN is already registered to another business';
  if (message == 'Required fields cannot be empty') return 'Please fill in all required fields';
  if (message == 'Business ID is required') return 'Something went wrong. Please try again.';
  if (message == 'Business not found') return 'Business not found. It may have been deleted.';
  if (message == 'Internal server error') return 'Something went wrong. Please try again later.';

  // ── Party Errors ──
  if (message == 'Name and party_type are required') return 'Name and party type are required';
  if (message == 'Invalid party_type. Must be one of: customer, supplier, both' || message == 'Invalid party_type') return 'Please select a valid party type';
  if (message == 'Invalid opening_balance_type. Must be one of: receive, pay' || message == 'Invalid opening_balance_type') return 'Please select a valid balance type';
  if (message == 'A party with this name already exists in this business') return 'A party with this name already exists';
  if (message == 'Party not found') return 'Party not found. It may have been deleted.';
  if (message == 'Name cannot be empty') return 'Name cannot be empty';

  // ── Invoice Errors ──
  if (message == 'invoice_number is required') return 'Invoice number is required';
  if (message == 'invoice_type and payment_mode are required') return 'Invoice type and payment mode are required';
  if (message.contains('Invalid invoice_type')) return 'Please select a valid invoice type';
  if (message == 'Invoice must contain at least one item') return 'Invoice must contain at least one item';
  if (message.contains('already exists') && message.contains('Invoice number')) return 'This invoice number is already in use';
  if (message == 'Selected party not found for this business') return 'Selected party not found for this business';
  if (message == 'Each item must have a name, quantity, and unit_price') return 'Each line item must have a name, quantity, and price';
  if (message.contains('Item with ID') && message.contains('not found')) return 'Selected item not found. It may have been deleted.';
  if (message.contains('Paid amount') && message.contains('cannot be greater than')) return 'Paid amount cannot be greater than the invoice total';
  if (message == 'Invoice not found') return 'Invoice not found. It may have been deleted.';

  return message;
}

String _friendlyFieldName(String field) {
  switch (field) {
    case 'name': return 'Name';
    case 'email': return 'Email';
    case 'password': return 'Password';
    case 'phone': return 'Phone number';
    case 'address': return 'Address';
    case 'city': return 'City';
    case 'state': return 'State';
    case 'pincode': return 'Pincode';
    case 'gstin': return 'GSTIN';
    case 'pan_number': return 'PAN number';
    case 'business_type': return 'Business type';
    case 'invoice_prefix': return 'Invoice prefix';
    default: return field[0].toUpperCase() + field.substring(1);
  }
}
