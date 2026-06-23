import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/factorySetup/worker.dart';
import 'package:vyaparsetu/types/factorySetup/transactionLog.dart';
import 'package:vyaparsetu/services/molderPdfService.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/api/api.dart';

class MolderPdfPreviewScreen extends StatefulWidget {
  final Worker worker;
  final String factoryId;

  const MolderPdfPreviewScreen({
    super.key,
    required this.worker,
    required this.factoryId,
  });

  @override
  State<MolderPdfPreviewScreen> createState() => _MolderPdfPreviewScreenState();
}

class _MolderPdfPreviewScreenState extends State<MolderPdfPreviewScreen> {
  late Future<List<TransactionLog>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _loadTransactions();
  }

  Future<List<TransactionLog>> _loadTransactions() async {
    try {
      final list = await Api.instance.factory.listTransactions(
        widget.factoryId,
        workerId: widget.worker.id,
      );
      return list.map((e) => TransactionLog.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading worker transactions: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final factoryName = context.select<Core, String>(
      (c) => c.factory.selectedFactory?.name ?? 'Factory',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'factory.pdf_report'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<TransactionLog>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingIndicator(message: 'factory.loading_report'.tr()),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: AppErrorWidget(
                errorMessage: 'factory.report_failed'.tr(),
                onRetry: () {
                  setState(() {
                    _transactionsFuture = _loadTransactions();
                  });
                },
              ),
            );
          }

          final transactions = snapshot.data ?? [];

          return PdfPreview(
            build: (format) async {
              return (await MolderPdfService.generateMolderReportPdf(
                worker: widget.worker,
                transactions: transactions,
                factoryName: factoryName,
              )).save();
            },
            allowPrinting: true,
            allowSharing: true,
            canChangePageFormat: false,
            canChangeOrientation: false,
            pdfFileName: 'Molder-Report-${widget.worker.name.replaceAll(' ', '_')}.pdf',
          );
        },
      ),
    );
  }
}
