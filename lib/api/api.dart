import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/modules/account.dart';
import 'package:vyaparsetu/api/modules/auth.dart';
import 'package:vyaparsetu/api/modules/business.dart';
import 'package:vyaparsetu/api/modules/expense.dart';
import 'package:vyaparsetu/api/modules/invoice.dart';
import 'package:vyaparsetu/api/modules/item.dart';
import 'package:vyaparsetu/api/modules/master.dart';
import 'package:vyaparsetu/api/modules/member.dart';
import 'package:vyaparsetu/api/modules/party.dart';
import 'package:vyaparsetu/api/modules/payment.dart';
import 'package:vyaparsetu/api/modules/report.dart';
import 'package:vyaparsetu/api/modules/stock.dart';
import 'package:vyaparsetu/api/modules/transfer.dart';

class Api {
  static late final Api _instance;
  static Api get instance => _instance;

  late final AuthApi auth;
  late final BusinessApi business;
  late final MemberApi member;
  late final PartyApi party;
  late final ItemApi item;
  late final MasterApi master;
  late final AccountApi account;
  late final InvoiceApi invoice;
  late final PaymentApi payment;
  late final ExpenseApi expense;
  late final TransferApi transfer;
  late final StockApi stock;
  late final ReportApi report;

  Api._internal(Dio dio) {
    auth = AuthApi(dio);
    business = BusinessApi(dio);
    member = MemberApi(dio);
    party = PartyApi(dio);
    item = ItemApi(dio);
    master = MasterApi(dio);
    account = AccountApi(dio);
    invoice = InvoiceApi(dio);
    payment = PaymentApi(dio);
    expense = ExpenseApi(dio);
    transfer = TransferApi(dio);
    stock = StockApi(dio);
    report = ReportApi(dio);
  }

  static void initialize(Dio dio) {
    _instance = Api._internal(dio);
  }
}
