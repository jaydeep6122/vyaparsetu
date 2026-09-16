import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:vyaparsetu/services/invoicePdfService.dart';

/// Shows the generated bill with share and print actions.
class PdfPreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  final String fileName;
  final String? shareMessage;

  const PdfPreviewScreen({
    super.key,
    required this.bytes,
    required this.fileName,
    this.shareMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          IconButton(
            tooltip: 'share'.tr(),
            icon: const Icon(Icons.share_rounded),
            onPressed: () => InvoicePdfService.share(
              bytes: bytes,
              fileName: fileName,
              message: shareMessage,
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => bytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowSharing: false,
        pdfFileName: '$fileName.pdf',
      ),
    );
  }
}
