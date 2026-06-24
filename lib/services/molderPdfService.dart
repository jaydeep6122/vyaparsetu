import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:vyaparsetu/types/factorySetup/worker.dart';
import 'package:vyaparsetu/types/factorySetup/transactionLog.dart';
import 'package:vyaparsetu/global/constants.dart';

class MolderPdfService {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  static final _rateFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );

  static String _f(double amount) => _currencyFormat.format(amount.roundToDouble());
  static String _fRate(double rate) => _rateFormat.format(rate);
  static String _d(DateTime dt) => DateFormat('dd-MM-yyyy', 'en').format(dt);

  static Future<pw.Document> generateMolderReportPdf({
    required Worker worker,
    required List<TransactionLog> transactions,
    required String factoryName,
  }) async {
    final font = await PdfGoogleFonts.hindRegular();
    final bold = await PdfGoogleFonts.hindBold();
    final gujaratiFont = await PdfGoogleFonts.notoSansGujaratiRegular();
    final gujaratiBold = await PdfGoogleFonts.notoSansGujaratiBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: bold,
        fontFallback: [gujaratiFont, gujaratiBold],
      ),
    );

    // Calculations
    final rate = worker.ratePer1000 ?? 0.0;
    final bricks = worker.totalBricks;
    final brickWages = (bricks * rate) / 1000.0;
    
    final directTxnsSum = transactions
        .where((t) => t.transactionType == TransactionType.direct)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final calculatedDirectWages = directTxnsSum > 0 
        ? directTxnsSum 
        : (worker.totalAmount - brickWages >= 0 ? worker.totalAmount - brickWages : 0.0);

    final totalWages = brickWages + calculatedDirectWages;
    final totalPayments = worker.totalMoneyGiven;
    final balanceDue = worker.balanceDue;

    // Filter transaction histories
    final wageTransactions = transactions
        .where((t) => t.transactionType != TransactionType.money_given)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first

    final paymentTransactions = transactions
        .where((t) => t.transactionType == TransactionType.money_given)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // --- SIMPLE HEADER ---
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  factoryName.toUpperCase(),
                  style: pw.TextStyle(font: bold, fontSize: 24, color: PdfColors.indigo900),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'WORKER ACCOUNT SHEET',
                  style: pw.TextStyle(font: bold, fontSize: 13, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 12),
                pw.Container(height: 3, color: PdfColors.indigo900),
                pw.SizedBox(height: 16),
              ],
            ),
          ),

          // --- WORKER NAME BOX ---
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Worker / Molder',
                      style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      worker.name.toUpperCase(),
                      style: pw.TextStyle(font: bold, fontSize: 18, color: PdfColors.indigo900),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Rate / 1000 Bricks',
                      style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${_fRate(rate)} per 1000',
                      style: pw.TextStyle(font: bold, fontSize: 14, color: PdfColors.grey900),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // --- SECTION: HOW WAGES ARE CALCULATED ---
          pw.Text(
            'STEP 1: TOTAL EARNED WAGES',
            style: pw.TextStyle(font: bold, fontSize: 12, color: PdfColors.indigo900),
          ),
          pw.SizedBox(height: 8),

          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                _buildSimpleRow(
                  label: 'Bricks Income:\n${worker.totalBricks} bricks  x  ${_fRate(rate)} / 1000',
                  value: _f(brickWages),
                  font: font,
                  bold: bold,
                  isHighlight: false,
                ),
                pw.Divider(height: 1, color: PdfColors.grey300),
                _buildSimpleRow(
                  label: 'Extra Work Income:',
                  value: _f(calculatedDirectWages),
                  font: font,
                  bold: bold,
                  isHighlight: false,
                ),
                pw.Container(
                  color: PdfColors.green50,
                  child: pw.Column(
                    children: [
                      pw.Divider(height: 1, color: PdfColors.green300, thickness: 1.5),
                      _buildSimpleRow(
                        label: 'Total Earned:',
                        value: _f(totalWages),
                        font: font,
                        bold: bold,
                        isHighlight: true,
                        textColor: PdfColors.green900,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // --- SECTION: MONEY GIVEN ---
          pw.Text(
            'STEP 2: TOTAL ADVANCES/PAYMENTS TAKEN',
            style: pw.TextStyle(font: bold, fontSize: 12, color: PdfColors.indigo900),
          ),
          pw.SizedBox(height: 8),

          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: _buildSimpleRow(
              label: 'Total Money Given to Worker:',
              value: _f(totalPayments),
              font: font,
              bold: bold,
              isHighlight: true,
              backgroundColor: PdfColors.red50,
              textColor: PdfColors.red900,
            ),
          ),
          pw.SizedBox(height: 20),

          // --- SECTION: PENDING BALANCE ---
          pw.Text(
            'STEP 3: REMAINING BALANCE',
            style: pw.TextStyle(font: bold, fontSize: 12, color: PdfColors.indigo900),
          ),
          pw.SizedBox(height: 8),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: balanceDue > 0
                  ? PdfColors.green100
                  : (balanceDue < 0 ? PdfColors.red100 : PdfColors.grey100),
              border: pw.Border.all(
                color: balanceDue > 0
                    ? PdfColors.green400
                    : (balanceDue < 0 ? PdfColors.red400 : PdfColors.grey400),
                width: 2,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      balanceDue > 0
                          ? 'FACTORY NEEDS TO PAY WORKER'
                          : (balanceDue < 0
                              ? 'PAID IN ADVANCE / EXTRA'
                              : 'NO PENDING BALANCE'),
                      style: pw.TextStyle(font: bold, fontSize: 11, color: PdfColors.grey800),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Total Earned  -  Money Given',
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Text(
                  _f(balanceDue),
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 22,
                    color: balanceDue > 0
                        ? PdfColors.green900
                        : (balanceDue < 0 ? PdfColors.red900 : PdfColors.grey900),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 40),
          _buildFooterBlock(font),

          // --- PAGE BREAK FOR WAGES HISTORY ---
          pw.NewPage(),

          // --- PAGE 2: WAGES HISTORY ---
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'WORK WAGES HISTORY',
                style: pw.TextStyle(font: bold, fontSize: 14, color: PdfColors.indigo900),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Lists all dates when bricks were made or extra wages were credited.',
                style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 12),
              
              if (wageTransactions.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(
                    'No earnings found.',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey500),
                  ),
                )
              else
                _buildEasyTable(
                  headers: ['Date', 'Work Type', 'Bricks Qty', 'Notes', 'Wages Amount'],
                  widths: [75, 110, 80, 140, 80],
                  rows: wageTransactions.map((t) {
                    var qtyStr = '-';
                    var amountVal = t.amount;

                    if (t.quantity != null) {
                      if (t.transactionType == TransactionType.truck_dist) {
                        final numWorkers = t.truckWorkerIds.isNotEmpty ? t.truckWorkerIds.length : 1;
                        final share = t.quantity! / numWorkers;
                        qtyStr = share.round().toString();
                        if (amountVal == 0.0 && worker.ratePer1000 != null) {
                          amountVal = (share / 1000.0) * worker.ratePer1000!;
                        }
                      } else {
                        qtyStr = '${t.quantity}';
                      }
                    }
                    final notesStr = t.notes ?? '-';
                    return [
                      _d(t.date),
                      t.transactionType == TransactionType.handoff
                          ? 'Handoff'
                          : t.transactionType == TransactionType.direct
                              ? 'Direct Work'
                              : t.transactionType == TransactionType.truck_dist
                                  ? 'Truck Distribution'
                                  : 'Money Given',
                      qtyStr,
                      notesStr,
                      _f(amountVal),
                    ];
                  }).toList(),
                  font: font,
                  bold: bold,
                ),
              
              pw.SizedBox(height: 30),
              _buildFooterBlock(font),
            ],
          ),

          // --- PAGE BREAK FOR PAYMENT HISTORY ---
          pw.NewPage(),

          // --- PAGE 3: PAYMENT HISTORY ---
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PAYMENTS RECEIVED HISTORY',
                style: pw.TextStyle(font: bold, fontSize: 14, color: PdfColors.indigo900),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Lists all dates when worker took advances, cash, or payouts.',
                style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 12),

              if (paymentTransactions.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(
                    'No payments found.',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey500),
                  ),
                )
              else
                _buildEasyTable(
                  headers: ['Date', 'Payment Method / Notes', 'Amount Paid'],
                  widths: [100, 285, 100],
                  rows: paymentTransactions.map((t) {
                    final notesStr = t.notes ?? 'Cash payout / Advance';
                    return [
                      _d(t.date),
                      notesStr,
                      _f(t.amount),
                    ];
                  }).toList(),
                  font: font,
                  bold: bold,
                ),

              pw.SizedBox(height: 30),
              _buildFooterBlock(font),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildSimpleRow({
    required String label,
    required String value,
    required pw.Font font,
    required pw.Font bold,
    required bool isHighlight,
    PdfColor? backgroundColor,
    PdfColor? textColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      color: backgroundColor,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: isHighlight ? bold : font,
              fontSize: isHighlight ? 12 : 11,
              color: PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: bold,
              fontSize: isHighlight ? 14 : 12,
              color: textColor ?? PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildEasyTable({
    required List<String> headers,
    required List<double> widths,
    required List<List<String>> rows,
    required pw.Font font,
    required pw.Font bold,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Table(
        border: const pw.TableBorder(
          verticalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
          horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        ),
        columnWidths: {
          for (var i = 0; i < widths.length; i++)
            i: pw.FixedColumnWidth(widths[i]),
        },
        children: [
          // Table Header
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: PdfColors.indigo50,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            children: headers
                .map((h) => pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text(
                        h,
                        style: pw.TextStyle(font: bold, fontSize: 9.5, color: PdfColors.indigo),
                        textAlign: pw.TextAlign.left,
                      ),
                    ))
                .toList(),
          ),
          // Table Rows
          ...rows.map(
            (row) => pw.TableRow(
              children: row
                  .map((cell) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: pw.Text(
                          cell,
                          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey800),
                          textAlign: pw.TextAlign.left,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooterBlock(pw.Font font) {
    return pw.Column(
      children: [
        pw.Container(height: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated via Vyapar Setu App',
              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
            ),
            pw.Text(
              'Date: ${DateFormat('dd-MM-yyyy, hh:mm a', 'en').format(DateTime.now())}',
              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }
}
