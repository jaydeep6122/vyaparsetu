import 'package:flutter_test/flutter_test.dart';
import 'package:vyaparsetu/services/invoicePdfService.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/types/invoice.dart';

Business _business() => Business.fromJson({
  'id': 'b1',
  'name': 'Shree Traders',
  'gst_registration_type': 'regular',
  'gstin': '24AAACC1206D1ZM',
  'state_code': '24',
  'address': {'line1': 'Shop 4, Market Road', 'city': 'Rajkot', 'state': 'Gujarat', 'pincode': '360001'},
  'phone': '9876543210',
  'fy_start_month': 4,
  'settings': {'round_off_invoices': true, 'invoice_terms': 'Goods once sold are not returnable.'},
  'role': 'owner',
});

Invoice _invoice({required String taxMode, required String supplyType}) {
  final interState = supplyType == 'inter';
  return Invoice.fromJson({
    'id': 'i1',
    'invoice_type': 'sale',
    'tax_mode': taxMode,
    'status': 'final',
    'invoice_number': 'INV/26-27/1',
    'invoice_date': '2026-09-10',
    'due_date': '2026-09-25',
    'party_id': 'p1',
    'party_name': 'Krishna Hardware',
    'party_gstin': interState ? '27AAPFU0939F1ZV' : '24AAACC1206D1ZM',
    'party_state_code': interState ? '27' : '24',
    'billing_address': {'line1': 'Plot 7', 'city': 'Mumbai', 'state': 'Maharashtra'},
    'place_of_supply': interState ? '27' : '24',
    'supply_type': taxMode == 'gst' ? supplyType : null,
    'taxable_total': '1000.00',
    'cgst_total': taxMode == 'gst' && !interState ? '90.00' : '0',
    'sgst_total': taxMode == 'gst' && !interState ? '90.00' : '0',
    'igst_total': taxMode == 'gst' && interState ? '180.00' : '0',
    'charges_total': '200.00',
    'round_off': '0',
    'total_amount': taxMode == 'gst' ? '1380.00' : '1200.00',
    'amount_settled': '500.00',
    'payment_status': 'partially_paid',
    'vehicle_no': 'GJ03AB1234',
    'lr_no': 'LR-99',
    'eway_bill_no': '123456789012',
    'lines': [
      {
        'line_no': 1,
        'description': 'Cement bag',
        'hsn_sac': '2523',
        'quantity': '10',
        'unit_code': 'BAG',
        'unit_price': '100.00',
        'taxable_value': '1000.00',
        'tax_rate': taxMode == 'gst' ? '18' : '0',
        'cgst_amount': taxMode == 'gst' && !interState ? '90.00' : '0',
        'sgst_amount': taxMode == 'gst' && !interState ? '90.00' : '0',
        'igst_amount': taxMode == 'gst' && interState ? '180.00' : '0',
        'line_total': taxMode == 'gst' ? '1180.00' : '1000.00',
      },
    ],
    'charges': [
      {
        'charge_type': 'transport',
        'description': 'Freight',
        'bill_to': 'invoice_party',
        'vehicle_no': 'GJ03AB1234',
        'amount': '200.00',
        'tax_rate': '0',
        'tax_amount': '0',
      },
    ],
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> expectPdf(Invoice invoice) async {
    final bytes = await InvoicePdfService.generate(
      invoice: invoice,
      business: _business(),
    );
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  }

  test('builds a GST bill with CGST and SGST', () async {
    await expectPdf(_invoice(taxMode: 'gst', supplyType: 'intra'));
  });

  test('builds a GST bill with IGST', () async {
    await expectPdf(_invoice(taxMode: 'gst', supplyType: 'inter'));
  });

  test('builds a non-GST bill', () async {
    await expectPdf(_invoice(taxMode: 'non_gst', supplyType: 'intra'));
  });
}
