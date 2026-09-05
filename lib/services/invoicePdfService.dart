import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/types/item.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/crashReporting.dart';
import 'package:vyaparsetu/helpers/formatters.dart';

class InvoicePdfService {
  static const PdfColor primaryBlue = PdfColor.fromInt(0xFF0000FF);
  static const PdfColor primaryRed = PdfColor.fromInt(0xFFFF0000);
  static const PdfColor tableBorder = PdfColors.black;

  static final _plainFormat = NumberFormat.decimalPattern('en_IN')
    ..minimumFractionDigits = 2
    ..maximumFractionDigits = 2;

  static String _formatPlain(double amount) => _plainFormat.format(amount);

  /// Decodes a base64 logo/signature into an embeddable image.
  ///
  /// Returns null when there is nothing to decode or the data is unreadable.
  /// A corrupt image should never abort the whole document — but it must not
  /// vanish silently either, which is what the empty `catch {}` blocks that
  /// used to be inlined at every call site did. Failures are now reported.
  static pw.MemoryImage? _decodeEmbeddedImage(String? source, String label) {
    if (source == null || source.isEmpty) return null;
    try {
      final base64Str = source.startsWith('data:image')
          ? source.split(',')[1]
          : source;
      return pw.MemoryImage(base64Decode(base64Str));
    } catch (e, stack) {
      CrashReporting.report(e, stack, context: 'InvoicePdfService.$label');
      return null;
    }
  }

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
    final pw.MemoryImage? logoImage = _decodeEmbeddedImage(
      business.logoUrl,
      'logo',
    );

    // Load signature if available
    final pw.MemoryImage? signatureImage = _decodeEmbeddedImage(
      business.signatureUrl,
      'signature',
    );

    final hasGst = business.gstin != null && business.gstin!.isNotEmpty;
    final customerName = party?.name ?? invoice.partyName ?? 'Walk-in Customer';
    final customerAddress =
        invoice.billingAddress ??
        (party != null ? party.billingAddresses.join('\n') : '');
    final customerGstin = party?.gstin;
    final shippingSiteName = party?.name ?? customerName;
    final shippingAddress =
        invoice.shippingAddress ??
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
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: primaryBlue,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (phone != null || email != null)
                    pw.Text(
                      [
                        if (phone != null) 'Mob : $phone',
                        if (email != null) 'Email : $email',
                      ].join(', '),
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: primaryBlue,
                      ),
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
                    hasGst ? 'TAX INVOICE' : 'INVOICE',
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
                    children: [_cell('Place of Supply', boldFont, fontSize: 9)],
                  ),
                  pw.TableRow(
                    children: [_cell(placeOfSupply, font, fontSize: 9)],
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
                        DateFormat('d/M/yyyy', 'en').format(invoiceDate),
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
            _cell(
              'Description',
              boldFont,
              fontSize: 9,
              align: pw.TextAlign.center,
            ),
            _cell(
              'Challan No',
              boldFont,
              fontSize: 9,
              align: pw.TextAlign.center,
            ),
            _cell(
              'Date of Delivery',
              boldFont,
              fontSize: 9,
              align: pw.TextAlign.center,
            ),
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
            final catalogItem = item.itemId != null
                ? itemMap[item.itemId]
                : null;
            final hsn = item.hsnCode ?? catalogItem?.hsnCode ?? '';
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
                      ? DateFormat(
                          'd/M/yyyy',
                          'en',
                        ).format(invoice.deliveryDate!)
                      : '-',
                  font,
                  fontSize: 9,
                  align: pw.TextAlign.center,
                ),
                _cell(unit, font, fontSize: 9, align: pw.TextAlign.center),
                _cell(
                  _formatPlain(item.quantity),
                  font,
                  fontSize: 9,
                  align: pw.TextAlign.right,
                ),
                _cell(
                  _formatPlain(item.unitPrice),
                  font,
                  fontSize: 9,
                  align: pw.TextAlign.right,
                ),
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
                _cell(
                  _formatPlain(lineAmount),
                  font,
                  fontSize: 9,
                  align: pw.TextAlign.right,
                ),
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
            _cell(
              _formatPlain(invoice.totalAmount),
              boldFont,
              fontSize: 10,
              align: pw.TextAlign.right,
            ),
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
            _cell('Total in words : $amountInWords', boldFont, fontSize: 9),
            _summarySummaryRow(
              'Sub Total Amount',
              invoice.subTotal,
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
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: tableBorder, width: 0.5),
            ),
          ),
          children: [
            _bankRowWidget(
              'Branch & IFSC Code',
              business.ifscCode ?? '',
              font,
            ),
            _cell('', font),
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
                    'Terms and Conditions',
                    style: pw.TextStyle(font: boldFont, fontSize: 8),
                  ),
                  pw.Text(
                    _cleanNotes(invoice.notes) ??
                        '1. in case of any discrepancy in the invoice we request you to get back to us on Phone number given.',
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
    PdfColor? color,
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
        style: pw.TextStyle(font: font, fontSize: fontSize, color: color),
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
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 2,
                ),
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
              _cell(
                _formatPlain(value),
                font,
                fontSize: 9,
                align: pw.TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dispatch to correct design based on BillDesign enum
  static Future<pw.Document> generatePdfByDesign({
    required Invoice invoice,
    required Business business,
    required BillDesign design,
    Party? party,
    List<Item>? catalogItems,
  }) async {
    switch (design) {
      case BillDesign.gstClassic:
        return generateInvoicePdf(
          invoice: invoice,
          business: business,
          party: party,
          catalogItems: catalogItems,
        );
      case BillDesign.gstModern1:
        return generateGstDesign2Pdf(
          invoice: invoice,
          business: business,
          party: party,
          catalogItems: catalogItems,
        );
      case BillDesign.gstModern2:
        return generateGstDesign3Pdf(
          invoice: invoice,
          business: business,
          party: party,
          catalogItems: catalogItems,
        );
      case BillDesign.normalSimple:
        return generateNormalDesign1Pdf(
          invoice: invoice,
          business: business,
          party: party,
          catalogItems: catalogItems,
        );
      case BillDesign.normalDetailed:
        return generateNormalDesign2Pdf(
          invoice: invoice,
          business: business,
          party: party,
          catalogItems: catalogItems,
        );
    }
  }

  /// Extract BillType from invoice notes
  static BillType billTypeFromNotes(Invoice invoice) {
    final notes = invoice.notes ?? '';
    if (notes.contains('[bill_type:normal]')) return BillType.normal;
    return BillType.gst;
  }

  /// Get available designs for a given bill type
  static List<BillDesign> availableDesigns(BillType billType) {
    if (billType == BillType.gst) {
      return [
        BillDesign.gstClassic,
        BillDesign.gstModern1,
        BillDesign.gstModern2,
      ];
    }
    return [BillDesign.normalSimple, BillDesign.normalDetailed];
  }

  // ================================================================
  // GST DESIGN 2 — Modern Clean
  // ================================================================
  static Future<pw.Document> generateGstDesign2Pdf({
    required Invoice invoice,
    required Business business,
    Party? party,
    List<Item>? catalogItems,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final itemMap = <String, Item>{};
    if (catalogItems != null) {
      for (final item in catalogItems) {
        itemMap[item.id] = item;
      }
    }

    final pw.MemoryImage? logoImage = _decodeEmbeddedImage(
      business.logoUrl,
      'logo',
    );

    final pw.MemoryImage? signatureImage = _decodeEmbeddedImage(
      business.signatureUrl,
      'signature',
    );

    final customerName = party?.name ?? invoice.partyName ?? 'Walk-in Customer';
    final customerAddress =
        invoice.billingAddress ??
        (party != null ? party.billingAddresses.join('\n') : '');
    final customerGstin = party?.gstin;
    final shippingSiteName = party?.name ?? customerName;
    final shippingAddress =
        invoice.shippingAddress ??
        (party != null
            ? (party.shippingAddresses.isNotEmpty
                  ? party.shippingAddresses.join('\n')
                  : customerAddress)
            : customerAddress);
    final shippingGstin = party?.gstin;

    const PdfColor primaryColor = PdfColor.fromInt(
      0xFF37474F,
    ); // Slate Grey (calm)
    const PdfColor textDark = PdfColor.fromInt(0xFF263238);
    const PdfColor textLight = PdfColor.fromInt(0xFF78909C);
    const PdfColor bgTint = PdfColor.fromInt(0xFFF4F6F7);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // --- Header band ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 55,
                          height: 55,
                          margin: const pw.EdgeInsets.only(right: 12),
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              business.name.toUpperCase(),
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 15,
                                color: primaryColor,
                                letterSpacing: 1,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              '${business.address}, ${business.city}, ${business.state} - ${business.pincode}',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: textDark,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Row(
                              children: [
                                if (business.phone != null)
                                  pw.Text(
                                    'Ph: ${business.phone}  ',
                                    style: const pw.TextStyle(
                                      fontSize: 8,
                                      color: textLight,
                                    ),
                                  ),
                                if (business.email != null)
                                  pw.Text(
                                    'Email: ${business.email}',
                                    style: const pw.TextStyle(
                                      fontSize: 8,
                                      color: textLight,
                                    ),
                                  ),
                              ],
                            ),
                            if (business.gstin != null &&
                                business.gstin!.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'GSTIN: ${business.gstin}',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8.5,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: primaryColor, width: 1),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Text(
                    'TAX INVOICE',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 11,
                      color: primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),

            pw.Divider(color: primaryColor, thickness: 1, height: 20),

            // --- Billing and Shipping Row ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // BILL TO
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILL TO',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8,
                          color: primaryColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        customerName,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9.5,
                          color: textDark,
                        ),
                      ),
                      if (customerAddress.isNotEmpty)
                        pw.Text(
                          customerAddress,
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: textDark,
                          ),
                        ),
                      if (customerGstin != null &&
                          customerGstin.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'GSTIN: $customerGstin',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                // SHIP TO
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SHIP TO',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8,
                          color: primaryColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        shippingSiteName,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9.5,
                          color: textDark,
                        ),
                      ),
                      if (shippingAddress.isNotEmpty)
                        pw.Text(
                          shippingAddress,
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: textDark,
                          ),
                        ),
                      if (shippingGstin != null &&
                          shippingGstin.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'GSTIN: $shippingGstin',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                // INVOICE DETAILS
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICE INFO',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8,
                          color: primaryColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      _rowInfo(
                        'Invoice No:',
                        invoice.invoiceNumber,
                        font,
                        boldFont,
                        textDark,
                      ),
                      _rowInfo(
                        'Date:',
                        DateFormat(
                          'dd/MM/yyyy',
                          'en',
                        ).format(invoice.invoiceDate),
                        font,
                        boldFont,
                        textDark,
                      ),
                      if (invoice.dueDate != null)
                        _rowInfo(
                          'Due Date:',
                          DateFormat(
                            'dd/MM/yyyy',
                            'en',
                          ).format(invoice.dueDate!),
                          font,
                          boldFont,
                          PdfColor.fromInt(0xFFD32F2F),
                        ),
                      _rowInfo(
                        'Place of Supply:',
                        business.state,
                        font,
                        boldFont,
                        textDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // --- Table of Items ---
            pw.Table(
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE0E0E0),
                  width: 0.5,
                ),
                bottom: pw.BorderSide(color: primaryColor, width: 1.5),
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(24), // Sr
                1: const pw.FlexColumnWidth(), // Description
                2: const pw.FixedColumnWidth(48), // Qty
                3: const pw.FixedColumnWidth(46), // Rate
                4: const pw.FixedColumnWidth(36), // Disc%
                5: const pw.FixedColumnWidth(55), // CGST
                6: const pw.FixedColumnWidth(55), // SGST
                7: const pw.FixedColumnWidth(65), // Amount
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: primaryColor),
                  children: [
                    _cell(
                      'Sr',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.center,
                    ),
                    _cell(
                      'Item Description',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.left,
                    ),
                    _cell(
                      'Qty',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      'Rate',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      'Disc',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      'CGST',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      'SGST',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      'Amount',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
                if (invoice.items != null)
                  ...invoice.items!.asMap().entries.map((entry) {
                    final i = entry.key + 1;
                    final item = entry.value;
                    final catalogItem = item.itemId != null ? itemMap[item.itemId] : null;
                    final hsn = item.hsnCode ?? catalogItem?.hsnCode ?? '';
                    final lineAmount = item.quantity * item.unitPrice;
                    final itemCgstRate = item.taxRate / 2;
                    final itemSgstRate = item.taxRate / 2;
                    final itemCgstAmt = lineAmount * (itemCgstRate / 100);
                    final itemSgstAmt = lineAmount * (itemSgstRate / 100);
                    final isEven = entry.key % 2 == 0;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven ? PdfColors.white : bgTint,
                      ),
                      children: [
                        _cell(
                          '$i',
                          font,
                          fontSize: 8,
                          align: pw.TextAlign.center,
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                item.name,
                                style: pw.TextStyle(font: font, fontSize: 8),
                              ),
                              if (hsn.isNotEmpty) ...[
                                pw.SizedBox(height: 1),
                                pw.Text(
                                  'HSN: $hsn',
                                  style: pw.TextStyle(font: font, fontSize: 6.5, color: textLight),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _cell(
                          _formatPlain(item.quantity),
                          font,
                          fontSize: 8,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          _formatPlain(item.unitPrice),
                          font,
                          fontSize: 8,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          item.discountPercentage > 0
                              ? '${item.discountPercentage.toStringAsFixed(0)}%'
                              : '-',
                          font,
                          fontSize: 8,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          '${itemCgstRate.toStringAsFixed(0)}%\n${_formatPlain(itemCgstAmt)}',
                          font,
                          fontSize: 7.5,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          '${itemSgstRate.toStringAsFixed(0)}%\n${_formatPlain(itemSgstAmt)}',
                          font,
                          fontSize: 7.5,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          _formatPlain(lineAmount),
                          boldFont,
                          fontSize: 8,
                          align: pw.TextAlign.right,
                          color: textDark,
                        ),
                      ],
                    );
                  }),
              ],
            ),

            // --- Totals and Bottom Details Row ---
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Amount in words:',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8,
                          color: textLight,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${Formatters.numberToWords(invoice.totalAmount.round())} Only',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8.5,
                          color: textDark,
                        ),
                      ),
                      if (business.bankName != null &&
                          business.bankName!.isNotEmpty) ...[
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'BANK DETAILS',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: primaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: const pw.BoxDecoration(
                            color: bgTint,
                            border: pw.Border(
                              left: pw.BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Bank: ${business.bankName}',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: textDark,
                                ),
                              ),
                              pw.Text(
                                'A/c No: ${business.accountNumber}',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8,
                                  color: textDark,
                                ),
                              ),
                              if (business.ifscCode != null &&
                                  business.ifscCode!.isNotEmpty)
                                pw.Text(
                                  'IFSC Code: ${business.ifscCode}',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: textDark,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Container(
                  width: 185,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      _rowInfo(
                        'Sub Total:',
                        _formatPlain(invoice.subTotal),
                        font,
                        boldFont,
                        textDark,
                      ),
                      if (invoice.discountAmount > 0)
                        _rowInfo(
                          'Discount:',
                          '-${_formatPlain(invoice.discountAmount)}',
                          font,
                          boldFont,
                          PdfColor.fromInt(0xFFD32F2F),
                        ),
                      _rowInfo(
                        'CGST Total:',
                        _formatPlain(invoice.taxAmount / 2),
                        font,
                        boldFont,
                        textDark,
                      ),
                      _rowInfo(
                        'SGST Total:',
                        _formatPlain(invoice.taxAmount / 2),
                        font,
                        boldFont,
                        textDark,
                      ),
                      pw.Divider(
                        color: PdfColors.grey300,
                        thickness: 0.5,
                        height: 10,
                      ),
                      _rowInfo(
                        'Grand Total:',
                        _formatPlain(invoice.totalAmount),
                        boldFont,
                        boldFont,
                        primaryColor,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- Footer / Signatory / Terms ---
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child:
                      invoice.notes != null && invoice.notes!.trim().isNotEmpty
                      ? pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'TERMS & CONDITIONS',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 8,
                                color: primaryColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              invoice.notes!.replaceAll(
                                RegExp(r'\[bill_type:\w+\]\s*'),
                                '',
                              ),
                              style: const pw.TextStyle(
                                fontSize: 7.5,
                                color: textLight,
                              ),
                            ),
                          ],
                        )
                      : pw.SizedBox(),
                ),
                pw.SizedBox(width: 40),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'For ${business.name}',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 8.5,
                        color: textDark,
                      ),
                    ),
                    if (signatureImage != null)
                      pw.Container(
                        width: 80,
                        height: 35,
                        margin: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.SizedBox(height: 30),
                    pw.Container(
                      height: 0.5,
                      width: 110,
                      color: PdfColors.grey400,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Authorised Signatory',
                      style: const pw.TextStyle(fontSize: 8, color: textLight),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  // ================================================================
  // GST DESIGN 3 — Modern Clean variant
  // ================================================================
  static Future<pw.Document> generateGstDesign3Pdf({
    required Invoice invoice,
    required Business business,
    Party? party,
    List<Item>? catalogItems,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final itemMap = <String, Item>{};
    if (catalogItems != null) {
      for (final item in catalogItems) {
        itemMap[item.id] = item;
      }
    }

    final pw.MemoryImage? logoImage = _decodeEmbeddedImage(
      business.logoUrl,
      'logo',
    );

    final pw.MemoryImage? signatureImage = _decodeEmbeddedImage(
      business.signatureUrl,
      'signature',
    );

    final customerName = party?.name ?? invoice.partyName ?? 'Walk-in Customer';
    final customerAddress =
        invoice.billingAddress ??
        (party != null ? party.billingAddresses.join('\n') : '');
    final customerGstin = party?.gstin;
    final shippingSiteName = party?.name ?? customerName;
    final shippingAddress =
        invoice.shippingAddress ??
        (party != null
            ? (party.shippingAddresses.isNotEmpty
                  ? party.shippingAddresses.join('\n')
                  : customerAddress)
            : customerAddress);
    final shippingGstin = party?.gstin;

    const PdfColor primaryColor = PdfColor.fromInt(
      0xFF2E3B4E,
    ); // Navy Grey (calm, corporate)
    const PdfColor accentColor = PdfColor.fromInt(
      0xFF455A64,
    ); // Muted Slate Grey
    const PdfColor textDark = PdfColor.fromInt(0xFF263238);
    const PdfColor textLight = PdfColor.fromInt(0xFF78909C);
    const PdfColor bgTint = PdfColor.fromInt(0xFFF4F6F7);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // --- Header section: Logo & Business Info ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        business.name.toUpperCase(),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          color: primaryColor,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '${business.address}, ${business.city}, ${business.state} - ${business.pincode}',
                        style: const pw.TextStyle(fontSize: 8, color: textDark),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          if (business.phone != null)
                            pw.Text(
                              'Ph: ${business.phone}  ',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: textLight,
                              ),
                            ),
                          if (business.email != null)
                            pw.Text(
                              'Email: ${business.email}',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: textLight,
                              ),
                            ),
                        ],
                      ),
                      if (business.gstin != null &&
                          business.gstin!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'GSTIN: ${business.gstin}',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8.5,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (logoImage != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    margin: const pw.EdgeInsets.only(left: 12),
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
              ],
            ),

            pw.SizedBox(height: 10),

            // --- ribbon banner for TAX INVOICE ---
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 10,
              ),
              color: primaryColor,
              child: pw.Center(
                child: pw.Text(
                  'TAX INVOICE',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 11,
                    color: PdfColors.white,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),

            pw.SizedBox(height: 12),

            // --- Billing, Shipping and Invoice Metadata Row ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // BILL TO Card
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      color: bgTint,
                      border: pw.Border(
                        left: pw.BorderSide(color: primaryColor, width: 2.5),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: primaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          customerName,
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 9.5,
                            color: textDark,
                          ),
                        ),
                        if (customerAddress.isNotEmpty)
                          pw.Text(
                            customerAddress,
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: textDark,
                            ),
                          ),
                        if (customerGstin != null &&
                            customerGstin.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'GSTIN: $customerGstin',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 8,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                // SHIP TO Card
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      color: bgTint,
                      border: pw.Border(
                        left: pw.BorderSide(color: accentColor, width: 2.5),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SHIP TO',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: accentColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          shippingSiteName,
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 9.5,
                            color: textDark,
                          ),
                        ),
                        if (shippingAddress.isNotEmpty)
                          pw.Text(
                            shippingAddress,
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: textDark,
                            ),
                          ),
                        if (shippingGstin != null &&
                            shippingGstin.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'GSTIN: $shippingGstin',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 8,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                // INVOICE DETAILS Card
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      color: bgTint,
                      border: pw.Border(
                        left: pw.BorderSide(color: primaryColor, width: 2.5),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INVOICE INFO',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: primaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        _rowInfo(
                          'Invoice No:',
                          invoice.invoiceNumber,
                          font,
                          boldFont,
                          textDark,
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Date:',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: textLight,
                              ),
                            ),
                            pw.Text(
                              DateFormat(
                                'dd/MM/yyyy',
                                'en',
                              ).format(invoice.invoiceDate),
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 8,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                        if (invoice.dueDate != null) ...[
                          pw.SizedBox(height: 2),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Due Date:',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: textLight,
                                ),
                              ),
                              pw.Text(
                                DateFormat(
                                  'dd/MM/yyyy',
                                  'en',
                                ).format(invoice.dueDate!),
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8,
                                  color: PdfColor.fromInt(0xFFD32F2F),
                                ),
                              ),
                            ],
                          ),
                        ],
                        _rowInfo(
                          'Place of Supply:',
                          business.state,
                          font,
                          boldFont,
                          textDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // --- Table of Items ---
            pw.Table(
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE0E0E0),
                  width: 0.5,
                ),
                bottom: pw.BorderSide(color: primaryColor, width: 1.5),
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(24), // Sr
                1: const pw.FixedColumnWidth(40), // HSN
                2: const pw.FlexColumnWidth(), // Description
                3: const pw.FixedColumnWidth(48), // Qty
                4: const pw.FixedColumnWidth(46), // Rate
                5: const pw.FixedColumnWidth(36), // Disc
                6: const pw.FixedColumnWidth(55), // CGST
                7: const pw.FixedColumnWidth(55), // SGST
                8: const pw.FixedColumnWidth(65), // Amount
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: primaryColor),
                  children: [
                    _cell(
                      'Sr',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.center,
                    ),
                    _cell(
                      'HSN',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.center,
                    ),
                    _cell(
                      'Item Description',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.left,
                    ),
                    _cell(
                      'Qty',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      'Rate',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      'Disc',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      'CGST',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      'SGST',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      'Amount',
                      boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
                if (invoice.items != null)
                  ...invoice.items!.asMap().entries.map((entry) {
                    final i = entry.key + 1;
                    final item = entry.value;
                    final catalogItem = item.itemId != null
                        ? itemMap[item.itemId]
                        : null;
                    final hsn = item.hsnCode ?? catalogItem?.hsnCode ?? '';
                    final lineAmount = item.quantity * item.unitPrice;
                    final itemCgstRate = item.taxRate / 2;
                    final itemSgstRate = item.taxRate / 2;
                    final itemCgstAmt = lineAmount * (itemCgstRate / 100);
                    final itemSgstAmt = lineAmount * (itemSgstRate / 100);
                    final isEven = entry.key % 2 == 0;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven ? PdfColors.white : bgTint,
                      ),
                      children: [
                        _cell(
                          '$i',
                          font,
                          fontSize: 8,
                          align: pw.TextAlign.center,
                        ),
                        _cell(
                          hsn,
                          font,
                          fontSize: 8,
                          align: pw.TextAlign.center,
                        ),
                        _cell(
                          item.name,
                          font,
                          fontSize: 8,
                          align: pw.TextAlign.left,
                        ),
                        _cell(
                          _formatPlain(item.quantity),
                          font,
                          fontSize: 8,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          _formatPlain(item.unitPrice),
                          font,
                          fontSize: 8,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          item.discountPercentage > 0
                              ? '${item.discountPercentage.toStringAsFixed(0)}%'
                              : '-',
                          font,
                          fontSize: 8,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          '${itemCgstRate.toStringAsFixed(0)}%\n${_formatPlain(itemCgstAmt)}',
                          font,
                          fontSize: 7.5,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          '${itemSgstRate.toStringAsFixed(0)}%\n${_formatPlain(itemSgstAmt)}',
                          font,
                          fontSize: 7.5,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          _formatPlain(lineAmount),
                          boldFont,
                          fontSize: 8,
                          align: pw.TextAlign.right,
                          color: textDark,
                        ),
                      ],
                    );
                  }),
              ],
            ),

            // --- Totals and Bottom Details Row ---
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Amount in words:',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8,
                          color: textLight,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${Formatters.numberToWords(invoice.totalAmount.round())} Only',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8.5,
                          color: textDark,
                        ),
                      ),
                      if (business.bankName != null &&
                          business.bankName!.isNotEmpty) ...[
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'BANK DETAILS',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: primaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: const pw.BoxDecoration(
                            color: bgTint,
                            border: pw.Border(
                              left: pw.BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Bank: ${business.bankName}',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: textDark,
                                ),
                              ),
                              pw.Text(
                                'A/c No: ${business.accountNumber}',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8,
                                  color: textDark,
                                ),
                              ),
                              if (business.ifscCode != null &&
                                  business.ifscCode!.isNotEmpty)
                                pw.Text(
                                  'IFSC Code: ${business.ifscCode}',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: textDark,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Container(
                  width: 185,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      _rowInfo(
                        'Sub Total:',
                        _formatPlain(invoice.subTotal),
                        font,
                        boldFont,
                        textDark,
                      ),
                      if (invoice.discountAmount > 0)
                        _rowInfo(
                          'Discount:',
                          '-${_formatPlain(invoice.discountAmount)}',
                          font,
                          boldFont,
                          PdfColor.fromInt(0xFFD32F2F),
                        ),
                      _rowInfo(
                        'CGST Total:',
                        _formatPlain(invoice.taxAmount / 2),
                        font,
                        boldFont,
                        textDark,
                      ),
                      _rowInfo(
                        'SGST Total:',
                        _formatPlain(invoice.taxAmount / 2),
                        font,
                        boldFont,
                        textDark,
                      ),
                      pw.Divider(
                        color: PdfColors.grey300,
                        thickness: 0.5,
                        height: 10,
                      ),
                      _rowInfo(
                        'Grand Total:',
                        _formatPlain(invoice.totalAmount),
                        boldFont,
                        boldFont,
                        primaryColor,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- Footer / Signatory / Terms ---
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child:
                      invoice.notes != null && invoice.notes!.trim().isNotEmpty
                      ? pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'TERMS & CONDITIONS',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 8,
                                color: primaryColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              invoice.notes!.replaceAll(
                                RegExp(r'\[bill_type:\w+\]\s*'),
                                '',
                              ),
                              style: const pw.TextStyle(
                                fontSize: 7.5,
                                color: textLight,
                              ),
                            ),
                          ],
                        )
                      : pw.SizedBox(),
                ),
                pw.SizedBox(width: 40),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'For ${business.name}',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 8.5,
                        color: textDark,
                      ),
                    ),
                    if (signatureImage != null)
                      pw.Container(
                        width: 80,
                        height: 35,
                        margin: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.SizedBox(height: 30),
                    pw.Container(
                      height: 0.5,
                      width: 110,
                      color: PdfColors.grey400,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Authorised Signatory',
                      style: const pw.TextStyle(fontSize: 8, color: textLight),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  // ================================================================
  // NORMAL DESIGN 1 — Simple Receipt (Modern)
  // ================================================================
  static Future<pw.Document> generateNormalDesign1Pdf({
    required Invoice invoice,
    required Business business,
    Party? party,
    List<Item>? catalogItems,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final itemMap = <String, Item>{};
    if (catalogItems != null) {
      for (final item in catalogItems) {
        itemMap[item.id] = item;
      }
    }

    final pw.MemoryImage? logoImage = _decodeEmbeddedImage(
      business.logoUrl,
      'logo',
    );

    final pw.MemoryImage? signatureImage = _decodeEmbeddedImage(
      business.signatureUrl,
      'signature',
    );

    final customerName = party?.name ?? invoice.partyName ?? 'Walk-in Customer';
    final customerAddress =
        invoice.billingAddress ??
        (party != null ? party.billingAddresses.join('\n') : '');

    const PdfColor primaryColor = PdfColor.fromInt(
      0xFF37474F,
    ); // Slate Grey (sober/calm)
    const PdfColor textDark = PdfColor.fromInt(0xFF263238); // Blue Grey 900
    const PdfColor textLight = PdfColor.fromInt(0xFF546E7A); // Blue Grey 600
    const PdfColor bgTint = PdfColor.fromInt(
      0xFFF4F6F7,
    ); // Very light grey-teal tint

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // --- Header section ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Business Info
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null) ...[
                        pw.Container(
                          width: 65,
                          height: 65,
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                      ],
                      pw.Text(
                        business.name.toUpperCase(),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          color: primaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${business.address}, ${business.city}, ${business.state} - ${business.pincode}',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: textDark,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          if (business.phone != null)
                            pw.Text(
                              'Ph: ${business.phone}  ',
                              style: const pw.TextStyle(
                                fontSize: 8.5,
                                color: textLight,
                              ),
                            ),
                          if (business.email != null)
                            pw.Text(
                              'Email: ${business.email}',
                              style: const pw.TextStyle(
                                fontSize: 8.5,
                                color: textLight,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Invoice Title & Info
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 14,
                          color: PdfColors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Invoice No: ${invoice.invoiceNumber}',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 9.5,
                        color: textDark,
                      ),
                    ),
                    pw.Text(
                      'Date: ${DateFormat('d MMM, yyyy', 'en').format(invoice.invoiceDate)}',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: textLight,
                      ),
                    ),
                    if (invoice.dueDate != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Due Date: ${DateFormat('d MMM, yyyy', 'en').format(invoice.dueDate!)}',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8.5,
                          color: PdfColor.fromInt(0xFFD32F2F),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            pw.Divider(color: primaryColor, thickness: 1.5, height: 24),

            // --- Bill To & Summary Details ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILL TO',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8.5,
                          color: primaryColor,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        customerName,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 10.5,
                          color: textDark,
                        ),
                      ),
                      if (customerAddress.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          customerAddress,
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: textDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      color: bgTint,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PAYMENT DETAILS',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 7.5,
                            color: primaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        _rowInfo(
                          'Sub Total:',
                          _formatPlain(invoice.subTotal),
                          font,
                          boldFont,
                          textDark,
                        ),
                        if (invoice.discountAmount > 0)
                          _rowInfo(
                            'Discount:',
                            '-${_formatPlain(invoice.discountAmount)}',
                            font,
                            boldFont,
                            PdfColor.fromInt(0xFFD32F2F),
                          ),
                        pw.Divider(
                          color: PdfColors.grey300,
                          thickness: 0.5,
                          height: 8,
                        ),
                        _rowInfo(
                          'Total Amount:',
                          _formatPlain(invoice.totalAmount),
                          boldFont,
                          boldFont,
                          primaryColor,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // --- Table of Items ---
            pw.Table(
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE0E0E0),
                  width: 0.5,
                ),
                bottom: pw.BorderSide(color: primaryColor, width: 1),
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FlexColumnWidth(),
                2: const pw.FixedColumnWidth(50),
                3: const pw.FixedColumnWidth(60),
                4: const pw.FixedColumnWidth(50),
                5: const pw.FixedColumnWidth(70),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: primaryColor),
                  children: [
                    _cell(
                      '#',
                      boldFont,
                      fontSize: 8.5,
                      color: PdfColors.white,
                      align: pw.TextAlign.center,
                    ),
                    _cell(
                      'Item / Description',
                      boldFont,
                      fontSize: 8.5,
                      color: PdfColors.white,
                      align: pw.TextAlign.left,
                    ),
                    _cell(
                      'Qty',
                      boldFont,
                      fontSize: 8.5,
                      align: pw.TextAlign.right,
                      color: PdfColors.white,
                    ),
                    _cell(
                      'Unit Price',
                      boldFont,
                      fontSize: 8.5,
                      align: pw.TextAlign.right,
                      color: PdfColors.white,
                    ),
                    _cell(
                      'Discount',
                      boldFont,
                      fontSize: 8.5,
                      align: pw.TextAlign.right,
                      color: PdfColors.white,
                    ),
                    _cell(
                      'Net Amount',
                      boldFont,
                      fontSize: 8.5,
                      align: pw.TextAlign.right,
                      color: PdfColors.white,
                    ),
                  ],
                ),
                if (invoice.items != null)
                  ...invoice.items!.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final catalogItem = item.itemId != null ? itemMap[item.itemId] : null;
                    final hsn = item.hsnCode ?? catalogItem?.hsnCode ?? '';
                    final lineAmount = item.quantity * item.unitPrice;
                    return pw.TableRow(
                      decoration: i.isEven
                          ? const pw.BoxDecoration(color: PdfColors.white)
                          : const pw.BoxDecoration(color: bgTint),
                      children: [
                        _cell(
                          '${i + 1}',
                          font,
                          fontSize: 8.5,
                          align: pw.TextAlign.center,
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                item.name,
                                style: pw.TextStyle(font: font, fontSize: 8.5),
                              ),
                              if (hsn.isNotEmpty) ...[
                                pw.SizedBox(height: 1),
                                pw.Text(
                                  'HSN: $hsn',
                                  style: pw.TextStyle(font: font, fontSize: 7, color: textLight),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _cell(
                          _formatPlain(item.quantity),
                          font,
                          fontSize: 8.5,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          _formatPlain(item.unitPrice),
                          font,
                          fontSize: 8.5,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          item.discountPercentage > 0
                              ? '${item.discountPercentage.toStringAsFixed(0)}%'
                              : '-',
                          font,
                          fontSize: 8.5,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          _formatPlain(lineAmount),
                          boldFont,
                          fontSize: 8.5,
                          align: pw.TextAlign.right,
                          color: textDark,
                        ),
                      ],
                    );
                  }),
              ],
            ),

            // --- Totals and Bank Details Row ---
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Amount in words:',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8,
                          color: textLight,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${Formatters.numberToWords(invoice.totalAmount.round())} Only',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8.5,
                          color: textDark,
                        ),
                      ),
                      if (business.bankName != null &&
                          business.bankName!.isNotEmpty) ...[
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'BANK DETAILS',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: primaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: const pw.BoxDecoration(
                            color: bgTint,
                            border: pw.Border(
                              left: pw.BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Bank: ${business.bankName}',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: textDark,
                                ),
                              ),
                              pw.Text(
                                'A/c: ${business.accountNumber}',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8,
                                  color: textDark,
                                ),
                              ),
                              if (business.ifscCode != null &&
                                  business.ifscCode!.isNotEmpty)
                                pw.Text(
                                  'IFSC: ${business.ifscCode}',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: textDark,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Container(
                  width: 180,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        decoration: const pw.BoxDecoration(
                          color: bgTint,
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.grey300,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Sub Total:',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: textDark,
                              ),
                            ),
                            pw.Text(
                              _formatPlain(invoice.subTotal),
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (invoice.discountAmount > 0)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: const pw.BoxDecoration(
                            color: bgTint,
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                color: PdfColors.grey300,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Discount:',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: textDark,
                                ),
                              ),
                              pw.Text(
                                '-${_formatPlain(invoice.discountAmount)}',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColor.fromInt(0xFFD32F2F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        decoration: const pw.BoxDecoration(
                          color: primaryColor,
                          borderRadius: pw.BorderRadius.only(
                            bottomLeft: pw.Radius.circular(4),
                            bottomRight: pw.Radius.circular(4),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Total:',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 9.5,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              _formatPlain(invoice.totalAmount),
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 10.5,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- Footer / Signatory / Terms ---
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child:
                      invoice.notes != null && invoice.notes!.trim().isNotEmpty
                      ? pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'TERMS & CONDITIONS',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 8,
                                color: primaryColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              invoice.notes!.replaceAll(
                                RegExp(r'\[bill_type:\w+\]\s*'),
                                '',
                              ),
                              style: const pw.TextStyle(
                                fontSize: 7.5,
                                color: textLight,
                              ),
                            ),
                          ],
                        )
                      : pw.SizedBox(),
                ),
                pw.SizedBox(width: 40),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'For ${business.name}',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 8.5,
                        color: textDark,
                      ),
                    ),
                    if (signatureImage != null)
                      pw.Container(
                        width: 80,
                        height: 35,
                        margin: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.SizedBox(height: 30),
                    pw.Container(
                      height: 0.5,
                      width: 110,
                      color: PdfColors.grey400,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Authorised Signatory',
                      style: const pw.TextStyle(fontSize: 8, color: textLight),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _rowInfo(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
    PdfColor color, {
    bool isTotal = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: isTotal ? boldFont : font,
              fontSize: isTotal ? 8.5 : 8,
              color: color,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: isTotal ? 9 : 8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // NORMAL DESIGN 2 — Detailed Retail (Modern)
  // ================================================================
  static Future<pw.Document> generateNormalDesign2Pdf({
    required Invoice invoice,
    required Business business,
    Party? party,
    List<Item>? catalogItems,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final itemMap = <String, Item>{};
    if (catalogItems != null) {
      for (final item in catalogItems) {
        itemMap[item.id] = item;
      }
    }

    final pw.MemoryImage? logoImage = _decodeEmbeddedImage(
      business.logoUrl,
      'logo',
    );

    final pw.MemoryImage? signatureImage = _decodeEmbeddedImage(
      business.signatureUrl,
      'signature',
    );

    final customerName = party?.name ?? invoice.partyName ?? 'Walk-in Customer';
    final customerAddress =
        invoice.billingAddress ??
        (party != null ? party.billingAddresses.join('\n') : '');

    const PdfColor primaryColor = PdfColor.fromInt(
      0xFF2E3B4E,
    ); // Soothing Navy Grey (calm)
    const PdfColor accentColor = PdfColor.fromInt(
      0xFF455A64,
    ); // Slate Grey (calm)
    const PdfColor textDark = PdfColor.fromInt(0xFF212121);
    const PdfColor textLight = PdfColor.fromInt(0xFF757575);
    const PdfColor bgTint = PdfColor.fromInt(
      0xFFF5F7F8,
    ); // Soft muted grey background
    const PdfColor accentTint = PdfColor.fromInt(
      0xFFECEFF1,
    ); // Soft grey-blue tint for alternate rows

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // --- Premium Header with solid indigo background ---
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoImage != null)
                          pw.Container(
                            width: 60,
                            height: 60,
                            margin: const pw.EdgeInsets.only(right: 14),
                            padding: const pw.EdgeInsets.all(2),
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.all(
                                pw.Radius.circular(4),
                              ),
                            ),
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                business.name.toUpperCase(),
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 16,
                                  color: PdfColors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                '${business.address}, ${business.city}, ${business.state} - ${business.pincode}',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColor.fromInt(0xB3FFFFFF),
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Row(
                                children: [
                                  if (business.phone != null)
                                    pw.Text(
                                      'Ph: ${business.phone}  ',
                                      style: const pw.TextStyle(
                                        fontSize: 8,
                                        color: PdfColor.fromInt(0xB3FFFFFF),
                                      ),
                                    ),
                                  if (business.email != null)
                                    pw.Text(
                                      'Email: ${business.email}',
                                      style: const pw.TextStyle(
                                        fontSize: 8,
                                        color: PdfColor.fromInt(0xB3FFFFFF),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                        ),
                        child: pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12,
                            color: primaryColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Invoice #: ${invoice.invoiceNumber}',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9.5,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Date: ${DateFormat('d MMM, yyyy', 'en').format(invoice.invoiceDate)}',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColor.fromInt(0xB3FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- Billing Info Cards ---
            pw.SizedBox(height: 16),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: const pw.BoxDecoration(
                      color: bgTint,
                      border: pw.Border(
                        left: pw.BorderSide(color: accentColor, width: 3),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: accentColor,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          customerName,
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 10,
                            color: textDark,
                          ),
                        ),
                        if (customerAddress.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            customerAddress,
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: textDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: const pw.BoxDecoration(
                      color: bgTint,
                      border: pw.Border(
                        left: pw.BorderSide(color: primaryColor, width: 3),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INVOICE DETAILS',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: primaryColor,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Date:',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: textLight,
                              ),
                            ),
                            pw.Text(
                              DateFormat(
                                'dd/MM/yyyy',
                                'en',
                              ).format(invoice.invoiceDate),
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 8,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                        if (invoice.dueDate != null) ...[
                          pw.SizedBox(height: 2),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Due Date:',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: textLight,
                                ),
                              ),
                              pw.Text(
                                DateFormat(
                                  'dd/MM/yyyy',
                                  'en',
                                ).format(invoice.dueDate!),
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8,
                                  color: PdfColor.fromInt(0xFFD32F2F),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- Table of Items ---
            pw.SizedBox(height: 16),
            pw.Table(
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE0E0E0),
                  width: 0.5,
                ),
                bottom: pw.BorderSide(color: primaryColor, width: 1.5),
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FlexColumnWidth(),
                2: const pw.FixedColumnWidth(50),
                3: const pw.FixedColumnWidth(60),
                4: const pw.FixedColumnWidth(50),
                5: const pw.FixedColumnWidth(70),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: primaryColor),
                  children: [
                    _cell(
                      '#',
                      boldFont,
                      fontSize: 8.5,
                      color: PdfColors.white,
                      align: pw.TextAlign.center,
                    ),
                    _cell(
                      'Item Description',
                      boldFont,
                      fontSize: 8.5,
                      color: PdfColors.white,
                      align: pw.TextAlign.left,
                    ),
                    _cell(
                      'Qty',
                      boldFont,
                      fontSize: 8.5,
                      align: pw.TextAlign.right,
                      color: PdfColors.white,
                    ),
                    _cell(
                      'Rate',
                      boldFont,
                      fontSize: 8.5,
                      align: pw.TextAlign.right,
                      color: PdfColors.white,
                    ),
                    _cell(
                      'Disc%',
                      boldFont,
                      fontSize: 8.5,
                      align: pw.TextAlign.right,
                      color: PdfColors.white,
                    ),
                    _cell(
                      'Amount',
                      boldFont,
                      fontSize: 8.5,
                      align: pw.TextAlign.right,
                      color: PdfColors.white,
                    ),
                  ],
                ),
                if (invoice.items != null)
                  ...invoice.items!.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final catalogItem = item.itemId != null ? itemMap[item.itemId] : null;
                    final hsn = item.hsnCode ?? catalogItem?.hsnCode ?? '';
                    final lineAmount = item.quantity * item.unitPrice;
                    return pw.TableRow(
                      decoration: i.isEven
                          ? const pw.BoxDecoration(color: PdfColors.white)
                          : const pw.BoxDecoration(color: accentTint),
                      children: [
                        _cell(
                          '${i + 1}',
                          font,
                          fontSize: 8.5,
                          align: pw.TextAlign.center,
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                item.name,
                                style: pw.TextStyle(font: font, fontSize: 8.5),
                              ),
                              if (hsn.isNotEmpty) ...[
                                pw.SizedBox(height: 1),
                                pw.Text(
                                  'HSN: $hsn',
                                  style: pw.TextStyle(font: font, fontSize: 7, color: textLight),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _cell(
                          _formatPlain(item.quantity),
                          font,
                          fontSize: 8.5,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          _formatPlain(item.unitPrice),
                          font,
                          fontSize: 8.5,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          item.discountPercentage > 0
                              ? '${item.discountPercentage.toStringAsFixed(0)}%'
                              : '-',
                          font,
                          fontSize: 8.5,
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          _formatPlain(lineAmount),
                          boldFont,
                          fontSize: 8.5,
                          align: pw.TextAlign.right,
                          color: textDark,
                        ),
                      ],
                    );
                  }),
              ],
            ),

            // --- Totals and Bank Details Row ---
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Amount in words:',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8,
                          color: textLight,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${Formatters.numberToWords(invoice.totalAmount.round())} Only',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8.5,
                          color: textDark,
                        ),
                      ),
                      if (business.bankName != null &&
                          business.bankName!.isNotEmpty) ...[
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'BANK DETAILS',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8,
                            color: primaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: const pw.BoxDecoration(
                            color: accentTint,
                            border: pw.Border(
                              left: pw.BorderSide(
                                color: primaryColor,
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Bank: ${business.bankName}',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: textDark,
                                ),
                              ),
                              pw.Text(
                                'A/c No: ${business.accountNumber}',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8,
                                  color: textDark,
                                ),
                              ),
                              if (business.ifscCode != null &&
                                  business.ifscCode!.isNotEmpty)
                                pw.Text(
                                  'IFSC Code: ${business.ifscCode}',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: textDark,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Container(
                  width: 170,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    color: bgTint,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    children: [
                      _rowInfo(
                        'Sub Total:',
                        _formatPlain(invoice.subTotal),
                        font,
                        boldFont,
                        textDark,
                      ),
                      if (invoice.discountAmount > 0) ...[
                        pw.SizedBox(height: 2),
                        _rowInfo(
                          'Discount:',
                          '-${_formatPlain(invoice.discountAmount)}',
                          font,
                          boldFont,
                          PdfColor.fromInt(0xFFD32F2F),
                        ),
                      ],
                      pw.Divider(
                        color: PdfColors.grey300,
                        thickness: 0.5,
                        height: 10,
                      ),
                      _rowInfo(
                        'Grand Total:',
                        _formatPlain(invoice.totalAmount),
                        boldFont,
                        boldFont,
                        primaryColor,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- Footer / Signatory / Terms ---
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child:
                      invoice.notes != null && invoice.notes!.trim().isNotEmpty
                      ? pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: const pw.BoxDecoration(
                            color: bgTint,
                            border: pw.Border(
                              left: pw.BorderSide(color: accentColor, width: 3),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'TERMS & CONDITIONS',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8,
                                  color: accentColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                invoice.notes!.replaceAll(
                                  RegExp(r'\[bill_type:\w+\]\s*'),
                                  '',
                                ),
                                style: const pw.TextStyle(
                                  fontSize: 7.5,
                                  color: textLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : pw.SizedBox(),
                ),
                pw.SizedBox(width: 40),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'For ${business.name}',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 8.5,
                        color: textDark,
                      ),
                    ),
                    if (signatureImage != null)
                      pw.Container(
                        width: 80,
                        height: 35,
                        margin: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.SizedBox(height: 30),
                    pw.Container(
                      height: 0.5,
                      width: 110,
                      color: PdfColors.grey400,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Authorised Signatory',
                      style: const pw.TextStyle(fontSize: 8, color: textLight),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  /// Strip bill_type markers from notes
  static String? _cleanNotes(String? notes) {
    if (notes == null) return null;
    return notes.replaceAll(RegExp(r'\[bill_type:\w+\]\s*'), '').trim();
  }

  /// Share PDF via system share sheet
  static Future<void> sharePdf(pw.Document doc, String fileName) async {
    final bytes = await doc.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: fileName),
    );
  }

  /// Print PDF
  static Future<void> printPdf(pw.Document doc) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}
