import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/services/reportService.dart';
import 'package:vyaparsetu/core/Core.dart';

class ReportCenterScreen extends StatefulWidget {
  const ReportCenterScreen({super.key});

  @override
  State<ReportCenterScreen> createState() => _ReportCenterScreenState();
}

class _ReportCenterScreenState extends State<ReportCenterScreen> {
  String _activeFilter = 'lifetime';
  DateTimeRange? _selectedDateRange;
  String? _generatingReport;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessId = context.read<Core>().business.selectedBusiness?.id;
      if (businessId != null) {
        context.read<Core>().party.fetchParties(businessId);
      }
    });
  }

  static const _filters = ['lifetime', 'today', 'week', 'month', 'year', 'custom'];

  String _filterLabel(String f) {
    switch (f) {
      case 'lifetime': return 'Lifetime';
      case 'today': return 'Today';
      case 'week': return 'This Week';
      case 'month': return 'This Month';
      case 'year': return 'This Year';
      case 'custom': return 'Custom';
      default: return f;
    }
  }

  String get _periodLabel {
    if (_activeFilter == 'lifetime') return 'Lifetime';
    if (_activeFilter == 'custom' && _selectedDateRange != null) {
      return '${Formatters.formatDate(_selectedDateRange!.start)} - ${Formatters.formatDate(_selectedDateRange!.end)}';
    }
    return _filterLabel(_activeFilter);
  }

  DateTimeRange _computeRange() {
    final now = DateTime.now();
    switch (_activeFilter) {
      case 'today':
        return DateTimeRange(start: now, end: now);
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: weekStart, end: now);
      case 'month':
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case 'year':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case 'custom':
        return _selectedDateRange ?? DateTimeRange(start: now, end: now);
      default:
        return DateTimeRange(start: DateTime(2020), end: now);
    }
  }

  String? _dateParam(DateTime? dt) {
    if (dt == null) return null;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedDateRange ?? DateTimeRange(start: now, end: now),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _activeFilter = 'custom';
      });
    }
  }

  Future<void> _generateBusinessHealth() async {
    final core = context.read<Core>();
    final business = core.business.selectedBusiness;
    if (business == null) return;

    setState(() => _generatingReport = 'health');

    try {
      final range = _computeRange();
      final from = _dateParam(range.start);
      final to = _dateParam(range.end);

      await core.invoice.fetchInvoices(business.id, fromDate: from, toDate: to);
      final invoices = List<Invoice>.from(core.invoice.invoices);

      await ReportService.generateBusinessHealthReport(
        business: business,
        invoices: invoices,
        period: _periodLabel,
      );
    } catch (_) {}

    if (mounted) setState(() => _generatingReport = null);
  }

  Future<void> _generateSalesReport() async {
    final core = context.read<Core>();
    final business = core.business.selectedBusiness;
    if (business == null) return;

    setState(() => _generatingReport = 'sales');

    try {
      final range = _computeRange();
      final from = _dateParam(range.start);
      final to = _dateParam(range.end);

      await core.invoice.fetchInvoices(business.id, type: 'sale', fromDate: from, toDate: to);
      final invoices = List<Invoice>.from(core.invoice.invoices);

      await ReportService.generateSalesReport(
        business: business,
        invoices: invoices,
        period: _periodLabel,
      );
    } catch (_) {}

    if (mounted) setState(() => _generatingReport = null);
  }

  Future<void> _generatePurchaseReport() async {
    final core = context.read<Core>();
    final business = core.business.selectedBusiness;
    if (business == null) return;

    setState(() => _generatingReport = 'purchase');

    try {
      final range = _computeRange();
      final from = _dateParam(range.start);
      final to = _dateParam(range.end);

      await core.invoice.fetchInvoices(business.id, type: 'purchase', fromDate: from, toDate: to);
      final invoices = List<Invoice>.from(core.invoice.invoices);

      await ReportService.generatePurchaseReport(
        business: business,
        invoices: invoices,
        period: _periodLabel,
      );
    } catch (_) {}

    if (mounted) setState(() => _generatingReport = null);
  }

  Future<void> _generateCustomerReport(Party party) async {
    final core = context.read<Core>();
    final business = core.business.selectedBusiness;
    if (business == null) return;

    setState(() => _generatingReport = 'customer');

    try {
      final range = _computeRange();
      final from = _dateParam(range.start);
      final to = _dateParam(range.end);

      await core.invoice.fetchInvoices(
        business.id,
        type: 'sale',
        partyId: party.id,
        fromDate: from,
        toDate: to,
      );
      final invoices = List<Invoice>.from(core.invoice.invoices);

      await ReportService.generateCustomerReport(
        business: business,
        partyName: party.name,
        invoices: invoices,
        period: _periodLabel,
      );
    } catch (_) {}

    if (mounted) setState(() => _generatingReport = null);
  }

  Future<void> _generateSupplierReport(Party party) async {
    final core = context.read<Core>();
    final business = core.business.selectedBusiness;
    if (business == null) return;

    setState(() => _generatingReport = 'supplier');

    try {
      final range = _computeRange();
      final from = _dateParam(range.start);
      final to = _dateParam(range.end);

      await core.invoice.fetchInvoices(
        business.id,
        type: 'purchase',
        partyId: party.id,
        fromDate: from,
        toDate: to,
      );
      final invoices = List<Invoice>.from(core.invoice.invoices);

      await ReportService.generateSupplierReport(
        business: business,
        partyName: party.name,
        invoices: invoices,
        period: _periodLabel,
      );
    } catch (_) {}

    if (mounted) setState(() => _generatingReport = null);
  }

  void _showPartyPicker({required bool isCustomer}) {
    final core = context.read<Core>();
    final business = core.business.selectedBusiness;
    if (business == null) return;

    final parties = core.party.parties.where((p) {
      if (isCustomer) return p.partyType == PartyType.customer || p.partyType == PartyType.both;
      return p.partyType == PartyType.supplier || p.partyType == PartyType.both;
    }).toList();

    if (parties.isEmpty) {
      showSuccessToast(isCustomer ? 'No customers found' : 'No suppliers found');
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchController = TextEditingController();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = searchQuery.isEmpty
                ? parties
                : parties.where((p) =>
                    p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                    (p.phone ?? '').contains(searchQuery)).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.backgroundDark : AppTheme.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      children: [
                        Container(
                          width: 40, height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        TextField(
                          controller: searchController,
                          onChanged: (v) => setSheetState(() => searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search ${isCustomer ? 'customers' : 'suppliers'}...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            filled: true,
                            fillColor: isDark ? AppTheme.cardDark : AppTheme.gray100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No ${isCustomer ? 'customers' : 'suppliers'} found',
                              style: GoogleFonts.outfit(
                                color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final party = filtered[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.secondary.withValues(alpha: 0.12),
                                  child: Text(
                                    party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  party.name,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : AppTheme.gray900,
                                  ),
                                ),
                                subtitle: party.phone != null
                                    ? Text(
                                        party.phone!,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                                        ),
                                      )
                                    : null,
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (isCustomer) {
                                    _generateCustomerReport(party);
                                  } else {
                                    _generateSupplierReport(party);
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Report Center', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date Range Filter Chips ──
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final f = _filters[index];
                      final selected = _activeFilter == f;
                      return GestureDetector(
                        onTap: f == 'custom' ? _pickDateRange : () => setState(() => _activeFilter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: selected
                                ? (isDark ? AppTheme.primary : AppTheme.primary)
                                : (isDark ? AppTheme.cardDark : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? Colors.transparent : (isDark ? AppTheme.gray700 : AppTheme.gray200),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _activeFilter == 'custom' && f == 'custom' && _selectedDateRange != null
                                ? '${Formatters.formatDate(_selectedDateRange!.start)} - ${Formatters.formatDate(_selectedDateRange!.end)}'
                                : _filterLabel(f),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : (isDark ? AppTheme.gray300 : AppTheme.gray700),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── General Business Section ──
                Text(
                  'GENERAL BUSINESS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                  ),
                ),
                const SizedBox(height: 12),
                _reportTile(
                  isDark: isDark,
                  icon: Icons.analytics_rounded,
                  title: 'Overall Business Health',
                  subtitle: 'Revenue, expenditure & net profit summary',
                  loading: _generatingReport == 'health' ? 'Generating...' : null,
                  onTap: _generateBusinessHealth,
                ),
                const SizedBox(height: 10),
                _reportTile(
                  isDark: isDark,
                  icon: Icons.receipt_long_rounded,
                  title: 'Full Sales Log',
                  subtitle: 'Complete ledger of all sales transactions',
                  loading: _generatingReport == 'sales' ? 'Generating...' : null,
                  onTap: _generateSalesReport,
                ),
                const SizedBox(height: 10),
                _reportTile(
                  isDark: isDark,
                  icon: Icons.shopping_cart_outlined,
                  title: 'Full Purchase Log',
                  subtitle: 'Complete log of all purchases from vendors',
                  loading: _generatingReport == 'purchase' ? 'Generating...' : null,
                  onTap: _generatePurchaseReport,
                ),
                const SizedBox(height: 28),

                // ── Party Specific Section ──
                Text(
                  'PARTY SPECIFIC',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                  ),
                ),
                const SizedBox(height: 12),
                _reportTile(
                  isDark: isDark,
                  icon: Icons.people_outline_rounded,
                  title: 'Customer Report',
                  subtitle: 'Tap to select a customer & generate report',
                  loading: _generatingReport == 'customer' ? 'Generating...' : null,
                  onTap: () => _showPartyPicker(isCustomer: true),
                ),
                const SizedBox(height: 10),
                _reportTile(
                  isDark: isDark,
                  icon: Icons.business_outlined,
                  title: 'Supplier Report',
                  subtitle: 'Tap to select a supplier & generate report',
                  loading: _generatingReport == 'supplier' ? 'Generating...' : null,
                  onTap: () => _showPartyPicker(isCustomer: false),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_generatingReport != null)
            Positioned.fill(
              child: Container(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black26,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray800 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.gray600 : AppTheme.gray200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black54 : Colors.black12,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: isDark ? AppTheme.accentDark : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Generating PDF...',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.gray900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reportTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    String? loading,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading != null ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.secondary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (loading != null)
                        Text(
                          loading,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.secondary,
                          ),
                        )
                      else
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (loading != null)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Icon(Icons.download_rounded, color: isDark ? AppTheme.gray400 : AppTheme.gray500, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
