import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/components/searchBar.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/invoices/form.dart';
import 'package:vyaparsetu/screens/invoices/detail.dart';
import 'package:vyaparsetu/core/Core.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  String _searchQuery = '';
  String _filterType = 'sale';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  String get _typeParam => _filterType;

  void _loadData() {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId != null) {
context.read<Core>().invoice.fetchInvoices(
        businessId,
        type: _typeParam,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final businessId = context.select<Core, String?>((c) => c.business.selectedBusiness?.id);
    final isLoading = context.select<Core, bool>((c) => c.invoice.isLoading);
    final invoices = context.select<Core, List<Invoice>>((c) => c.invoice.invoices);
    final error = context.select<Core, String?>((c) => c.invoice.error);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: AppSearchBar(
              hintText: 'Search by invoice number or party...',
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  _loadData();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterButton('sale'.tr(), 'sale'),
                const SizedBox(width: 8),
                _buildFilterButton('purchase'.tr(), 'purchase'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (isLoading && invoices.isNotEmpty)
            const LinearProgressIndicator(),
          Expanded(
            child: _buildInvoiceList(isDark, theme, isLoading, invoices, error, businessId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'invoices_fab',
        onPressed: () {
          Navigator.of(context).push(
            getPageRoute(_filterType == 'sale'
                ? const InvoiceFormScreen.sale()
                : const InvoiceFormScreen.purchase()),
          ).then((_) {
            if (mounted) _loadData();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInvoiceList(bool isDark, ThemeData theme, bool isLoading, List<Invoice> invoices, String? error, String? businessId) {
    if (isLoading && invoices.isEmpty) {
      return const LoadingIndicator(message: 'Loading invoices...', isShimmer: true);
    }

    if (error != null) {
      return AppErrorWidget(
        errorMessage: error,
        onRetry: _loadData,
      );
    }

    if (invoices.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No invoices found',
        description: _searchQuery.isNotEmpty
            ? 'No match for "$_searchQuery" inside this category.'
            : 'Create invoices to track sales and purchases.',
        buttonText: _searchQuery.isEmpty ? 'create_invoice'.tr() : null,
        onButtonPressed: _searchQuery.isEmpty
            ? () => Navigator.of(context).push(
                getPageRoute(_filterType == 'sale'
                    ? const InvoiceFormScreen.sale()
                    : const InvoiceFormScreen.purchase()),
              ).then((_) {
                if (mounted) _loadData();
              })
            : null,
      );
    }

    return RefreshIndicator(
      color: isDark ? Colors.white : AppTheme.primary,
      onRefresh: () async {
        if (businessId != null) {
          await context.read<Core>().invoice.fetchInvoices(businessId, type: _typeParam, search: _searchQuery.isNotEmpty ? _searchQuery : null);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          final inv = invoices[index];
          final isSale = inv.invoiceType == InvoiceType.sale;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isDark ? AppTheme.gray800 : AppTheme.slate50,
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () {
                Navigator.of(context).push(
                  getPageRoute(InvoiceDetailScreen(invoiceId: inv.id)),
                ).then((_) {
                  if (mounted) _loadData();
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(
                        isSale
                            ? Icons.receipt_long_rounded
                            : Icons.shopping_cart_outlined,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.invoiceNumber,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : AppTheme.gray900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            inv.partyName ?? 'Walk-in Customer',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            Formatters.formatDate(inv.invoiceDate),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.formatCurrency(inv.totalAmount),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? Colors.white : AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        StatusChip(
                          label: inv.paymentStatus.displayName,
                          dotColor: inv.paymentStatus == PaymentStatus.paid
                              ? AppTheme.success
                              : inv.paymentStatus == PaymentStatus.partially_paid
                                  ? AppTheme.warning
                                  : AppTheme.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterButton(String text, String type) {
    final theme = Theme.of(context);
    final isSelected = _filterType == type;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterType = type;
          });
          _loadData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: isSelected
                      ? (isDark ? Colors.white : AppTheme.primary)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppTheme.primary)
                    : (isDark ? AppTheme.gray400 : AppTheme.gray400),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
