import 'package:easy_localization/easy_localization.dart';

// API enums. `value` is the wire string, `fromString` falls back to a safe
// default for unknown values, `displayName` is the translated label.

enum GstRegistrationType {
  regular('regular'),
  composition('composition'),
  unregistered('unregistered');

  const GstRegistrationType(this.value);
  final String value;

  static GstRegistrationType fromString(String? value) => GstRegistrationType
      .values
      .firstWhere((e) => e.value == value, orElse: () => unregistered);

  String get displayName => 'gst_reg_$value'.tr();
}

enum PartyType {
  customer('customer'),
  supplier('supplier'),
  both('both'),
  transporter('transporter');

  const PartyType(this.value);
  final String value;

  static PartyType fromString(String? value) =>
      PartyType.values.firstWhere((e) => e.value == value, orElse: () => customer);

  String get displayName => 'party_type_$value'.tr();

  bool get canSell => this == customer || this == both;
  bool get canBuy => this == supplier || this == both;
}

enum PartyGstType {
  registered('registered'),
  unregistered('unregistered'),
  composition('composition'),
  consumer('consumer'),
  overseas('overseas');

  const PartyGstType(this.value);
  final String value;

  static PartyGstType fromString(String? value) => PartyGstType.values
      .firstWhere((e) => e.value == value, orElse: () => unregistered);

  String get displayName => 'party_gst_$value'.tr();

  bool get needsGstin => this == registered || this == composition;
}

/// Receivable: the party owes the business. Payable: the business owes them.
enum BalanceType {
  receivable('receivable'),
  payable('payable');

  const BalanceType(this.value);
  final String value;

  static BalanceType fromString(String? value) =>
      BalanceType.values.firstWhere((e) => e.value == value, orElse: () => receivable);

  String get displayName => 'balance_$value'.tr();
}

/// What a saved party address is mainly used for. Either kind can still be
/// picked for either slot on a bill.
enum AddressKind {
  billing('billing'),
  shipping('shipping');

  const AddressKind(this.value);
  final String value;

  static AddressKind fromString(String? value) =>
      AddressKind.values.firstWhere((e) => e.value == value, orElse: () => billing);

  String get displayName => 'address_kind_$value'.tr();
}

enum ItemType {
  goods('goods'),
  service('service');

  const ItemType(this.value);
  final String value;

  static ItemType fromString(String? value) =>
      ItemType.values.firstWhere((e) => e.value == value, orElse: () => goods);

  String get displayName => 'item_type_$value'.tr();
}

enum InvoiceType {
  sale('sale'),
  purchase('purchase'),
  saleReturn('sale_return'),
  purchaseReturn('purchase_return');

  const InvoiceType(this.value);
  final String value;

  static InvoiceType fromString(String? value) =>
      InvoiceType.values.firstWhere((e) => e.value == value, orElse: () => sale);

  String get displayName => 'invoice_type_$value'.tr();

  bool get isSaleSide => this == sale || this == saleReturn;
  bool get isReturn => this == saleReturn || this == purchaseReturn;

  /// The invoice a return is raised against.
  InvoiceType? get returnOf => switch (this) {
    saleReturn => sale,
    purchaseReturn => purchase,
    _ => null,
  };

  /// Money for this invoice flows in (sale, purchase return) or out.
  PaymentDirection get paymentDirection =>
      this == sale || this == purchaseReturn ? PaymentDirection.paymentIn : PaymentDirection.paymentOut;
}

enum TaxMode {
  gst('gst'),
  nonGst('non_gst');

  const TaxMode(this.value);
  final String value;

  static TaxMode fromString(String? value) =>
      TaxMode.values.firstWhere((e) => e.value == value, orElse: () => gst);

  String get displayName => 'tax_mode_$value'.tr();
}

enum InvoiceStatus {
  draft('draft'),
  finalized('final'),
  cancelled('cancelled');

  const InvoiceStatus(this.value);
  final String value;

  static InvoiceStatus fromString(String? value) =>
      InvoiceStatus.values.firstWhere((e) => e.value == value, orElse: () => finalized);

  String get displayName => 'invoice_status_$value'.tr();
}

enum PaymentStatus {
  paid('paid'),
  partiallyPaid('partially_paid'),
  unpaid('unpaid');

  const PaymentStatus(this.value);
  final String value;

  static PaymentStatus fromString(String? value) =>
      PaymentStatus.values.firstWhere((e) => e.value == value, orElse: () => unpaid);

  String get displayName => 'payment_status_$value'.tr();
}

/// Money received (in) or paid (out).
enum PaymentDirection {
  paymentIn('in'),
  paymentOut('out');

  const PaymentDirection(this.value);
  final String value;

  static PaymentDirection fromString(String? value) => PaymentDirection.values
      .firstWhere((e) => e.value == value, orElse: () => paymentIn);

  String get displayName => 'payment_direction_$value'.tr();
}

enum PaymentMode {
  cash('cash'),
  upi('upi'),
  bankTransfer('bank_transfer'),
  cheque('cheque'),
  card('card'),
  other('other');

  const PaymentMode(this.value);
  final String value;

  static PaymentMode fromString(String? value) =>
      PaymentMode.values.firstWhere((e) => e.value == value, orElse: () => cash);

  String get displayName => 'payment_mode_$value'.tr();
}

/// Status of payments, expenses, transfers and stock adjustments.
enum RecordStatus {
  active('active'),
  cancelled('cancelled');

  const RecordStatus(this.value);
  final String value;

  static RecordStatus fromString(String? value) =>
      RecordStatus.values.firstWhere((e) => e.value == value, orElse: () => active);

  String get displayName => 'record_status_$value'.tr();
}

enum AccountType {
  cash('cash'),
  bank('bank');

  const AccountType(this.value);
  final String value;

  static AccountType fromString(String? value) =>
      AccountType.values.firstWhere((e) => e.value == value, orElse: () => cash);

  String get displayName => 'account_type_$value'.tr();
}

enum ChargeType {
  transport('transport'),
  loading('loading'),
  unloading('unloading'),
  packing('packing'),
  other('other');

  const ChargeType(this.value);
  final String value;

  static ChargeType fromString(String? value) =>
      ChargeType.values.firstWhere((e) => e.value == value, orElse: () => other);

  String get displayName => 'charge_type_$value'.tr();
}

/// Who a charge is owed by: added to the invoice party's bill, or owed only
/// to a payee such as a transporter.
enum ChargeBillTo {
  invoiceParty('invoice_party'),
  payeeOnly('payee_only');

  const ChargeBillTo(this.value);
  final String value;

  static ChargeBillTo fromString(String? value) => ChargeBillTo.values
      .firstWhere((e) => e.value == value, orElse: () => invoiceParty);

  String get displayName => 'charge_bill_to_$value'.tr();
}

enum TransportMode {
  road('road'),
  rail('rail'),
  air('air'),
  ship('ship'),
  self('self');

  const TransportMode(this.value);
  final String value;

  static TransportMode? fromString(String? value) =>
      TransportMode.values.where((e) => e.value == value).firstOrNull;

  String get displayName => 'transport_mode_$value'.tr();
}

/// owner > admin > accountant > staff
enum MemberRole {
  staff('staff', 1),
  accountant('accountant', 2),
  admin('admin', 3),
  owner('owner', 4);

  const MemberRole(this.value, this.rank);
  final String value;
  final int rank;

  static MemberRole fromString(String? value) =>
      MemberRole.values.firstWhere((e) => e.value == value, orElse: () => staff);

  String get displayName => 'role_$value'.tr();
  String get description => 'role_${value}_description'.tr();

  bool atLeast(MemberRole other) => rank >= other.rank;
}

enum AdjustmentReason {
  damage('damage'),
  count('count'),
  opening('opening'),
  other('other');

  const AdjustmentReason(this.value);
  final String value;

  static AdjustmentReason fromString(String? value) => AdjustmentReason.values
      .firstWhere((e) => e.value == value, orElse: () => other);

  String get displayName => 'adjustment_reason_$value'.tr();
}

/// What produced a ledger or account-book entry.
enum LedgerSource {
  opening('opening'),
  invoice('invoice'),
  invoiceCharge('invoice_charge'),
  payment('payment'),
  expense('expense'),
  transfer('transfer'),
  adjustment('adjustment');

  const LedgerSource(this.value);
  final String value;

  static LedgerSource fromString(String? value) =>
      LedgerSource.values.firstWhere((e) => e.value == value, orElse: () => adjustment);

  String get displayName => 'ledger_source_$value'.tr();
}

enum CategoryKind {
  item('item-categories'),
  expense('expense-categories');

  const CategoryKind(this.path);
  final String path;
}

enum OutstandingType {
  receivable('receivable'),
  payable('payable');

  const OutstandingType(this.value);
  final String value;
}

/// Invoice PDF layouts: one for tax invoices, one for bills of supply.
enum BillDesign {
  gstClassic,
  nonGstSimple;

  static BillDesign forTaxMode(TaxMode taxMode) =>
      taxMode == TaxMode.gst ? gstClassic : nonGstSimple;
}

class AppConstants {
  static const String appName = 'Vyapar Setu';

  static const String apiBaseUrl = 'https://vyaparsetubackend.onrender.com/v1/';

  /// Page size for lists that load more as you scroll.
  static const int pageSize = 50;
}
