import 'package:flutter/material.dart';
import 'package:vyaparsetu/core/modules/accountModule.dart';
import 'package:vyaparsetu/core/modules/authModule.dart';
import 'package:vyaparsetu/core/modules/businessModule.dart';
import 'package:vyaparsetu/core/modules/expenseModule.dart';
import 'package:vyaparsetu/core/modules/invoiceModule.dart';
import 'package:vyaparsetu/core/modules/itemModule.dart';
import 'package:vyaparsetu/core/modules/masterModule.dart';
import 'package:vyaparsetu/core/modules/memberModule.dart';
import 'package:vyaparsetu/core/modules/partyModule.dart';
import 'package:vyaparsetu/core/modules/paymentModule.dart';
import 'package:vyaparsetu/core/modules/reportModule.dart';
import 'package:vyaparsetu/core/modules/settingsModule.dart';
import 'package:vyaparsetu/core/modules/stockModule.dart';

class Core extends ChangeNotifier {
  late final AuthModule auth;
  late final BusinessModule business;
  late final MemberModule member;
  late final PartyModule party;
  late final ItemModule item;
  late final MasterModule master;
  late final AccountModule account;
  late final InvoiceModule invoice;
  late final PaymentModule payment;
  late final ExpenseModule expense;
  late final StockModule stock;
  late final ReportModule report;
  late final SettingsModule settings;

  static Core? _instance;
  static Core get() => _instance!;

  Core._() {
    _instance = this;
    auth = AuthModule(this);
    business = BusinessModule(this);
    member = MemberModule(this);
    party = PartyModule(this);
    item = ItemModule(this);
    master = MasterModule(this);
    account = AccountModule(this);
    invoice = InvoiceModule(this);
    payment = PaymentModule(this);
    expense = ExpenseModule(this);
    stock = StockModule(this);
    report = ReportModule(this);
    settings = SettingsModule(this);
  }

  factory Core() => _instance ?? Core._();

  void notify() => notifyListeners();

  /// Drops everything loaded for the current business (on switching business
  /// or signing out).
  void resetBusinessData() {
    member.clear();
    party.clear();
    item.clear();
    master.clear();
    account.clear();
    invoice.clear();
    payment.clear();
    expense.clear();
    stock.clear();
    report.clear();
    notify();
  }

  /// Money or stock moved on the server: balances, stock, documents and
  /// reports reload the next time they are shown.
  void markBooksChanged() {
    party.markStale();
    item.markStale();
    account.markStale();
    invoice.markStale();
    payment.markStale();
    expense.markStale();
    stock.markStale();
    report.markStale();
  }
}
