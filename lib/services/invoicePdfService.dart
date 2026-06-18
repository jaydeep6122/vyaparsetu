import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/types/item.dart';
import 'package:vyaparsetu/helpers/formatters.dart';

class InvoicePdfService {
  static const PdfColor primaryBlue = PdfColor.fromInt(0xFF0000FF);
  static const PdfColor primaryRed = PdfColor.fromInt(0xFFFF0000);
  static const PdfColor tableBorder = PdfColors.black;

  static final _plainFormat = NumberFormat.decimalPattern('en_IN')
    ..minimumFractionDigits = 2
    ..maximumFractionDigits = 2;

  static String _formatPlain(double amount) => _plainFormat.format(amount);

  /// Generates a Classic-style invoice PDF (matching JayKunj Enterprise design)
  static Future<pw.Document> generateInvoicePdf({
    required Invoice invoice,
    required Business business,
    Party? party,
    List<Item>? catalogItems,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    // Build item lookup map
    final itemMap = <String, Item>{};
    if (catalogItems != null) {
      for (final item in catalogItems) {
        itemMap[item.id] = item;
      }
    }

    // Load logo if available
    pw.MemoryImage? logoImage;
    if (business.logoUrl != null && business.logoUrl!.isNotEmpty) {
      try {
        String base64Str;
        if (business.logoUrl!.startsWith('data:image')) {
          base64Str = business.logoUrl!.split(',')[1];
        } else {
          base64Str = business.logoUrl!;
        }
        logoImage = pw.MemoryImage(base64Decode(base64Str));
      } catch (e) {}
    }

    // Load signature if available
    pw.MemoryImage? signatureImage;
    if (business.signatureUrl != null && business.signatureUrl!.isNotEmpty) {
      try {
        String base64Str;
        if (business.signatureUrl!.startsWith('data:image')) {
          base64Str = business.signatureUrl!.split(',')[1];
        } else {
          base64Str = business.signatureUrl!;
        }
        signatureImage = pw.MemoryImage(base64Decode(base64Str));
      } catch (e) {}
    }

    final hasGst = business.gstin != null && business.gstin!.isNotEmpty;
    final customerName = party?.name ?? invoice.partyName ?? 'Walk-in Customer';
    final customerAddress = invoice.billingAddress ??
        (party != null ? party.billingAddresses.join('\n') : '');
    final customerGstin = party?.gstin;
    final shippingSiteName = party?.name ?? customerName;
    final shippingAddress = invoice.shippingAddress ??
        (party != null
            ? (party.shippingAddresses.isNotEmpty
                ? party.shippingAddresses.join('\n')
                : customerAddress)
            : customerAddress);
    final shippingGstin = party?.gstin;

    // Compute effective GST rate
    double effectiveGstRate = 0;
    if (invoice.subTotal > 0 && invoice.taxAmount > 0) {
      effectiveGstRate = (invoice.taxAmount / invoice.subTotal) * 100;
    }
    final cgstRate = effectiveGstRate / 2;
    final sgstRate = effectiveGstRate / 2;
    final totalCgst = invoice.taxAmount / 2;
    final totalSgst = invoice.taxAmount / 2;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            _buildHeader(
              businessName: business.name,
              address: business.address,
              city: business.city,
              state: business.state,
              pincode: business.pincode,
              phone: business.phone,
              email: business.email,
              gstin: business.gstin,
              logoImage: logoImage,
              hasGst: hasGst,
              boldFont: boldFont,
            ),
            _buildInvoiceHeader(
              invoiceNumber: invoice.invoiceNumber,
              invoiceDate: invoice.invoiceDate,
              placeOfSupply: business.state,
              font: font,
              boldFont: boldFont,
            ),
            _buildBillToShipTo(
              customerName: customerName,
              customerAddress: customerAddress,
              customerGstin: customerGstin,
              shippingSiteName: shippingSiteName,
              shippingAddress: shippingAddress,
              shippingGstin: shippingGstin,
              font: font,
              boldFont: boldFont,
            ),
            _buildItemsTable(
              invoice: invoice,
              itemMap: itemMap,
              font: font,
              boldFont: boldFont,
              cgstRate: cgstRate,
              sgstRate: sgstRate,
              totalCgst: totalCgst,
              totalSgst: totalSgst,
            ),
            _buildFooter(
              invoice: invoice,
              business: business,
              font: font,
              boldFont: boldFont,
              signatureImage: signatureImage,
              cgstRate: cgstRate,
              sgstRate: sgstRate,
              totalCgst: totalCgst,
              totalSgst: totalSgst,
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader({
    required String businessName,
    required String address,
    required String city,
    required String state,
    required String pincode,
    String? phone,
    String? email,
    String? gstin,
    pw.MemoryImage? logoImage,
    required bool hasGst,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: tableBorder),
          left: pw.BorderSide(color: tableBorder),
          right: pw.BorderSide(color: tableBorder),
          bottom: pw.BorderSide(color: tableBorder),
        ),
      ),
      child: pw.Table(
        columnWidths: {
          0: const pw.FixedColumnWidth(75),
          1: const pw.FlexColumnWidth(),
          2: const pw.FixedColumnWidth(75),
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.TableRow(
            children: [
              if (logoImage != null)
                pw.Container(
                  width: 60,
                  height: 60,
                  margin: const pw.EdgeInsets.only(right: 15),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                )
              else
                pw.SizedBox(),
              pw.Column(
                children: [
                  pw.Text(
                    businessName,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 20,
                      color: primaryRed,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Add: $address, $city, $state - $pincode',
                    style: const pw.TextStyle(fontSize: 8.5, color: primaryBlue),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (phone != null || email != null)
                    pw.Text(
                      [
                        if (phone != null) 'Mob : $phone',
                        if (email != null) 'Email : $email',
                      ].join(', '),
                      style: const pw.TextStyle(fontSize: 8.5, color: primaryBlue),
                      textAlign: pw.TextAlign.center,
                    ),
                  if (gstin != null && gstin.isNotEmpty)
                    pw.Text(
                      'GSTIN : $gstin',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 9,
                        color: primaryBlue,
                      ),
                    ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    hasGst ? 'TAX INVOICE' : 'BILL',
                    style: pw.TextStyle(font: boldFont, fontSize: 13),
                  ),
                ],
              ),
              if (logoImage != null) pw.SizedBox() else pw.SizedBox(),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceHeader({
    required String invoiceNumber,
    required DateTime invoiceDate,
    required String placeOfSupply,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: tableBorder),
          right: pw.BorderSide(color: tableBorder),
          bottom: pw.BorderSide(color: tableBorder),
        ),
      ),
      child: pw.Table(
        border: const pw.TableBorder(
          verticalInside: pw.BorderSide(color: tableBorder),
          horizontalInside: pw.BorderSide(color: tableBorder),
        ),
        columnWidths: {
          0: const pw.FixedColumnWidth(318),
          1: const pw.FixedColumnWidth(237),
        },
        children: [
          pw.TableRow(
            children: [
              pw.Table(
                border: const pw.TableBorder(
                  verticalInside: pw.BorderSide(color: tableBorder),
                  horizontalInside: pw.BorderSide(color: tableBorder),
                ),
                children: [
                  pw.TableRow(
                    children: [
                      _cell('Place of Supply', boldFont, fontSize: 9),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _cell(placeOfSupply, font, fontSize: 9),
                    ],
                  ),
                ],
              ),
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(1.2),
                },
                border: const pw.TableBorder(
                  verticalInside: pw.BorderSide(color: tableBorder),
                  horizontalInside: pw.BorderSide(color: tableBorder),
                ),
                children: [
                  pw.TableRow(
                    children: [
                      _cell('Invoice No :', boldFont, fontSize: 9),
                      _cell(invoiceNumber, font, fontSize: 9),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _cell('Invoice Date :', boldFont, fontSize: 9),
                      _cell(
                        DateFormat('d/M/yyyy').format(invoiceDate),
                        font,
                        fontSize: 9,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBillToShipTo({
    required String customerName,
    required String customerAddress,
    String? customerGstin,
    required String shippingSiteName,
    required String shippingAddress,
    String? shippingGstin,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: tableBorder),
          right: pw.BorderSide(color: tableBorder),
          bottom: pw.BorderSide(color: tableBorder),
        ),
      ),
      child: pw.Table(
        border: const pw.TableBorder(
          verticalInside: pw.BorderSide(color: tableBorder),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(330),
          1: const pw.FlexColumnWidth(245),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: tableBorder, width: 0.5),
              ),
            ),
            children: [
              _cell('Bill To', boldFont, fontSize: 10),
              _cell('Ship To', boldFont, fontSize: 10),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      customerName,
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.RichText(
                      text: pw.TextSpan(
                        style: const pw.TextStyle(fontSize: 9),
                        children: [
                          pw.TextSpan(
                            text: 'Add: ',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.TextSpan(text: customerAddress),
                        ],
                      ),
                    ),
                    if (customerGstin != null && customerGstin.isNotEmpty)
                      pw.Text(
                        'GST NO: $customerGstin',
                        style: pw.TextStyle(font: boldFont, fontSize: 9),
                      ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      shippingSiteName,
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.RichText(
                      text: pw.TextSpan(
                        style: const pw.TextStyle(fontSize: 9),
                        children: [
                          pw.TextSpan(
                            text: 'Add: ',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.TextSpan(text: shippingAddress),
                        ],
                      ),
                    ),
                    if (shippingGstin != null && shippingGstin.isNotEmpty)
                      pw.Text(
                        'GST NO: $shippingGstin',
                        style: pw.TextStyle(font: boldFont, fontSize: 9),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable({
    required Invoice invoice,
    required Map<String, Item> itemMap,
    required pw.Font font,
    required pw.Font boldFont,
    required double cgstRate,
    required double sgstRate,
    required double totalCgst,
    required double totalSgst,
  }) {
    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: const pw.TableBorder(
        left: pw.BorderSide(color: tableBorder),
        right: pw.BorderSide(color: tableBorder),
        verticalInside: pw.BorderSide(color: tableBorder),
        bottom: pw.BorderSide(color: tableBorder),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FixedColumnWidth(39),
        2: const pw.FixedColumnWidth(63),
        3: const pw.FixedColumnWidth(43),
        4: const pw.FixedColumnWidth(72),
        5: const pw.FixedColumnWidth(34),
        6: const pw.FixedColumnWidth(43),
        7: const pw.FixedColumnWidth(34),
        8: const pw.FixedColumnWidth(63),
        9: const pw.FixedColumnWidth(63),
        10: const pw.FixedColumnWidth(77),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: tableBorder)),
          ),
          children: [
            _cell('Sr\nNo', boldFont, fontSize: 9, align: pw.TextAlign.center),
            _cell('HSN', boldFont, fontSize: 9, align: pw.TextAlign.center),
            _cell('Description', boldFont, fontSize: 9, align: pw.TextAlign.center),
            _cell('Challan No', boldFont, fontSize: 9, align: pw.TextAlign.center),
            _cell('Date of Delivery', boldFont, fontSize: 9, align: pw.TextAlign.center),
            _cell('Unit', boldFont, fontSize: 9, align: pw.TextAlign.center),
            _cell('Qty', boldFont, fontSize: 9, align: pw.TextAlign.center),
            _cell('Rate', boldFont, fontSize: 9, align: pw.TextAlign.center),
            _nestedGstHeader('CGST', boldFont),
            _nestedGstHeader('SGST', boldFont),
            _cell('Amount', boldFont, fontSize: 9, align: pw.TextAlign.center),
          ],
        ),
        if (invoice.items != null)
          ...invoice.items!.asMap().entries.map((entry) {
            final i = entry.key + 1;
            final item = entry.value;
            final catalogItem = item.itemId != null ? itemMap[item.itemId] : null;
            final hsn = catalogItem?.hsnCode ?? '';
            final unit = catalogItem?.measuringUnit ?? '';
            final lineAmount = item.quantity * item.unitPrice;
            final itemCgstRate = item.taxRate / 2;
            final itemSgstRate = item.taxRate / 2;
            final itemCgstAmt = lineAmount * (itemCgstRate / 100);
            final itemSgstAmt = lineAmount * (itemSgstRate / 100);

            return pw.TableRow(
              children: [
                _cell('$i', font, fontSize: 9, align: pw.TextAlign.center),
                _cell(hsn, font, fontSize: 9, align: pw.TextAlign.center),
                _cell(item.name, font, fontSize: 9),
                _cell(
                  invoice.chalanNo ?? '-',
                  font,
                  fontSize: 9,
                  align: pw.TextAlign.center,
                ),
                _cell(
                  invoice.deliveryDate != null
                      ? DateFormat('d/M/yyyy').format(invoice.deliveryDate!)
                      : '-',
                  font,
                  fontSize: 9,
                  align: pw.TextAlign.center,
                ),
                _cell(unit, font, fontSize: 9, align: pw.TextAlign.center),
                _cell(_formatPlain(item.quantity), font, fontSize: 9, align: pw.TextAlign.right),
                _cell(_formatPlain(item.unitPrice), font, fontSize: 9, align: pw.TextAlign.right),
                _gstDataRow(
                  '${itemCgstRate.toStringAsFixed(1)}%',
                  _formatPlain(itemCgstAmt),
                  font,
                ),
                _gstDataRow(
                  '${itemSgstRate.toStringAsFixed(1)}%',
                  _formatPlain(itemSgstAmt),
                  font,
                ),
                _cell(_formatPlain(lineAmount), font, fontSize: 9, align: pw.TextAlign.right),
              ],
            );
          }),
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: tableBorder)),
          ),
          children: [
            _cell('', font, fontSize: 9),
            _cell('', font, fontSize: 9),
            _cell('', font, fontSize: 9),
            _cell('', font, fontSize: 9),
            _cell('', font, fontSize: 9),
            _cell('', font, fontSize: 9),
            _cell('', font, fontSize: 9),
            _cell('Total', boldFont, fontSize: 10, align: pw.TextAlign.center),
            _gstDataRow('', _formatPlain(totalCgst), boldFont),
            _gstDataRow('', _formatPlain(totalSgst), boldFont),
            _cell(_formatPlain(invoice.totalAmount), boldFont, fontSize: 10, align: pw.TextAlign.right),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter({
    required Invoice invoice,
    required Business business,
    required pw.Font font,
    required pw.Font boldFont,
    pw.MemoryImage? signatureImage,
    required double cgstRate,
    required double sgstRate,
    required double totalCgst,
    required double totalSgst,
  }) {
    final amountInWords =
        '${Formatters.numberToWords(invoice.totalAmount.round())} Only';

    return pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: tableBorder),
        left: pw.BorderSide(color: tableBorder),
        right: pw.BorderSide(color: tableBorder),
        bottom: pw.BorderSide(color: tableBorder),
        verticalInside: pw.BorderSide(color: tableBorder),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(318),
        1: const pw.FixedColumnWidth(237),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: tableBorder, width: 0.5),
            ),
          ),
          children: [
            _cell(
              'Total in words : $amountInWords',
              boldFont,
              fontSize: 9,
            ),
            _summarySummaryRow('Sub Total Amount', invoice.subTotal, boldFont, hasBottomBorder: false),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: tableBorder, width: 0.5),
            ),
          ),
          children: [
            _cell('Companys Bank Details', boldFont, fontSize: 9),
            _summarySummaryRow(
              'Add CGST @ ${cgstRate.toStringAsFixed(1)}%',
              totalCgst,
              boldFont,
              hasBottomBorder: false,
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: tableBorder, width: 0.5),
            ),
          ),
          children: [
            _bankRowWidget('Bank Name', business.bankName ?? '', font),
            _summarySummaryRow(
              'Add SGST @ ${sgstRate.toStringAsFixed(1)}%',
              totalSgst,
              boldFont,
              hasBottomBorder: false,
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: tableBorder, width: 0.5),
            ),
          ),
          children: [
            _bankRowWidget('A/c No', business.accountNumber ?? '', font),
            _summarySummaryRow(
              'Total Amount with GST',
              invoice.subTotal + invoice.taxAmount,
              boldFont,
              hasBottomBorder: false,
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _bankRowWidget('Branch & IFSC Code', business.ifscCode ?? '', font),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: tableBorder, width: 0.5),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Terms and Conditions',
                        style: pw.TextStyle(font: boldFont, fontSize: 8),
                      ),
                      pw.Text(
                        invoice.notes ?? '1. in case of any discrepancy in the invoice we request you to get back to us on Phone number given.',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        '2. Cheque/DD to be drawn in favour of : ${business.name}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        '3. Goods once sold will not be acceped return.',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'For ${business.name}',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  if (signatureImage != null)
                    pw.Center(
                      child: pw.Container(
                        width: 100,
                        height: 50,
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      ),
                    )
                  else
                    pw.SizedBox(height: 50),
                  pw.Container(height: 0.5, color: tableBorder),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Proprietor',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _bankRowWidget(String label, String value, pw.Font font) {
    return pw.Table(
      border: const pw.TableBorder(
        verticalInside: pw.BorderSide(color: tableBorder, width: 0.5),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(106),
        1: const pw.FixedColumnWidth(212),
      },
      children: [
        pw.TableRow(
          children: [
            _cell(label, font, fontSize: 8.5),
            _cell(value, font, fontSize: 8.5),
          ],
        ),
      ],
    );
  }

  static pw.Widget _cell(
    String text,
    pw.Font font, {
    double fontSize = 10,
    pw.TextAlign align = pw.TextAlign.center,
    pw.EdgeInsets? padding,
    bool showTopBorder = false,
    bool showBottomBorder = false,
  }) {
    return pw.Container(
      padding: padding ?? const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: showTopBorder
              ? const pw.BorderSide(color: PdfColors.black, width: 0.5)
              : pw.BorderSide.none,
          bottom: showBottomBorder
              ? const pw.BorderSide(color: PdfColors.black, width: 0.5)
              : pw.BorderSide.none,
        ),
      ),
      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : (align == pw.TextAlign.right
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: fontSize),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _nestedGstHeader(String label, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _cell(
          label,
          boldFont,
          fontSize: 9,
          align: pw.TextAlign.center,
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
        ),
        pw.Container(height: 0.5, color: tableBorder),
        pw.Row(
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(right: pw.BorderSide(color: tableBorder)),
                ),
                child: _cell(
                  '%',
                  boldFont,
                  fontSize: 7.5,
                  align: pw.TextAlign.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                ),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: _cell(
                'Amount',
                boldFont,
                fontSize: 8,
                align: pw.TextAlign.center,
                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _gstDataRow(String pct, String amt, pw.Font font) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 1,
          child: pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(color: tableBorder)),
            ),
            child: _cell(
              pct,
              font,
              fontSize: 8,
              align: pw.TextAlign.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
            ),
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: _cell(
            amt,
            font,
            fontSize: 8,
            align: pw.TextAlign.right,
            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
          ),
        ),
      ],
    );
  }

  static pw.Widget _summarySummaryRow(
    String label,
    double value,
    pw.Font font, {
    bool hasBottomBorder = true,
  }) {
    return pw.Container(
      decoration: hasBottomBorder
          ? const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: tableBorder, width: 0.5),
              ),
            )
          : null,
      child: pw.Table(
        border: const pw.TableBorder(
          verticalInside: pw.BorderSide(color: tableBorder, width: 0.5),
        ),
        columnWidths: {
          0: const pw.FixedColumnWidth(160),
          1: const pw.FixedColumnWidth(77),
        },
        children: [
          pw.TableRow(
            children: [
              _cell(label, font, fontSize: 9, align: pw.TextAlign.right),
              _cell(_formatPlain(value), font, fontSize: 9, align: pw.TextAlign.right),
            ],
          ),
        ],
      ),
    );
  }

  /// Share PDF via system share sheet
  static Future<void> sharePdf(pw.Document doc, String fileName) async {
    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: '$fileName.pdf');
  }

  /// Print PDF
  static Future<void> printPdf(pw.Document doc) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}
