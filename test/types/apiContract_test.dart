import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/types/account.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/types/expense.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/types/item.dart';
import 'package:vyaparsetu/types/member.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/types/payment.dart';
import 'package:vyaparsetu/types/reports.dart';
import 'package:vyaparsetu/types/stockAdjustment.dart';

/// Parses real server responses captured by `tests/fixtures.test.js` in the
/// backend repo, so a field the API renames or drops fails here instead of
/// crashing a screen.
///
/// Regenerate with:
///   DATABASE_URL_TEST=... npx jest tests/fixtures.test.js
const fixtureDir = String.fromEnvironment('FIXTURES', defaultValue: '/tmp/api-fixtures');

Map<String, dynamic>? _map(String name) {
  final file = File('$fixtureDir/$name.json');
  if (!file.existsSync()) return null;
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

List<Map<String, dynamic>>? _list(String name) {
  final file = File('$fixtureDir/$name.json');
  if (!file.existsSync()) return null;
  final decoded = jsonDecode(file.readAsStringSync());
  final items = decoded is Map ? decoded['data'] : decoded;
  return (items as List).cast<Map<String, dynamic>>();
}

void main() {
  final hasFixtures = Directory(fixtureDir).existsSync();

  group('API contract', skip: hasFixtures ? null : 'No fixtures in $fixtureDir', () {
    test('business, accounts and masters', () {
      final business = Business.fromJson(_map('business')!);
      expect(business.name, isNotEmpty);
      expect(business.stateCode, isNotEmpty);
      expect(business.canIssueGstInvoices, isTrue);

      final accounts = _list('accounts')!.map(Account.fromJson).toList();
      expect(accounts, isNotEmpty);
      expect(accounts.any((a) => a.accountType == AccountType.cash), isTrue);
      expect(accounts.first.balance, isNot(0));

      final rates = _list('tax_rates')!.map(TaxRate.fromJson).toList();
      expect(rates.any((rate) => rate.rate == 18), isTrue);

      _list('members')!.map(Member.fromJson).toList();
      final invite = Invite.fromJson(_map('invite')!);
      expect(invite.inviteToken, isNotNull);
      _list('invites')!.map(Invite.fromJson).toList();

      final series = _list('document_series')!.map(DocumentSeries.fromJson).toList();
      expect(series, isNotEmpty);
      expect(series.first.preview, isNotEmpty);
    });

    test('parties', () {
      final created = Party.fromJson(_map('party_create')!);
      final fetched = Party.fromJson(_map('party_get')!);
      expect(created.name, fetched.name);
      expect(fetched.balance, greaterThan(0));
      expect(fetched.openingBalance, 2500);

      // Two billing addresses and one shipping address; with none marked, the
      // first of each kind is the default.
      expect(fetched.addresses, hasLength(3));
      expect(fetched.addressesOf(AddressKind.billing), hasLength(2));
      expect(fetched.defaultAddress(AddressKind.billing)?.label, 'Head office');
      expect(fetched.defaultAddress(AddressKind.shipping)?.address.city, 'Morbi');
      expect(fetched.billingAddress?.line1, '1 Main Road');
      expect(fetched.addresses.every((address) => address.id != null), isTrue);
      expect(_list('party_list')!.map(Party.fromJson).length, greaterThan(1));
    });

    test('items and categories', () {
      Category.fromJson(_map('category')!);
      final item = Item.fromJson(_map('item_get')!);
      expect(item.unitCode, 'BAG');
      expect(item.taxRate, 18);
      expect(item.quantityOnHand, isNotNull);
      expect(_list('item_list')!.map(Item.fromJson), isNotEmpty);
    });

    test('invoice with lines, charges and payments', () {
      final invoice = Invoice.fromJson(_map('invoice_get')!);
      expect(invoice.lines, isNotEmpty);
      expect(invoice.charges, isNotEmpty);
      expect(invoice.payments, isNotEmpty);
      expect(invoice.totalAmount, greaterThan(0));
      expect(invoice.outstanding, invoice.totalAmount - invoice.amountSettled);
      expect(invoice.isGst, isTrue);
      expect(invoice.hasTransportDetails, isTrue);
      expect(invoice.charges.first.payeeName, isNotNull);

      // The bill printed the Branch billing address and the warehouse.
      expect(invoice.billingAddressId, isNotNull);
      expect(invoice.billingAddress?.line1, '9 Ring Road');
      expect(invoice.shippingAddressId, isNotNull);
      expect(invoice.shippingAddress?.city, 'Morbi');
      expect(_list('invoice_list')!.map(Invoice.fromJson), isNotEmpty);
    });

    test('payments', () {
      final payment = Payment.fromJson(_map('payment_get')!);
      expect(payment.allocations, isNotEmpty);
      expect(payment.allocations.first.documentNumber, isNotNull);
      expect(payment.amount, 5000);
      expect(_list('payment_list')!.map(Payment.fromJson), isNotEmpty);
    });

    test('expenses, transfers and stock adjustments', () {
      final expense = Expense.fromJson(_map('expense_get')!);
      expect(expense.totalAmount, 2360);
      expect(expense.payments, isNotEmpty);
      expect(_list('expense_list')!.map(Expense.fromJson), isNotEmpty);

      Transfer.fromJson(_map('transfer_create')!);
      expect(_list('transfer_list')!.map(Transfer.fromJson), isNotEmpty);

      final adjustment = StockAdjustment.fromJson(_map('adjustment_create')!);
      expect(adjustment.lines, isNotEmpty);
      expect(adjustment.lines.first.quantity, -3);
      expect(_list('adjustment_list')!.map(StockAdjustment.fromJson), isNotEmpty);
    });

    test('reports', () {
      final dashboard = DashboardData.fromJson(_map('dashboard')!);
      expect(dashboard.accounts, isNotEmpty);
      expect(dashboard.cashBalance, isNot(0));
      expect(dashboard.receivable, greaterThan(0));
      expect(dashboard.sales.net, greaterThan(0));

      ProfitLoss.fromJson(_map('profit_loss')!);
      final gst = GstSummary.fromJson(_map('gst_summary')!);
      expect(gst.output.taxable, greaterThan(0));

      final receivable = OutstandingReport.fromJson(_map('outstanding_receivable')!);
      expect(receivable.documents, isNotEmpty);
      expect(receivable.total, greaterThan(0));
      final payable = OutstandingReport.fromJson(_map('outstanding_payable')!);
      expect(payable.documents.any((doc) => doc.kind == 'charge'), isTrue);

      final dayBook = DayBook.fromJson(_map('day_book')!);
      expect(dayBook.entries, isNotEmpty);

      final stock = StockSummary.fromJson(_map('stock_summary')!);
      expect(stock.items, isNotEmpty);
      expect(stock.totalValue, greaterThan(0));
    });

    test('ledgers', () {
      final party = Ledger.partyFromJson(_map('party_ledger')!);
      expect(party.ownerName, isNotEmpty);
      expect(party.entries, isNotEmpty);
      expect(party.totalDebitOrIn, greaterThan(0));
      expect(party.closingBalance, isNot(0));

      final book = Ledger.accountFromJson(_map('account_book')!);
      expect(book.ownerName, isNotEmpty);
      expect(book.entries, isNotEmpty);
      expect(book.totalDebitOrIn, greaterThan(0));
      expect(book.totalCreditOrOut, greaterThan(0));
      expect(book.closingBalance, isNot(0));
      expect(book.entries.first.amount, isNot(0));
    });
  });
}
