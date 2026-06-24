import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/global/constants.dart';

class ReportService {
  static final _format =
      NumberFormat.decimalPattern('en_IN')
        ..minimumFractionDigits = 2
        ..maximumFractionDigits = 2;

  static String _f(double amount) => _format.format(amount);
  static String _d(DateTime dt) => DateFormat('d MMM yyyy', 'en').format(dt);

  // ── Business Health Report ──────────────────────────────────────────

  static Future<void> generateBusinessHealthReport({
    required Business business,
    required List<Invoice> invoices,
    required String period,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();

    final saleInvoices =
        invoices.where((i) => i.invoiceType == InvoiceType.sale).toList();
    final purchaseInvoices =
        invoices.where((i) => i.invoiceType == InvoiceType.purchase).toList();

    final saleBase = saleInvoices.fold(0.0, (s, i) => s + i.subTotal);
    final saleTax = saleInvoices.fold(0.0, (s, i) => s + i.taxAmount);
    final saleTotal = saleInvoices.fold(0.0, (s, i) => s + i.totalAmount);
    final saleReceived = saleInvoices.fold(0.0, (s, i) => s + i.paidAmount);
    final purchaseBase = purchaseInvoices.fold(0.0, (s, i) => s + i.subTotal);
    final purchaseTax = purchaseInvoices.fold(0.0, (s, i) => s + i.taxAmount);
    final purchaseTotal = purchaseInvoices.fold(
      0.0,
      (s, i) => s + i.totalAmount,
    );
    final purchasePaid = purchaseInvoices.fold(0.0, (s, i) => s + i.paidAmount);
    final netProfit = saleTotal - purchaseTotal;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build:
            (ctx) => [
              _header(business, 'Business Health Report', period, bold, font),
              pw.SizedBox(height: 16),
              _sectionTitle('Profit / Loss Summary', bold),
              pw.SizedBox(height: 8),
              _keyValue(
                'Net Profit / Loss',
                _f(netProfit),
                netProfit >= 0,
                bold,
                font,
              ),
              pw.SizedBox(height: 20),
              _sectionTitle('Sales Metrics', bold),
              pw.SizedBox(height: 8),
              _keyValue('Base (excl. GST)', _f(saleBase), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue('GST Amount', _f(saleTax), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue('Total (incl. GST)', _f(saleTotal), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue('Received', _f(saleReceived), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue(
                'Outstanding',
                _f(saleTotal - saleReceived),
                false,
                bold,
                font,
              ),
              pw.SizedBox(height: 20),
              _sectionTitle('Purchase Metrics', bold),
              pw.SizedBox(height: 8),
              _keyValue(
                'Base (excl. GST)',
                _f(purchaseBase),
                false,
                bold,
                font,
              ),
              pw.SizedBox(height: 4),
              _keyValue('GST Amount', _f(purchaseTax), false, bold, font),
              pw.SizedBox(height: 4),
              _keyValue(
                'Total (incl. GST)',
                _f(purchaseTotal),
                false,
                bold,
                font,
              ),
              pw.SizedBox(height: 4),
              _keyValue('Paid', _f(purchasePaid), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue(
                'Pending Payables',
                _f(purchaseTotal - purchasePaid),
                false,
                bold,
                font,
              ),
              pw.SizedBox(height: 20),
              _footer(bold, font),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // ── Sales Report ────────────────────────────────────────────────────

  static Future<void> generateSalesReport({
    required Business business,
    required List<Invoice> invoices,
    required String period,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();

    final sorted = List<Invoice>.from(invoices)
      ..sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));
    final totalBase = sorted.fold(0.0, (s, i) => s + i.subTotal);
    final totalTax = sorted.fold(0.0, (s, i) => s + i.taxAmount);
    final totalAmount = sorted.fold(0.0, (s, i) => s + i.totalAmount);
    final totalReceived = sorted.fold(0.0, (s, i) => s + i.paidAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build:
            (ctx) => [
              _header(business, 'Sales Report', period, bold, font),
              pw.SizedBox(height: 16),
              _table(
                headers: [
                  'Date',
                  'Invoice No',
                  'Party',
                  'Base',
                  'GST',
                  'Total',
                  'Paid',
                  'Status',
                ],
                widths: const [60, 70, 110, 55, 55, 55, 55, 55],
                rows:
                    sorted
                        .map(
                          (i) => [
                            _d(i.invoiceDate),
                            i.invoiceNumber,
                            i.partyName ?? '-',
                            _f(i.subTotal),
                            _f(i.taxAmount),
                            _f(i.totalAmount),
                            _f(i.paidAmount),
                            i.paymentStatus.name.replaceAll('_', ' ').toUpperCase(),
                          ],
                        )
                        .toList(),
                font: font,
                bold: bold,
              ),
              pw.SizedBox(height: 16),
              _sectionTitle('Summary', bold),
              pw.SizedBox(height: 8),
              _keyValue('Base (excl. GST)', _f(totalBase), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue('GST Amount', _f(totalTax), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue('Total (incl. GST)', _f(totalAmount), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue('Received', _f(totalReceived), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue(
                'Outstanding',
                _f(totalAmount - totalReceived),
                false,
                bold,
                font,
              ),
              pw.SizedBox(height: 4),
              _keyValue(
                'Number of Invoices',
                '${sorted.length}',
                true,
                bold,
                font,
              ),
              pw.SizedBox(height: 20),
              _footer(bold, font),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // ── Purchase Report ─────────────────────────────────────────────────

  static Future<void> generatePurchaseReport({
    required Business business,
    required List<Invoice> invoices,
    required String period,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();

    final sorted = List<Invoice>.from(invoices)
      ..sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));
    final totalBase = sorted.fold(0.0, (s, i) => s + i.subTotal);
    final totalTax = sorted.fold(0.0, (s, i) => s + i.taxAmount);
    final totalAmount = sorted.fold(0.0, (s, i) => s + i.totalAmount);
    final totalPaid = sorted.fold(0.0, (s, i) => s + i.paidAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build:
            (ctx) => [
              _header(business, 'Purchase Report', period, bold, font),
              pw.SizedBox(height: 16),
              _table(
                headers: [
                  'Date',
                  'Invoice No',
                  'Supplier',
                  'Base',
                  'GST',
                  'Total',
                  'Paid',
                  'Status',
                ],
                widths: const [60, 70, 110, 55, 55, 55, 55, 55],
                rows:
                    sorted
                        .map(
                          (i) => [
                            _d(i.invoiceDate),
                            i.invoiceNumber,
                            i.partyName ?? '-',
                            _f(i.subTotal),
                            _f(i.taxAmount),
                            _f(i.totalAmount),
                            _f(i.paidAmount),
                            i.paymentStatus.name.replaceAll('_', ' ').toUpperCase(),
                          ],
                        )
                        .toList(),
                font: font,
                bold: bold,
              ),
              pw.SizedBox(height: 16),
              _sectionTitle('Summary', bold),
              pw.SizedBox(height: 8),
              _keyValue('Base (excl. GST)', _f(totalBase), false, bold, font),
              pw.SizedBox(height: 4),
              _keyValue('GST Amount', _f(totalTax), false, bold, font),
              pw.SizedBox(height: 4),
              _keyValue(
                'Total (incl. GST)',
                _f(totalAmount),
                false,
                bold,
                font,
              ),
              pw.SizedBox(height: 4),
              _keyValue('Paid', _f(totalPaid), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue(
                'Pending Payables',
                _f(totalAmount - totalPaid),
                false,
                bold,
                font,
              ),
              pw.SizedBox(height: 4),
              _keyValue(
                'Number of Purchases',
                '${sorted.length}',
                true,
                bold,
                font,
              ),
              pw.SizedBox(height: 20),
              _footer(bold, font),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // ── Customer Report ─────────────────────────────────────────────────

  static Future<void> generateCustomerReport({
    required Business business,
    required String partyName,
    required List<Invoice> invoices,
    required String period,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();

    final sorted = List<Invoice>.from(invoices)
      ..sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));
    final totalBase = sorted.fold(0.0, (s, i) => s + i.subTotal);
    final totalTax = sorted.fold(0.0, (s, i) => s + i.taxAmount);
    final totalAmount = sorted.fold(0.0, (s, i) => s + i.totalAmount);
    final totalReceived = sorted.fold(0.0, (s, i) => s + i.paidAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build:
            (ctx) => [
              _header(business, 'Customer Report', period, bold, font),
              pw.SizedBox(height: 12),
              pw.Text(
                'Party: $partyName',
                style: pw.TextStyle(font: bold, fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              _table(
                headers: [
                  'Date',
                  'Invoice No',
                  'Base',
                  'GST',
                  'Total',
                  'Paid',
                  'Status',
                ],
                widths: const [65, 90, 60, 60, 60, 60, 55],
                rows:
                    sorted
                        .map(
                          (i) => [
                            _d(i.invoiceDate),
                            i.invoiceNumber,
                            _f(i.subTotal),
                            _f(i.taxAmount),
                            _f(i.totalAmount),
                            _f(i.paidAmount),
                            i.paymentStatus.name.replaceAll('_', ' ').toUpperCase(),
                          ],
                        )
                        .toList(),
                font: font,
                bold: bold,
              ),
              pw.SizedBox(height: 16),
              _sectionTitle('Summary', bold),
              pw.SizedBox(height: 8),
              _keyValue('Base (excl. GST)', _f(totalBase), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue('GST Amount', _f(totalTax), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue('Total (incl. GST)', _f(totalAmount), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue('Received', _f(totalReceived), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue(
                'Outstanding',
                _f(totalAmount - totalReceived),
                false,
                bold,
                font,
              ),
              pw.SizedBox(height: 4),
              _keyValue(
                'Number of Invoices',
                '${sorted.length}',
                true,
                bold,
                font,
              ),
              pw.SizedBox(height: 20),
              _footer(bold, font),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // ── Supplier Report ─────────────────────────────────────────────────

  static Future<void> generateSupplierReport({
    required Business business,
    required String partyName,
    required List<Invoice> invoices,
    required String period,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();

    final sorted = List<Invoice>.from(invoices)
      ..sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));
    final totalBase = sorted.fold(0.0, (s, i) => s + i.subTotal);
    final totalTax = sorted.fold(0.0, (s, i) => s + i.taxAmount);
    final totalAmount = sorted.fold(0.0, (s, i) => s + i.totalAmount);
    final totalPaid = sorted.fold(0.0, (s, i) => s + i.paidAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build:
            (ctx) => [
              _header(business, 'Supplier Report', period, bold, font),
              pw.SizedBox(height: 12),
              pw.Text(
                'Party: $partyName',
                style: pw.TextStyle(font: bold, fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              _table(
                headers: [
                  'Date',
                  'Invoice No',
                  'Base',
                  'GST',
                  'Total',
                  'Paid',
                  'Status',
                ],
                widths: const [65, 90, 60, 60, 60, 60, 55],
                rows:
                    sorted
                        .map(
                          (i) => [
                            _d(i.invoiceDate),
                            i.invoiceNumber,
                            _f(i.subTotal),
                            _f(i.taxAmount),
                            _f(i.totalAmount),
                            _f(i.paidAmount),
                            i.paymentStatus.name.replaceAll('_', ' ').toUpperCase(),
                          ],
                        )
                        .toList(),
                font: font,
                bold: bold,
              ),
              pw.SizedBox(height: 16),
              _sectionTitle('Summary', bold),
              pw.SizedBox(height: 8),
              _keyValue('Base (excl. GST)', _f(totalBase), false, bold, font),
              pw.SizedBox(height: 4),
              _keyValue('GST Amount', _f(totalTax), false, bold, font),
              pw.SizedBox(height: 4),
              _keyValue(
                'Total (incl. GST)',
                _f(totalAmount),
                false,
                bold,
                font,
              ),
              pw.SizedBox(height: 4),
              _keyValue('Paid', _f(totalPaid), true, bold, font),
              pw.SizedBox(height: 4),
              _keyValue(
                'Pending Payables',
                _f(totalAmount - totalPaid),
                false,
                bold,
                font,
              ),
              pw.SizedBox(height: 4),
              _keyValue(
                'Number of Purchases',
                '${sorted.length}',
                true,
                bold,
                font,
              ),
              pw.SizedBox(height: 20),
              _footer(bold, font),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // ── Shared PDF widgets ──────────────────────────────────────────────

  static pw.Widget _header(
    Business b,
    String title,
    String period,
    pw.Font bold,
    pw.Font font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          b.name,
          style: pw.TextStyle(
            font: bold,
            fontSize: 20,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 4),

        pw.Text(
          b.address,
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
        if (b.gstin != null && b.gstin!.isNotEmpty)
          pw.Text(
            'GSTIN: ${b.gstin}',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        pw.SizedBox(height: 8),
        pw.Container(height: 1, color: PdfColors.grey400),
        pw.SizedBox(height: 8),
        pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 16)),
        pw.Text(
          'Period: $period',
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _sectionTitle(String text, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.blue900, width: 3),
        ),
      ),
      child: pw.Text(text, style: pw.TextStyle(font: bold, fontSize: 12)),
    );
  }

  static pw.Widget _keyValue(
    String label,
    String value,
    bool isPositive,
    pw.Font bold,
    pw.Font font,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10)),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: bold,
            fontSize: 10,
            color: isPositive ? PdfColors.green800 : PdfColors.red800,
          ),
        ),
      ],
    );
  }

  static pw.Widget _table({
    required List<String> headers,
    required List<double> widths,
    required List<List<String>> rows,
    required pw.Font font,
    required pw.Font bold,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Table(
        border: const pw.TableBorder(
          verticalInside: pw.BorderSide(color: PdfColors.grey400),
          horizontalInside: pw.BorderSide(color: PdfColors.grey400),
        ),
        columnWidths: {
          for (var i = 0; i < widths.length; i++)
            i: pw.FixedColumnWidth(widths[i]),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            children: headers.map((h) => _cell(h, bold, fontSize: 9)).toList(),
          ),
          ...rows.map(
            (row) => pw.TableRow(
              children: row.map((c) => _cell(c, font, fontSize: 9)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(String text, pw.Font font, {double fontSize = 10}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: fontSize),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _footer(pw.Font bold, pw.Font font) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Text(
          'Generated by VyaparSetu',
          style: pw.TextStyle(
            font: font,
            fontSize: 8,
            color: PdfColors.grey500,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
