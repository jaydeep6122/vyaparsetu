import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/modules/auth.dart';
import 'package:vyaparsetu/api/modules/business.dart';
import 'package:vyaparsetu/api/modules/party.dart';
import 'package:vyaparsetu/api/modules/item.dart';
import 'package:vyaparsetu/api/modules/invoice.dart';
import 'package:vyaparsetu/api/modules/payment.dart';
import 'package:vyaparsetu/api/modules/expense.dart';
import 'package:vyaparsetu/api/modules/dashboard.dart';
import 'package:vyaparsetu/api/modules/appConfig.dart';

class Api {
  static late final Api _instance;
  static Api get instance => _instance;

  late final AuthApi auth;
  late final BusinessApi business;
  late final PartyApi party;
  late final ItemApi item;
  late final InvoiceApi invoice;
  late final PaymentApi payment;
  late final ExpenseApi expense;
  late final DashboardApi dashboard;
  late final AppConfigApi appConfig;

  Api._internal(Dio dio) {
    auth = AuthApi(dio);
    business = BusinessApi(dio);
    party = PartyApi(dio);
    item = ItemApi(dio);
    invoice = InvoiceApi(dio);
    payment = PaymentApi(dio);
    expense = ExpenseApi(dio);
    dashboard = DashboardApi(dio);
    appConfig = AppConfigApi(dio);
  }

  static void initialize(Dio dio) {
    _instance = Api._internal(dio);
  }
}
