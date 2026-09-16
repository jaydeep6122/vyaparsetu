import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/types/member.dart';

/// How bills, payments and expenses are numbered (admins).
class DocumentSeriesScreen extends StatefulWidget {
  const DocumentSeriesScreen({super.key});

  @override
  State<DocumentSeriesScreen> createState() => _DocumentSeriesScreenState();
}

class _DocumentSeriesScreenState extends State<DocumentSeriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() =>
      context.read<Core>().business.fetchDocumentSeries(refresh: true);

  void _edit(DocumentSeries series) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SeriesSheet(series: series),
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();

    return Scaffold(
      appBar: AppBar(title: Text('invoice_numbering'.tr())),
      body: LoadStateBody<List<DocumentSeries>>(
        state: core.business.documentSeries,
        onRetry: _refresh,
        builder: (context, seriesList) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            children: [
              Text('document_series_hint'.tr(), style: context.text.bodyMedium),
              const SizedBox(height: AppTheme.spaceLg),
              if (seriesList.isEmpty)
                Text('document_series_empty'.tr(), style: context.text.bodyMedium),
              for (final series in seriesList)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                  child: AppCard(
                    onTap: () => _edit(series),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('doc_type_${series.docType}'.tr(), style: context.text.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                'financial_year_label'.tr(namedArgs: {'fy': series.financialYear}),
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('next_number'.tr(), style: context.text.bodySmall),
                            Text(series.preview, style: context.text.titleSmall),
                          ],
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        Icon(Icons.edit_outlined, size: 18, color: context.colors.muted),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeriesSheet extends StatefulWidget {
  final DocumentSeries series;

  const _SeriesSheet({required this.series});

  @override
  State<_SeriesSheet> createState() => _SeriesSheetState();
}

class _SeriesSheetState extends State<_SeriesSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _prefix = TextEditingController(text: widget.series.prefix);
  late final _next = TextEditingController(text: '${widget.series.nextNumber}');
  late final _padding = TextEditingController(text: '${widget.series.padding}');

  @override
  void dispose() {
    _prefix.dispose();
    _next.dispose();
    _padding.dispose();
    super.dispose();
  }

  String get _preview {
    final next = int.tryParse(_next.text) ?? 1;
    final padding = (int.tryParse(_padding.text) ?? 1).clamp(1, 10);
    return '${_prefix.text.trim()}${next.toString().padLeft(padding, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final core = context.read<Core>();
    final ok = await core.business.updateDocumentSeries(
      widget.series.id,
      prefix: _prefix.text.trim(),
      nextNumber: int.parse(_next.text),
      padding: int.parse(_padding.text),
    );
    if (!mounted) return;
    if (!ok) {
      showErrorToast(core.business.error ?? 'error_generic'.tr());
      return;
    }
    showSuccessToast('numbering_saved'.tr());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<Core, bool>((c) => c.business.isSaving);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spaceLg,
        0,
        AppTheme.spaceLg,
        MediaQuery.viewInsetsOf(context).bottom + AppTheme.spaceLg,
      ),
      child: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('doc_type_${widget.series.docType}'.tr(), style: context.text.titleLarge),
            const SizedBox(height: AppTheme.spaceLg),
            AppTextField(
              controller: _prefix,
              labelText: 'number_prefix'.tr(),
              helperText: 'number_prefix_hint'.tr(),
              maxLength: 20,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _next,
                    labelText: 'next_number'.tr(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                        ? 'validation_min_one'.tr()
                        : null,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: AppTextField(
                    controller: _padding,
                    labelText: 'number_digits'.tr(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    validator: (v) {
                      final n = int.tryParse(v ?? '') ?? 0;
                      return n < 1 || n > 10 ? 'validation_digits_range'.tr() : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Text(
              'next_document_preview'.tr(namedArgs: {'number': _preview}),
              style: context.text.titleSmall?.copyWith(color: context.colors.primary),
            ),
            const SizedBox(height: AppTheme.space2xl),
            AppButton(text: 'save'.tr(), isLoading: isSaving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
