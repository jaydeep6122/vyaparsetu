import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/types/party.dart';
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

  static const _filters = [
    'custom',
    'lifetime',
    'today',
    'week',
    'month',
    'year',
  ];

  String _filterLabel(String f) {
    switch (f) {
      case 'lifetime':
        return 'filter_lifetime'.tr();
      case 'today':
        return 'filter_today'.tr();
      case 'week':
        return 'filter_this_week'.tr();
      case 'month':
        return 'filter_this_month'.tr();
      case 'year':
        return 'filter_this_year'.tr();
      case 'custom':
        return 'filter_custom'.tr();
      default:
        return f;
    }
  }

  String get _englishPeriodLabel {
    if (_activeFilter == 'lifetime') return 'Lifetime';
    if (_activeFilter == 'custom' && _selectedDateRange != null) {
      final df = DateFormat('dd MMM yyyy', 'en');
      return '${df.format(_selectedDateRange!.start.toLocal())} - ${df.format(_selectedDateRange!.end.toLocal())}';
    }
    switch (_activeFilter) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'year':
        return 'This Year';
      default:
        return _activeFilter;
    }
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

  String? _startParam(DateTime? dt) {
    if (dt == null) return null;
    return DateTime(
      dt.year,
      dt.month,
      dt.day,
      0,
      0,
      0,
    ).toUtc().toIso8601String();
  }

  String? _endParam(DateTime? dt) {
    if (dt == null) return null;
    return DateTime(
      dt.year,
      dt.month,
      dt.day,
      23,
      59,
      59,
      999,
    ).toUtc().toIso8601String();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          _selectedDateRange ?? DateTimeRange(start: now, end: now),
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
      final from = _startParam(range.start);
      final to = _endParam(range.end);

      final invoices = await core.invoice.fetchInvoices(
        business.id,
        fromDate: from,
        toDate: to,
      );

      await ReportService.generateBusinessHealthReport(
        business: business,
        invoices: invoices,
        period: _englishPeriodLabel,
        isMounted: () => mounted,
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
      final from = _startParam(range.start);
      final to = _endParam(range.end);

      final invoices = await core.invoice.fetchInvoices(
        business.id,
        type: 'sale',
        fromDate: from,
        toDate: to,
      );

      await ReportService.generateSalesReport(
        business: business,
        invoices: invoices,
        period: _englishPeriodLabel,
        isMounted: () => mounted,
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
      final from = _startParam(range.start);
      final to = _endParam(range.end);

      final invoices = await core.invoice.fetchInvoices(
        business.id,
        type: 'purchase',
        fromDate: from,
        toDate: to,
      );

      await ReportService.generatePurchaseReport(
        business: business,
        invoices: invoices,
        period: _englishPeriodLabel,
        isMounted: () => mounted,
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
      final from = _startParam(range.start);
      final to = _endParam(range.end);

      final invoices = await core.invoice.fetchInvoices(
        business.id,
        type: 'sale',
        partyId: party.id,
        fromDate: from,
        toDate: to,
      );

      await ReportService.generateCustomerReport(
        business: business,
        partyName: party.name,
        invoices: invoices,
        period: _englishPeriodLabel,
        isMounted: () => mounted,
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
      final from = _startParam(range.start);
      final to = _endParam(range.end);

      final invoices = await core.invoice.fetchInvoices(
        business.id,
        type: 'purchase',
        partyId: party.id,
        fromDate: from,
        toDate: to,
      );

      await ReportService.generateSupplierReport(
        business: business,
        partyName: party.name,
        invoices: invoices,
        period: _englishPeriodLabel,
        isMounted: () => mounted,
      );
    } catch (_) {}

    if (mounted) setState(() => _generatingReport = null);
  }

  void _showPartyPicker({required bool isCustomer}) {
    final core = context.read<Core>();
    final business = core.business.selectedBusiness;
    if (business == null) return;

    final parties = core.party.parties.where((p) {
      if (isCustomer)
        return p.partyType == PartyType.customer ||
            p.partyType == PartyType.both;
      return p.partyType == PartyType.supplier || p.partyType == PartyType.both;
    }).toList();

    if (parties.isEmpty) {
      showSuccessToast(isCustomer ? 'no_customers'.tr() : 'no_suppliers'.tr());
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
                : parties
                      .where(
                        (p) =>
                            p.name.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ||
                            (p.phone ?? '').contains(searchQuery),
                      )
                      .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.backgroundDark : AppTheme.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        TextField(
                          controller: searchController,
                          onChanged: (v) =>
                              setSheetState(() => searchQuery = v),
                          decoration: InputDecoration(
                            hintText: isCustomer
                                ? 'search_customers_hint'.tr()
                                : 'search_suppliers_hint'.tr(),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppTheme.cardDark
                                : AppTheme.gray100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                              isCustomer
                                  ? 'no_customers_found'.tr()
                                  : 'no_suppliers_found'.tr(),
                              style: GoogleFonts.outfit(
                                color: isDark
                                    ? AppTheme.gray400
                                    : AppTheme.gray500,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final party = filtered[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.secondary
                                      .withValues(alpha: 0.12),
                                  child: Text(
                                    party.name.isNotEmpty
                                        ? party.name[0].toUpperCase()
                                        : '?',
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
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.gray900,
                                  ),
                                ),
                                subtitle: party.phone != null
                                    ? Text(
                                        party.phone!,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppTheme.gray400
                                              : AppTheme.gray500,
                                        ),
                                      )
                                    : null,
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: isDark
                                      ? AppTheme.gray500
                                      : AppTheme.gray400,
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
        title: Text(
          'report_center'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
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
                        onTap: f == 'custom'
                            ? _pickDateRange
                            : () => setState(() => _activeFilter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: selected
                                ? (isDark ? AppTheme.primary : AppTheme.primary)
                                : (isDark ? AppTheme.cardDark : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : (isDark
                                        ? AppTheme.gray700
                                        : AppTheme.gray200),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _activeFilter == 'custom' &&
                                    f == 'custom' &&
                                    _selectedDateRange != null
                                ? '${Formatters.formatDate(_selectedDateRange!.start)} - ${Formatters.formatDate(_selectedDateRange!.end)}'
                                : _filterLabel(f),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                        ? AppTheme.gray300
                                        : AppTheme.gray700),
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
                  'general_business'.tr(),
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
                  title: 'overall_business_health'.tr(),
                  subtitle: 'health_subtitle'.tr(),
                  loading: _generatingReport == 'health' ? 'generating'.tr() : null,
                  onTap: _generatingReport != null ? null : _generateBusinessHealth,
                ),
                const SizedBox(height: 10),
                 _reportTile(
                  isDark: isDark,
                  icon: Icons.receipt_long_rounded,
                  title: 'full_sales_log'.tr(),
                  subtitle: 'sales_log_subtitle'.tr(),
                  loading: _generatingReport == 'sales' ? 'generating'.tr() : null,
                  onTap: _generatingReport != null ? null : _generateSalesReport,
                ),
                const SizedBox(height: 10),
                 _reportTile(
                  isDark: isDark,
                  icon: Icons.shopping_cart_outlined,
                  title: 'full_purchase_log'.tr(),
                  subtitle: 'purchase_log_subtitle'.tr(),
                  loading: _generatingReport == 'purchase' ? 'generating'.tr() : null,
                  onTap: _generatingReport != null ? null : _generatePurchaseReport,
                ),
                const SizedBox(height: 28),

                // ── Party Specific Section ──
                Text(
                  'party_specific'.tr(),
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
                  title: 'customer_report'.tr(),
                  subtitle: 'customer_report_subtitle'.tr(),
                  loading: _generatingReport == 'customer' ? 'generating'.tr() : null,
                  onTap: _generatingReport != null ? null : () => _showPartyPicker(isCustomer: true),
                ),
                const SizedBox(height: 10),
                 _reportTile(
                  isDark: isDark,
                  icon: Icons.business_outlined,
                  title: 'supplier_report'.tr(),
                  subtitle: 'supplier_report_subtitle'.tr(),
                  loading: _generatingReport == 'supplier' ? 'generating'.tr() : null,
                  onTap: _generatingReport != null ? null : () => _showPartyPicker(isCustomer: false),
                ),
                const SizedBox(height: 40),
              ],
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
    final themeColor = isDark ? Colors.white70 : AppTheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: themeColor, size: 22),
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
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppTheme.primaryDark : AppTheme.secondary,
                          ),
                        )
                      else
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.gray400
                                : AppTheme.slate500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (loading != null)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? AppTheme.primaryDark : AppTheme.secondary,
                    ),
                  )
                else
                  Icon(
                    Icons.download_rounded,
                    color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
