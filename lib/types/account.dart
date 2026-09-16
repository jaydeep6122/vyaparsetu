import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';

class Account {
  final String id;
  final String name;
  final AccountType accountType;
  final String? bankName;
  final String? accountNumber;
  final String? ifsc;
  final String? upiId;
  final bool isDefault;
  final DateTime? archivedAt;
  final double balance;

  /// Negative for an overdraft.
  final double openingBalance;
  final DateTime? openingBalanceDate;

  const Account({
    required this.id,
    required this.name,
    required this.accountType,
    this.bankName,
    this.accountNumber,
    this.ifsc,
    this.upiId,
    required this.isDefault,
    this.archivedAt,
    required this.balance,
    required this.openingBalance,
    this.openingBalanceDate,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: asString(json['name']),
      accountType: AccountType.fromString(json['account_type'] as String?),
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      ifsc: json['ifsc'] as String?,
      upiId: json['upi_id'] as String?,
      isDefault: asBool(json['is_default']),
      archivedAt: asDate(json['archived_at']),
      balance: asDouble(json['balance']),
      openingBalance: asDouble(json['opening_balance']),
      openingBalanceDate: asDate(json['opening_balance_date']),
    );
  }

  bool get isArchived => archivedAt != null;

  /// "HDFC ••5678" style label for bank accounts.
  String get subtitle {
    if (accountType == AccountType.cash) return accountType.displayName;
    final last4 = (accountNumber?.length ?? 0) >= 4
        ? ' ••${accountNumber!.substring(accountNumber!.length - 4)}'
        : '';
    return '${bankName ?? accountType.displayName}$last4';
  }
}

class Transfer {
  final String id;
  final DateTime transferDate;
  final String fromAccountId;
  final String fromAccountName;
  final String toAccountId;
  final String toAccountName;
  final double amount;
  final String? notes;
  final RecordStatus status;
  final DateTime? createdAt;

  const Transfer({
    required this.id,
    required this.transferDate,
    required this.fromAccountId,
    required this.fromAccountName,
    required this.toAccountId,
    required this.toAccountName,
    required this.amount,
    this.notes,
    required this.status,
    this.createdAt,
  });

  factory Transfer.fromJson(Map<String, dynamic> json) {
    return Transfer(
      id: json['id'] as String,
      transferDate: asDate(json['transfer_date']) ?? DateTime.now(),
      fromAccountId: asString(json['from_account_id']),
      fromAccountName: asString(json['from_account_name']),
      toAccountId: asString(json['to_account_id']),
      toAccountName: asString(json['to_account_name']),
      amount: asDouble(json['amount']),
      notes: json['notes'] as String?,
      status: RecordStatus.fromString(json['status'] as String?),
      createdAt: asDate(json['created_at']),
    );
  }
}
