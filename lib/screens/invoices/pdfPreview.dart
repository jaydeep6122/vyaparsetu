import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/types/item.dart';
import 'package:vyaparsetu/services/invoicePdfService.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/storage/hive/preferences.dart';

class InvoicePdfScreen extends StatefulWidget {
  final Invoice invoice;
  final Party? party;
  final List<Item>? catalogItems;
  final BillDesign design;

  const InvoicePdfScreen({
    super.key,
    required this.invoice,
    this.party,
    this.catalogItems,
    this.design = BillDesign.gstClassic,
  });

  @override
  State<InvoicePdfScreen> createState() => _InvoicePdfScreenState();
}

class _InvoicePdfScreenState extends State<InvoicePdfScreen> {
  late BillDesign _currentDesign;
  late int _previewKey;

  @override
  void initState() {
    super.initState();
    _currentDesign = widget.design;
    _previewKey = 0;
  }

  List<BillDesign> get _availableDesigns {
    final billType = InvoicePdfService.billTypeFromNotes(widget.invoice);
    return InvoicePdfService.availableDesigns(billType);
  }

  void _onDesignChanged(BillDesign? design) {
    if (design == null || design == _currentDesign) return;
    setState(() {
      _currentDesign = design;
      _previewKey++;
    });
    PreferencesBox.setInvoiceDesign(design.value);
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final business = context.select<Core, Business?>(
      (c) => c.business.selectedBusiness,
    );
    final resolvedParty =
        widget.party ?? _resolveParty(context, invoice.partyId);
    final resolvedItems =
        widget.catalogItems ?? context.read<Core>().item.items;

    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice PDF')),
        body: const Center(child: Text('Business profile not loaded')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentDesign.displayName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<BillDesign>(
            icon: const Icon(Icons.style_rounded),
            tooltip: 'Change Design',
            onSelected: _onDesignChanged,
            itemBuilder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final selectedColor = isDark
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary;
              return _availableDesigns.map((d) {
                final isSelected = d == _currentDesign;
                return PopupMenuItem<BillDesign>(
                  value: d,
                  child: Row(
                    children: [
                      Icon(
                        d.isGst
                            ? Icons.receipt_long_rounded
                            : Icons.receipt_rounded,
                        size: 20,
                        color: isSelected ? selectedColor : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        d.displayName,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? selectedColor : null,
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        Icon(Icons.check, size: 18, color: selectedColor),
                      ],
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: PdfPreview(
        key: ValueKey(_previewKey),
        build: (format) async {
          final doc = await InvoicePdfService.generatePdfByDesign(
            invoice: invoice,
            business: business,
            party: resolvedParty,
            catalogItems: resolvedItems,
            design: _currentDesign,
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
