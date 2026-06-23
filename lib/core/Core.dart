import 'package:flutter/material.dart';
import 'package:vyaparsetu/core/modules/authModule.dart';
import 'package:vyaparsetu/core/modules/businessModule.dart';
import 'package:vyaparsetu/core/modules/partyModule.dart';
import 'package:vyaparsetu/core/modules/itemModule.dart';
import 'package:vyaparsetu/core/modules/invoiceModule.dart';
import 'package:vyaparsetu/core/modules/paymentModule.dart';
import 'package:vyaparsetu/core/modules/expenseModule.dart';
import 'package:vyaparsetu/core/modules/dashboardModule.dart';
import 'package:vyaparsetu/core/modules/settingsModule.dart';
import 'package:vyaparsetu/core/modules/factoryModule.dart';

class Core extends ChangeNotifier {
  late final AuthModule auth;
  late final BusinessModule business;
  late final PartyModule party;
  late final ItemModule item;
  late final InvoiceModule invoice;
  late final PaymentModule payment;
  late final ExpenseModule expense;
  late final DashboardModule dashboard;
  late final SettingsModule settings;
  late final FactoryModule factory;

  static Core? _instance;
  static Core get() => _instance!;

  Core._() {
    _instance = this;
    auth = AuthModule(this);
    business = BusinessModule(this);
    party = PartyModule(this);
    item = ItemModule(this);
    invoice = InvoiceModule(this);
    payment = PaymentModule(this);
    expense = ExpenseModule(this);
    dashboard = DashboardModule(this);
    settings = SettingsModule(this);
    factory = FactoryModule(this);
  }

  factory Core() => _instance ?? Core._();

  void notify() => notifyListeners();
}
