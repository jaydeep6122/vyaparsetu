import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/types/item.dart';
import 'package:vyaparsetu/services/invoicePdfService.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/core/Core.dart';

class InvoicePdfScreen extends StatelessWidget {
  final Invoice invoice;
  final Party? party;
  final List<Item>? catalogItems;

  const InvoicePdfScreen({
    super.key,
    required this.invoice,
    this.party,
    this.catalogItems,
  });

  @override
  Widget build(BuildContext context) {
    final invoice = this.invoice;
    final business = context.select<Core, Business?>((c) => c.business.selectedBusiness);
    final resolvedParty = party ??
        _resolveParty(context, invoice.partyId);
    final resolvedItems = catalogItems ??
        context.read<Core>().item.items;


    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice PDF')),
        body: const Center(child: Text('Business profile not loaded')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Invoice PDF Preview',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: PdfPreview(
        build: (format) async {
          final doc = await InvoicePdfService.generateInvoicePdf(
            invoice: invoice,
            business: business,
            party: resolvedParty,
            catalogItems: resolvedItems,
          );
          return doc.save();
        },
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: 'Invoice-${invoice.invoiceNumber}.pdf',
      ),
    );
  }

  Party? _resolveParty(BuildContext context, String? partyId) {
    if (partyId == null) return null;
    final parties = context.read<Core>().party.parties;
    try {
      return parties.firstWhere((p) => p.id == partyId);
    } catch (_) {
      return null;
    }
  }
}
