import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vyaparsetu/components/avatar.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/gst.dart';
import 'package:vyaparsetu/types/account.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/types/invoice.dart';

/// Builds the printable bill: a classic tax invoice for GST bills and a plain
/// one for non-GST bills. All amounts come from the server, so nothing here
/// recalculates tax.
class InvoicePdfService {
  InvoicePdfService._();

  static const PdfColor _ink = PdfColors.black;
  static const PdfColor _muted = PdfColor.fromInt(0xFF555555);
  static const PdfColor _line = PdfColor.fromInt(0xFF9E9E9E);
  static const PdfColor _tint = PdfColor.fromInt(0xFFF2F4F5);

  static final NumberFormat _number = NumberFormat('#,##,##0.00', 'en_IN');

  static Future<Uint8List> generate({
    required Invoice invoice,
    required Business business,
    Account? bankAccount,
  }) async {
    final fonts = await _loadFonts();
    final logo = await _image(business.logoUrl);
    final signature = await _image(business.signatureUrl);

    final document = pw.Document(
      title: invoice.invoiceNumber,
      author: business.name,
    );
    final design = BillDesign.forTaxMode(invoice.taxMode);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: _muted),
          ),
        ),
        build: (context) => design == BillDesign.gstClassic
            ? _classic(
                invoice: invoice,
                business: business,
                bankAccount: bankAccount,
                logo: logo,
                signature: signature,
                fonts: fonts,
              )
            : _simple(
                invoice: invoice,
                business: business,
                bankAccount: bankAccount,
                logo: logo,
                signature: signature,
                fonts: fonts,
              ),
      ),
    );
    return document.save();
  }

  /// Saves the bill and opens the share sheet (WhatsApp, email, ...).
  static Future<void> share({
    required Uint8List bytes,
    required String fileName,
    String? message,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: message ?? fileName),
    );
  }

  static Future<void> printBill(Uint8List bytes, String fileName) {
    return Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
  }

  // ---------------------------------------------------------------- helpers

  static Future<_Fonts> _loadFonts() async {
    // Noto Sans covers the rupee sign; the built-in PDF fonts do not. When the
    // font cannot be fetched (offline), the package quietly hands back
    // Helvetica, so check the font we actually got rather than trusting it.
    try {
      final regular = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      final name = regular.fontName.toLowerCase();
      return _Fonts(regular: regular, bold: bold, hasRupee: name.contains('noto'));
    } catch (_) {
      return _Fonts(
        regular: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        hasRupee: false,
      );
    }
  }

  static Future<pw.ImageProvider?> _image(String? source) async {
    if (source == null || source.isEmpty) return null;
    final bytes = decodeImageDataUri(source);
    if (bytes != null) return pw.MemoryImage(bytes);
    if (source.startsWith('http')) {
      try {
        return await networkImage(source);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String _plain(double amount) => _number.format(amount);

  static String _date(DateTime? date) =>
      date == null ? '-' : DateFormat('dd/MM/yyyy').format(date);

  static String _title(Invoice invoice, Business business) => switch (invoice.invoiceType) {
    InvoiceType.sale => invoice.isGst
        ? 'TAX INVOICE'
        : business.gstRegistrationType == GstRegistrationType.composition
        ? 'BILL OF SUPPLY'
        : 'INVOICE',
    InvoiceType.purchase => 'PURCHASE BILL',
    InvoiceType.saleReturn => 'CREDIT NOTE',
    InvoiceType.purchaseReturn => 'DEBIT NOTE',
  };

  static List<String> _businessLines(Business business) => [
    ...?business.address?.lines,
    if (business.phone != null) 'Phone: ${business.phone}',
    if (business.email != null) 'Email: ${business.email}',
  ];

  static pw.Widget _text(
    String value, {
    double size = 8.5,
    bool bold = false,
    PdfColor color = _ink,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Text(
      value,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
    );
  }

  static pw.Widget _cell(
    String value, {
    double size = 8,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor color = _ink,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: _text(value, size: size, bold: bold, align: align, color: color),
    );
  }

  /// "Label: value" line used in the detail boxes.
  static pw.Widget _pair(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 62, child: _text(label, size: 8, color: _muted)),
          pw.Expanded(child: _text(value, size: 8, bold: bold)),
        ],
      ),
    );
  }

  static pw.Widget _box({
    required pw.Widget child,
    PdfColor? color,
    pw.EdgeInsets padding = const pw.EdgeInsets.all(6),
  }) {
    return pw.Container(
      width: double.infinity,
      padding: padding,
      decoration: pw.BoxDecoration(
        color: color,
        border: pw.Border.all(color: _line, width: 0.5),
      ),
      child: child,
    );
  }

  static pw.Widget _sectionTitle(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: _text(title, size: 8, bold: true, color: _muted),
  );

  static List<String> _partyLines(Invoice invoice) => [
    if (invoice.billingAddress != null) ...invoice.billingAddress!.lines,
    if (invoice.partyGstin != null) 'GSTIN: ${invoice.partyGstin}',
    if (stateNameFromCode(invoice.partyStateCode) case final state?) 'State: $state',
  ];

  static List<String> _transportLines(Invoice invoice) => [
    if (invoice.vehicleNo != null) 'Vehicle: ${invoice.vehicleNo}',
    if (invoice.driverName != null)
      'Driver: ${invoice.driverName}${invoice.driverPhone == null ? '' : ' (${invoice.driverPhone})'}',
    if (invoice.transportMode != null) 'Mode: ${invoice.transportMode!.value}',
    if (invoice.lrNo != null) 'LR No: ${invoice.lrNo} ${invoice.lrDate == null ? '' : 'dt ${_date(invoice.lrDate)}'}',
    if (invoice.ewayBillNo != null)
      'E-way Bill: ${invoice.ewayBillNo} ${invoice.ewayBillDate == null ? '' : 'dt ${_date(invoice.ewayBillDate)}'}',
    if (invoice.chalanNo != null) 'Challan No: ${invoice.chalanNo}',
    if (invoice.deliveryDate != null) 'Delivery: ${_date(invoice.deliveryDate)}',
  ];

  static List<String> _bankLines(Account? account) {
    if (account == null) return const [];
    return [
      if (account.bankName != null) 'Bank: ${account.bankName}',
      if (account.accountNumber != null) 'A/c No: ${account.accountNumber}',
      if (account.ifsc != null) 'IFSC: ${account.ifsc}',
      if (account.upiId != null) 'UPI: ${account.upiId}',
    ];
  }

  static pw.Widget _header({
    required Business business,
    required Invoice invoice,
    required pw.ImageProvider? logo,
    required bool boxed,
  }) {
    final content = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null) ...[
          pw.Container(width: 54, height: 54, child: pw.Image(logo, fit: pw.BoxFit.contain)),
          pw.SizedBox(width: 10),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _text(business.name, size: 15, bold: true),
              if (business.legalName != null && business.legalName != business.name)
                _text(business.legalName!, size: 8, color: _muted),
              for (final line in _businessLines(business)) _text(line, size: 8, color: _muted),
              if (business.gstin != null) _text('GSTIN: ${business.gstin}', size: 8.5, bold: true),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _text(_title(invoice, business), size: 13, bold: true),
            if (invoice.isCancelled)
              _text('CANCELLED', size: 10, bold: true, color: PdfColors.red),
            if (invoice.isDraft) _text('DRAFT', size: 10, bold: true, color: _muted),
          ],
        ),
      ],
    );
    return boxed ? _box(child: content, padding: const pw.EdgeInsets.all(8)) : content;
  }

  /// Side-by-side boxes of equal width. A table, not a stretched row: inside a
  /// MultiPage a stretched row has no height to stretch to.
  static pw.Widget _columns(List<pw.Widget> cells) {
    if (cells.isEmpty) return pw.SizedBox();
    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      columnWidths: {
        for (var index = 0; index < cells.length; index++) index: const pw.FlexColumnWidth(),
      },
      children: [pw.TableRow(children: cells)],
    );
  }

  static pw.Widget _meta(Invoice invoice, {required bool gst}) {
    return _columns([
      _box(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _sectionTitle('BILL TO'),
            _text(
              invoice.partyName.isEmpty ? 'Walk-in customer' : invoice.partyName,
              size: 10,
              bold: true,
            ),
            for (final line in _partyLines(invoice)) _text(line, size: 8),
          ],
        ),
      ),
      _box(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pair('Invoice No', invoice.invoiceNumber, bold: true),
            _pair('Date', _date(invoice.invoiceDate)),
            if (invoice.dueDate != null) _pair('Due date', _date(invoice.dueDate)),
            if (invoice.supplierInvoiceNumber != null)
              _pair('Supplier bill', invoice.supplierInvoiceNumber!),
            if (gst)
              _pair(
                'Place of supply',
                stateNameFromCode(invoice.placeOfSupply) ?? invoice.placeOfSupply ?? '-',
              ),
            if (gst && invoice.isReverseCharge) _pair('Reverse charge', 'Yes'),
          ],
        ),
      ),
    ]);
  }

  static pw.Widget _shipAndTransport(Invoice invoice) {
    final shipping = invoice.shipTo ?? invoice.shippingAddress;
    final transport = _transportLines(invoice);
    if ((shipping?.isEmpty ?? true) && transport.isEmpty) return pw.SizedBox();

    return _columns([
      if (shipping != null && !shipping.isEmpty)
        _box(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle('SHIP TO'),
              for (final line in shipping.lines) _text(line, size: 8),
            ],
          ),
        ),
      if (transport.isNotEmpty)
        _box(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle('TRANSPORT'),
              for (final line in transport) _text(line, size: 8),
            ],
          ),
        ),
    ]);
  }

  static pw.TableRow _headerRow(List<String> labels, List<pw.TextAlign> aligns) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _tint),
      children: [
        for (final (index, label) in labels.indexed)
          _cell(label, bold: true, size: 8, align: aligns[index]),
      ],
    );
  }

  static pw.Widget _totalsRow(String label, String value, {bool bold = false, double size = 8.5}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _text(label, size: size, bold: bold),
          _text(value, size: size, bold: bold),
        ],
      ),
    );
  }

  static pw.Widget _signature({
    required Business business,
    required pw.ImageProvider? signature,
  }) {
    return pw.Container(
      width: 150,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _text('For ${business.name}', size: 8.5, bold: true, align: pw.TextAlign.center),
          if (signature != null)
            pw.Container(height: 40, child: pw.Image(signature, fit: pw.BoxFit.contain))
          else
            pw.SizedBox(height: 40),
          pw.Container(height: 0.5, color: _line),
          pw.SizedBox(height: 2),
          _text('Authorised Signatory', size: 8, color: _muted),
        ],
      ),
    );
  }

  static List<pw.Widget> _footerBlocks({
    required Invoice invoice,
    required Business business,
    required Account? bankAccount,
    required pw.ImageProvider? signature,
    required _Fonts fonts,
  }) {
    final bank = _bankLines(bankAccount);
    final terms = invoice.terms ?? business.settings.invoiceTerms;

    return [
      pw.SizedBox(height: 6),
      _box(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _text('Amount in words', size: 8, color: _muted),
            _text(Formatters.amountInWords(invoice.totalAmount), size: 9, bold: true),
          ],
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (bank.isNotEmpty) ...[
                  _sectionTitle('BANK DETAILS'),
                  for (final line in bank) _text(line, size: 8),
                  pw.SizedBox(height: 6),
                ],
                if (invoice.notes != null) ...[
                  _sectionTitle('NOTES'),
                  _text(invoice.notes!, size: 8),
                  pw.SizedBox(height: 6),
                ],
                if (terms != null && terms.trim().isNotEmpty) ...[
                  _sectionTitle('TERMS & CONDITIONS'),
                  _text(terms, size: 7.5, color: _muted),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          _signature(business: business, signature: signature),
        ],
      ),
    ];
  }

  // ------------------------------------------------------------ GST classic

  static List<pw.Widget> _classic({
    required Invoice invoice,
    required Business business,
    required Account? bankAccount,
    required pw.ImageProvider? logo,
    required pw.ImageProvider? signature,
    required _Fonts fonts,
  }) {
    final interState = invoice.isInterState;
    final money = fonts.money;

    final labels = [
      '#',
      'Description',
      'HSN',
      'Qty',
      'Rate',
      'Taxable',
      if (interState) 'IGST' else 'CGST',
      if (!interState) 'SGST',
      'Amount',
    ];
    final aligns = [
      pw.TextAlign.center,
      pw.TextAlign.left,
      pw.TextAlign.center,
      pw.TextAlign.right,
      pw.TextAlign.right,
      pw.TextAlign.right,
      pw.TextAlign.right,
      if (!interState) pw.TextAlign.right,
      pw.TextAlign.right,
    ];

    pw.TableRow lineRow(int index, InvoiceLine line) {
      final taxColumns = interState
          ? [_cell(_taxCell(line.igstAmount, line.taxRate), align: pw.TextAlign.right)]
          : [
              _cell(_taxCell(line.cgstAmount, line.taxRate / 2), align: pw.TextAlign.right),
              _cell(_taxCell(line.sgstAmount, line.taxRate / 2), align: pw.TextAlign.right),
            ];
      return pw.TableRow(
        children: [
          _cell('$index', align: pw.TextAlign.center),
          _cell(line.description),
          _cell(line.hsnSac ?? '-', align: pw.TextAlign.center),
          _cell(
            '${Formatters.formatNumber(line.quantity)} ${line.unitCode ?? ''}'.trim(),
            align: pw.TextAlign.right,
          ),
          _cell(_plain(line.unitPrice), align: pw.TextAlign.right),
          _cell(_plain(line.taxableValue), align: pw.TextAlign.right),
          ...taxColumns,
          _cell(_plain(line.lineTotal), align: pw.TextAlign.right, bold: true),
        ],
      );
    }

    return [
      _header(business: business, invoice: invoice, logo: logo, boxed: true),
      _meta(invoice, gst: true),
      _shipAndTransport(invoice),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: _line, width: 0.5),
        columnWidths: {
          0: const pw.FixedColumnWidth(18),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FixedColumnWidth(42),
          3: const pw.FixedColumnWidth(52),
          4: const pw.FixedColumnWidth(48),
          5: const pw.FixedColumnWidth(54),
          6: const pw.FixedColumnWidth(58),
          7: const pw.FixedColumnWidth(58),
          // Inter-state prints one IGST column instead of CGST + SGST.
          if (!interState) 8: const pw.FixedColumnWidth(58),
        },
        children: [
          _headerRow(labels, aligns),
          for (final (index, line) in invoice.lines.indexed) lineRow(index + 1, line),
        ],
      ),
      if (invoice.charges.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        _box(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle('OTHER CHARGES'),
              for (final charge in invoice.charges)
                _totalsRow(
                  [
                    charge.chargeType.value,
                    ?charge.description,
                    if (charge.vehicleNo != null) '(${charge.vehicleNo})',
                    if (charge.billTo == ChargeBillTo.payeeOnly) '- not billed',
                  ].join(' '),
                  money(charge.total),
                  size: 8,
                ),
            ],
          ),
        ),
      ],
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: pw.SizedBox()),
          pw.Container(
            width: 230,
            child: _box(
              child: pw.Column(
                children: [
                  _totalsRow('Taxable value', money(invoice.taxableTotal)),
                  if (invoice.discountTotal > 0)
                    _totalsRow('Discount', '- ${money(invoice.discountTotal)}'),
                  if (invoice.cgstTotal > 0) _totalsRow('CGST', money(invoice.cgstTotal)),
                  if (invoice.sgstTotal > 0) _totalsRow('SGST', money(invoice.sgstTotal)),
                  if (invoice.igstTotal > 0) _totalsRow('IGST', money(invoice.igstTotal)),
                  if (invoice.cessTotal > 0) _totalsRow('Cess', money(invoice.cessTotal)),
                  if (invoice.chargesTotal > 0)
                    _totalsRow('Other charges', money(invoice.chargesTotal)),
                  if (invoice.roundOff != 0) _totalsRow('Round off', money(invoice.roundOff)),
                  pw.Divider(color: _line, height: 8),
                  _totalsRow('Total', money(invoice.totalAmount), bold: true, size: 10),
                  if (invoice.amountSettled > 0)
                    _totalsRow('Paid', money(invoice.amountSettled), size: 8),
                  if (invoice.outstanding > 0.004)
                    _totalsRow('Balance due', money(invoice.outstanding), bold: true),
                ],
              ),
            ),
          ),
        ],
      ),
      ..._footerBlocks(
        invoice: invoice,
        business: business,
        bankAccount: bankAccount,
        signature: signature,
        fonts: fonts,
      ),
    ];
  }

  static String _taxCell(double amount, double rate) =>
      '${_plain(amount)}\n@ ${Formatters.formatNumber(rate, maxDecimals: 2)}%';

  // ---------------------------------------------------------- non-GST bill

  static List<pw.Widget> _simple({
    required Invoice invoice,
    required Business business,
    required Account? bankAccount,
    required pw.ImageProvider? logo,
    required pw.ImageProvider? signature,
    required _Fonts fonts,
  }) {
    final money = fonts.money;

    return [
      _header(business: business, invoice: invoice, logo: logo, boxed: false),
      pw.Divider(color: _line, thickness: 1, height: 14),
      _meta(invoice, gst: false),
      _shipAndTransport(invoice),
      pw.SizedBox(height: 8),
      pw.Table(
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _line, width: 0.4),
          bottom: pw.BorderSide(color: _line, width: 0.4),
        ),
        columnWidths: {
          0: const pw.FixedColumnWidth(20),
          1: const pw.FlexColumnWidth(),
          2: const pw.FixedColumnWidth(62),
          3: const pw.FixedColumnWidth(62),
          4: const pw.FixedColumnWidth(70),
        },
        children: [
          _headerRow(
            ['#', 'Item', 'Qty', 'Rate', 'Amount'],
            [
              pw.TextAlign.center,
              pw.TextAlign.left,
              pw.TextAlign.right,
              pw.TextAlign.right,
              pw.TextAlign.right,
            ],
          ),
          for (final (index, line) in invoice.lines.indexed)
            pw.TableRow(
              children: [
                _cell('${index + 1}', align: pw.TextAlign.center),
                _cell(line.description),
                _cell(
                  '${Formatters.formatNumber(line.quantity)} ${line.unitCode ?? ''}'.trim(),
                  align: pw.TextAlign.right,
                ),
                _cell(_plain(line.unitPrice), align: pw.TextAlign.right),
                _cell(_plain(line.lineTotal), align: pw.TextAlign.right, bold: true),
              ],
            ),
          for (final charge in invoice.charges)
            if (charge.billTo == ChargeBillTo.invoiceParty)
              pw.TableRow(
                children: [
                  _cell(''),
                  _cell([charge.chargeType.value, ?charge.description].join(' ')),
                  _cell(''),
                  _cell(''),
                  _cell(_plain(charge.total), align: pw.TextAlign.right),
                ],
              ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _text('Amount in words', size: 8, color: _muted),
                _text(Formatters.amountInWords(invoice.totalAmount), size: 9, bold: true),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Container(
            width: 200,
            child: pw.Column(
              children: [
                if (invoice.discountTotal > 0)
                  _totalsRow('Discount', '- ${money(invoice.discountTotal)}'),
                if (invoice.roundOff != 0) _totalsRow('Round off', money(invoice.roundOff)),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  color: _tint,
                  child: _totalsRow('Total', money(invoice.totalAmount), bold: true, size: 11),
                ),
                if (invoice.amountSettled > 0)
                  _totalsRow('Paid', money(invoice.amountSettled), size: 8),
                if (invoice.outstanding > 0.004)
                  _totalsRow('Balance due', money(invoice.outstanding), bold: true),
              ],
            ),
          ),
        ],
      ),
      ..._footerBlocks(
        invoice: invoice,
        business: business,
        bankAccount: bankAccount,
        signature: signature,
        fonts: fonts,
      ),
    ];
  }
}

class _Fonts {
  final pw.Font regular;
  final pw.Font bold;

  /// The built-in PDF fonts have no ₹ glyph, so those bills print "Rs.".
  final bool hasRupee;

  const _Fonts({required this.regular, required this.bold, required this.hasRupee});

  String Function(double) get money =>
      (amount) => hasRupee
          ? '₹ ${InvoicePdfService._plain(amount)}'
          : 'Rs. ${InvoicePdfService._plain(amount)}';
}
