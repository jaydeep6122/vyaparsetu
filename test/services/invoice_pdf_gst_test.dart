import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/services/invoicePdfService.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/types/invoiceItem.dart';
import 'package:vyaparsetu/types/party.dart';

/// Characterisation tests for GST invoice rendering.
///
/// Scope: these render each of the three GST designs for an intra-state, an
/// inter-state and a legacy (no state recorded) buyer, and assert the document
/// builds. Because inter-state collapses two tax columns into one IGST column,
/// a row/column count mismatch is the most likely way that change breaks, and
/// it throws during layout - which is exactly what this catches.
///
/// These do NOT assert the printed text: the pdf package compresses content
/// streams, so "IGST" is not greppable in the output bytes. The tax decision
/// and the split arithmetic are covered directly in test/helpers/gst_test.dart;
/// verifying what a human sees on the page still needs a visual check.
void main() {
  setUpAll(() async {
    // The PDF layout formats dates with an explicit 'en' locale, which needs
    // locale data loaded. The app gets this via EasyLocalization at startup.
    await initializeDateFormatting('en');
  });

  final now = DateTime(2026, 4, 1);

  Business businessIn(String state, String gstin) => Business(
    id: 'b1',
    userId: 'u1',
    name: 'Test Traders',
    address: '1 Test Road',
    city: 'Testville',
    state: state,
    pincode: '380001',
    gstin: gstin,
    businessType: BusinessType.retailer,
    invoicePrefix: 'INV',
    invoiceCounter: 1,
    financialYear: '2026-2027',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );

  Party partyIn(String? state, String? gstin) => Party(
    id: 'p1',
    businessId: 'b1',
    name: 'Buyer Co',
    gstin: gstin,
    state: state,
    partyType: PartyType.customer,
    openingBalance: 0,
    openingBalanceType: OpeningBalanceType.receive,
    currentBalance: 0,
    createdAt: now,
    updatedAt: now,
  );

  Invoice invoice() => Invoice(
    id: 'i1',
    businessId: 'b1',
    partyId: 'p1',
    invoiceNumber: 'INV-1',
    invoiceType: InvoiceType.sale,
    billType: BillType.gst,
    transportCost: 0,
    invoiceDate: now,
    subTotal: 1000,
    taxAmount: 180,
    discountAmount: 0,
    totalAmount: 1180,
    paidAmount: 0,
    paymentStatus: PaymentStatus.unpaid,
    paymentMode: PaymentMode.cash,
    createdAt: now,
    updatedAt: now,
    items: [
      InvoiceItem(
        id: 'li1',
        invoiceId: 'i1',
        name: 'Widget',
        quantity: 10,
        unitPrice: 100,
        discountPercentage: 0,
        discountAmount: 0,
        taxRate: 18,
        taxAmount: 180,
        totalAmount: 1180,
        hsnCode: '8471',
      ),
    ],
  );

  // Gujarat seller. Same-state buyer is intra-state; Maharashtra is inter.
  final seller = businessIn('Gujarat', '24AAACC1206D1ZM');
  final intraBuyer = partyIn('Gujarat', '24AAPFU0939F1ZV');
  final interBuyer = partyIn('Maharashtra', '27AAPFU0939F1ZV');
  final legacyBuyer = partyIn(null, null);

  group('GST invoice PDFs render for both supply types', () {
    Future<void> expectRenders(Party party, String label) async {
      // Each generator builds a full multi-page document; a column-count or
      // row-count mismatch throws during layout, which is what we are guarding.
      final classic = await InvoicePdfService.generateInvoicePdf(
        invoice: invoice(),
        business: seller,
        party: party,
      );
      expect(await classic.save(), isNotEmpty, reason: 'classic/$label');

      final design2 = await InvoicePdfService.generateGstDesign2Pdf(
        invoice: invoice(),
        business: seller,
        party: party,
      );
      expect(await design2.save(), isNotEmpty, reason: 'design2/$label');

      final design3 = await InvoicePdfService.generateGstDesign3Pdf(
        invoice: invoice(),
        business: seller,
        party: party,
      );
      expect(await design3.save(), isNotEmpty, reason: 'design3/$label');
    }

    test('intra-state (Gujarat -> Gujarat)', () async {
      await expectRenders(intraBuyer, 'intra');
    });

    test('inter-state (Gujarat -> Maharashtra)', () async {
      await expectRenders(interBuyer, 'inter');
    });

    test('party with no state recorded still renders', () async {
      // Parties created before the state field existed must keep working and
      // stay on the previous intra-state treatment.
      await expectRenders(legacyBuyer, 'legacy');
    });
  });
}
