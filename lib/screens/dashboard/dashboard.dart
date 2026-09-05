import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/business/form.dart';
import 'package:vyaparsetu/screens/expenses/form.dart';
import 'package:vyaparsetu/screens/home/home.dart';
import 'package:vyaparsetu/screens/invoices/form.dart';
import 'package:vyaparsetu/screens/items/list.dart';
import 'package:vyaparsetu/screens/payments/form.dart';
import 'package:vyaparsetu/screens/reports/reportCenter.dart';
import 'package:vyaparsetu/types/dashboardSummary.dart';

/// Money-first dashboard.
///
/// The order answers "where do I stand?" before "what do I do?":
///
///   1. Money in hand   - cash / bank / UPI, from `summary.cashBook`
///   2. To receive / to pay
///   3. Sales vs purchases, netting to profit or loss
///   4. Actions
///   5. Low stock
///
/// `cashBook` and the `lowStockItems` list were both being fetched and parsed
/// and then never rendered; this screen surfaces them.
///
/// The summary endpoint has no date range, so everything here is all-time.
/// That is stated on screen rather than left ambiguous.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId != null) {
      context.read<Core>().dashboard.fetchSummary(businessId);
      context.read<Core>().invoice.fetchInvoices(businessId);
    }
  }

  Future<void> _refresh() async {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId == null) return;
    await Future.wait([
      context.read<Core>().dashboard.fetchSummary(businessId, forceRefresh: true),
      context.read<Core>().invoice.fetchInvoices(businessId, forceRefresh: true),
    ]);
  }

  /// Opens a sibling tab in the shell rather than pushing a second copy of a
  /// screen that is already in the IndexedStack.
  void _openTab(int index) {
    HapticFeedback.selectionClick();
    context.findAncestorStateOfType<HomeScreenState>()?.setTab(index);
  }

  void _push(Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(getPageRoute(screen)).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);

    final isLoading = context.select<Core, bool>(
      (c) => c.dashboard.isLoadingSummary,
    );
    final summary = context.select<Core, DashboardSummary?>(
      (c) => c.dashboard.summary,
    );
    final error = context.select<Core, String?>(
      (c) => c.dashboard.summaryError,
    );

    if (isLoading && summary == null) {
      return Scaffold(
        backgroundColor: palette.canvas,
        body: LoadingIndicator(message: 'loading_dashboard'.tr()),
      );
    }

    if (error != null && summary == null) {
      return Scaffold(
        backgroundColor: palette.canvas,
        body: AppErrorWidget(errorMessage: error, onRetry: _loadData),
      );
    }

    if (summary == null) {
      return Scaffold(
        backgroundColor: palette.canvas,
        body: Center(child: Text('no_dashboard_summary'.tr())),
      );
    }

    return Scaffold(
      backgroundColor: palette.canvas,
      body: RefreshIndicator(
        color: palette.accent,
        backgroundColor: palette.card,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
          children: [
            _PeriodNote(palette: palette),
            const SizedBox(height: 12),
            _MoneyInHandCard(palette: palette, cashBook: summary.cashBook),
            const SizedBox(height: 12),
            _OwedRow(
              palette: palette,
              receivable: summary.totalReceivables.total,
              payable: summary.totalPayables.total,
              onReceivableTap: () => _openTab(1),
              onPayableTap: () => _openTab(1),
            ),
            const SizedBox(height: 12),
            _TradeCard(palette: palette, summary: summary),
            const SizedBox(height: 24),
            _SectionLabel(text: 'quick_actions'.tr(), palette: palette),
            const SizedBox(height: 12),
            _ActionGrid(
              palette: palette,
              onNewSale: _onNewSale,
              onNewPurchase: () => _push(const InvoiceFormScreen.purchase()),
              onPaymentIn: () => _push(const PaymentFormScreen.paymentIn()),
              onPaymentOut: () => _push(const PaymentFormScreen.paymentOut()),
              onExpense: () => _push(const ExpenseFormScreen()),
              onItems: () => _push(const ItemListScreen()),
              onReports: () => _push(const ReportCenterScreen()),
            ),
            if (summary.lowStockItemsCount > 0) ...[
              const SizedBox(height: 24),
              _SectionLabel(
                text: 'low_stock_alert'.tr(),
                palette: palette,
                actionLabel: 'see_all'.tr(),
                onActionTap: () => _push(const ItemListScreen()),
              ),
              const SizedBox(height: 12),
              _LowStockCard(
                palette: palette,
                count: summary.lowStockItemsCount,
                items: summary.lowStockItems,
                onTap: () => _push(const ItemListScreen()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onNewSale() {
    HapticFeedback.lightImpact();
    final palette = _Palette.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _BillTypeSheet(
        palette: palette,
        onSelect: (billType) {
          Navigator.of(sheetContext).pop();
          _startSale(billType);
        },
      ),
    );
  }

  void _startSale(BillType billType) {
    // A GST invoice needs the seller's own GSTIN on the bill, so block early
    // with a route to fix it rather than producing an invalid document.
    if (billType == BillType.gst) {
      final business = context.read<Core>().business.selectedBusiness;
      final hasGstin = business?.gstin != null && business!.gstin!.isNotEmpty;
      if (!hasGstin) {
        _promptForGstin();
        return;
      }
    }
    _push(InvoiceFormScreen.sale(billType: billType));
  }

  void _promptForGstin() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('gst_number_required'.tr()),
        content: Text('gst_number_required_msg'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _push(const BusinessFormScreen());
            },
            child: Text('go_to_settings'.tr()),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Palette
// ---------------------------------------------------------------------------

/// Resolves the theme once per build instead of threading `isDark` through
/// every widget and repeating a ternary at each colour.
class _Palette {
  final bool isDark;
  final Color canvas;
  final Color card;
  final Color cardBorder;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color accent;
  final Color positive;
  final Color negative;
  final Color caution;

  const _Palette({
    required this.isDark,
    required this.canvas,
    required this.card,
    required this.cardBorder,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.accent,
    required this.positive,
    required this.negative,
    required this.caution,
  });

  factory _Palette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const _Palette(
            isDark: true,
            canvas: AppTheme.backgroundDark,
            card: AppTheme.cardDark,
            cardBorder: Color(0x1FFFFFFF),
            ink: Colors.white,
            inkMuted: AppTheme.gray400,
            inkFaint: AppTheme.gray500,
            accent: AppTheme.primaryDark,
            positive: AppTheme.success,
            negative: AppTheme.error,
            caution: AppTheme.warning,
          )
        : const _Palette(
            isDark: false,
            canvas: AppTheme.background,
            card: Colors.white,
            cardBorder: AppTheme.gray200,
            ink: AppTheme.gray900,
            inkMuted: AppTheme.gray600,
            inkFaint: AppTheme.gray500,
            accent: AppTheme.primary,
            positive: Color(0xFF059669),
            negative: Color(0xFFDC2626),
            caution: Color(0xFFD97706),
          );
  }
}

// ---------------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------------

/// Flat surface. The reset drops the previous glass/blur and heavy shadows in
/// favour of a hairline border, so dense numbers stay legible.
class _Surface extends StatelessWidget {
  final _Palette palette;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? background;
  final Color? border;

  const _Surface({
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.background,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border ?? palette.cardBorder, width: 1),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: content,
      ),
    );
  }
}

/// Small uppercase label above a figure.
class _Eyebrow extends StatelessWidget {
  final String text;
  final Color color;

  const _Eyebrow(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }
}

/// Currency figure. Tabular figures keep columns of numbers aligned.
class _Amount extends StatelessWidget {
  final double value;
  final double size;
  final Color color;
  final FontWeight weight;

  const _Amount(
    this.value, {
    required this.size,
    required this.color,
    this.weight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      Formatters.formatCurrency(value),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: -0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final _Palette palette;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SectionLabel({
    required this.text,
    required this.palette,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: palette.ink,
            letterSpacing: -0.2,
          ),
        ),
        if (actionLabel != null)
          Semantics(
            button: true,
            child: InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.accent,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// States that the figures are all-time, because the summary endpoint takes no
/// date range. Better to say so than to let the reader assume "this month".
class _PeriodNote extends StatelessWidget {
  final _Palette palette;

  const _PeriodNote({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.history_rounded, size: 13, color: palette.inkFaint),
        const SizedBox(width: 6),
        Text(
          'this_is_all_time'.tr(),
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.inkFaint,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Money in hand
// ---------------------------------------------------------------------------

class _MoneyInHandCard extends StatelessWidget {
  final _Palette palette;
  final CashBook cashBook;

  const _MoneyInHandCard({required this.palette, required this.cashBook});

  @override
  Widget build(BuildContext context) {
    final parts = <_MoneyPart>[
      _MoneyPart('cash'.tr(), cashBook.cash, palette.positive),
      _MoneyPart('bank'.tr(), cashBook.bank, palette.accent),
      _MoneyPart('upi'.tr(), cashBook.upi, AppTheme.secondary),
    ];
    final splitTotal = parts.fold<double>(0, (sum, p) => sum + p.value);

    return _Surface(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('money_in_hand'.tr(), color: palette.inkMuted),
          const SizedBox(height: 8),
          _Amount(cashBook.totalMoney, size: 34, color: palette.ink),
          const SizedBox(height: 16),
          if (splitTotal <= 0)
            Text(
              'no_money_recorded'.tr(),
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: palette.inkFaint,
                fontWeight: FontWeight.w500,
              ),
            )
          else ...[
            _ProportionBar(parts: parts, total: splitTotal, palette: palette),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < parts.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _MoneyLeg(part: parts[i], palette: palette)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MoneyPart {
  final String label;
  final double value;
  final Color color;
  const _MoneyPart(this.label, this.value, this.color);
}

/// Single stacked bar showing how the balance is distributed.
class _ProportionBar extends StatelessWidget {
  final List<_MoneyPart> parts;
  final double total;
  final _Palette palette;

  const _ProportionBar({
    required this.parts,
    required this.total,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final visible = parts.where((p) => p.value > 0).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                // Guarded above: this widget is only built when total > 0.
                flex: (visible[i].value / total * 1000).round().clamp(1, 1000),
                child: ColoredBox(color: visible[i].color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoneyLeg extends StatelessWidget {
  final _MoneyPart part;
  final _Palette palette;

  const _MoneyLeg({required this.part, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: part.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                part.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.inkMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        _Amount(part.value, size: 14, color: palette.ink, weight: FontWeight.w600),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2. To receive / to pay
// ---------------------------------------------------------------------------

class _OwedRow extends StatelessWidget {
  final _Palette palette;
  final double receivable;
  final double payable;
  final VoidCallback onReceivableTap;
  final VoidCallback onPayableTap;

  const _OwedRow({
    required this.palette,
    required this.receivable,
    required this.payable,
    required this.onReceivableTap,
    required this.onPayableTap,
  });

  @override
  Widget build(BuildContext context) {
    // Deliberately no IntrinsicHeight: it miscalculated against the tabular
    // figures and clipped the amount by a few pixels on device. Both cards
    // have the same single-line structure, so they match height on their own.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _OwedCard(
            palette: palette,
            label: 'to_receive'.tr(),
            amount: receivable,
            tone: palette.positive,
            icon: Icons.south_west_rounded,
            onTap: onReceivableTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OwedCard(
            palette: palette,
            label: 'to_pay'.tr(),
            amount: payable,
            tone: palette.negative,
            icon: Icons.north_east_rounded,
            onTap: onPayableTap,
          ),
        ),
      ],
    );
  }
}

class _OwedCard extends StatelessWidget {
  final _Palette palette;
  final String label;
  final double amount;
  final Color tone;
  final IconData icon;
  final VoidCallback onTap;

  const _OwedCard({
    required this.palette,
    required this.label,
    required this.amount,
    required this.tone,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label ${Formatters.formatCurrency(amount)}',
      child: _Surface(
        palette: palette,
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 12, color: tone),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: palette.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Amount(amount, size: 20, color: palette.ink),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Sales vs purchases
// ---------------------------------------------------------------------------

class _TradeCard extends StatelessWidget {
  final _Palette palette;
  final DashboardSummary summary;

  const _TradeCard({required this.palette, required this.summary});

  @override
  Widget build(BuildContext context) {
    final sales = summary.totalSales.total;
    final purchases = summary.totalPurchases.total;
    final net = sales - purchases;
    final isProfit = net >= 0;
    final tone = isProfit ? palette.positive : palette.negative;

    return _Surface(
      palette: palette,
      child: Column(
        children: [
          _TradeLine(
            palette: palette,
            label: 'sales'.tr(),
            amount: sales,
            secondary: '${'outstanding'.tr()} '
                '${Formatters.formatCurrency(summary.totalReceivables.total)}',
          ),
          const SizedBox(height: 14),
          _TradeLine(
            palette: palette,
            label: 'purchases'.tr(),
            amount: purchases,
            secondary: '${'outstanding'.tr()} '
                '${Formatters.formatCurrency(summary.totalPayables.total)}',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: palette.cardBorder),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Eyebrow('net_balance'.tr(), color: palette.inkMuted),
                    const SizedBox(height: 6),
                    _Amount(net, size: 24, color: tone, weight: FontWeight.w800),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: tone,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      (isProfit ? 'profit' : 'loss').tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tone,
                      ),
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
}

class _TradeLine extends StatelessWidget {
  final _Palette palette;
  final String label;
  final double amount;
  final String secondary;

  const _TradeLine({
    required this.palette,
    required this.label,
    required this.amount,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                secondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: palette.inkFaint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _Amount(amount, size: 17, color: palette.ink),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Actions
// ---------------------------------------------------------------------------

class _ActionGrid extends StatelessWidget {
  final _Palette palette;
  final VoidCallback onNewSale;
  final VoidCallback onNewPurchase;
  final VoidCallback onPaymentIn;
  final VoidCallback onPaymentOut;
  final VoidCallback onExpense;
  final VoidCallback onItems;
  final VoidCallback onReports;

  const _ActionGrid({
    required this.palette,
    required this.onNewSale,
    required this.onNewPurchase,
    required this.onPaymentIn,
    required this.onPaymentOut,
    required this.onExpense,
    required this.onItems,
    required this.onReports,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The four billing actions carry the most traffic, so they get the
        // full-width row and the tinted treatment.
        Row(
          children: [
            Expanded(
              child: _PrimaryAction(
                palette: palette,
                icon: Icons.add_shopping_cart_rounded,
                label: 'new_sale'.tr(),
                tone: palette.positive,
                onTap: onNewSale,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PrimaryAction(
                palette: palette,
                icon: Icons.shopping_bag_outlined,
                label: 'new_purchase'.tr(),
                tone: palette.accent,
                onTap: onNewPurchase,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PrimaryAction(
                palette: palette,
                icon: Icons.south_west_rounded,
                label: 'payment_in'.tr(),
                tone: palette.positive,
                onTap: onPaymentIn,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PrimaryAction(
                palette: palette,
                icon: Icons.north_east_rounded,
                label: 'payment_out'.tr(),
                tone: palette.negative,
                onTap: onPaymentOut,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MinorAction(
                palette: palette,
                icon: Icons.receipt_long_outlined,
                label: 'add_expense'.tr(),
                onTap: onExpense,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MinorAction(
                palette: palette,
                icon: Icons.inventory_2_outlined,
                label: 'items_appbar'.tr(),
                onTap: onItems,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MinorAction(
                palette: palette,
                icon: Icons.assessment_outlined,
                label: 'reports'.tr(),
                onTap: onReports,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final _Palette palette;
  final IconData icon;
  final String label;
  final Color tone;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.palette,
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: _Surface(
        palette: palette,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: tone),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinorAction extends StatelessWidget {
  final _Palette palette;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MinorAction({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: _Surface(
        palette: palette,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, size: 20, color: palette.inkMuted),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Low stock
// ---------------------------------------------------------------------------

/// Renders the actual low-stock items. Previously only the count was shown,
/// even though the API returns the list.
class _LowStockCard extends StatelessWidget {
  final _Palette palette;
  final int count;
  final List<LowStockItem> items;
  final VoidCallback onTap;

  static const int _maxShown = 3;

  const _LowStockCard({
    required this.palette,
    required this.count,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shown = items.take(_maxShown).toList();
    final remaining = count - shown.length;

    return _Surface(
      palette: palette,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      background: palette.caution.withValues(alpha: palette.isDark ? 0.10 : 0.06),
      border: palette.caution.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: palette.caution,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'low_stock_count'.tr(namedArgs: {'count': '$count'}),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.caution,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: palette.caution,
              ),
            ],
          ),
          // The list can be empty even when the count is not: older cached
          // summaries stored the count alone.
          if (shown.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _LowStockLine(palette: palette, item: shown[i]),
            ],
            if (remaining > 0) ...[
              const SizedBox(height: 10),
              Text(
                '+$remaining',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.inkFaint,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _LowStockLine extends StatelessWidget {
  final _Palette palette;
  final LowStockItem item;

  const _LowStockLine({required this.palette, required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: palette.ink,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${Formatters.formatDouble(item.currentStock)} ${item.measuringUnit}',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: palette.caution,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bill type sheet
// ---------------------------------------------------------------------------

class _BillTypeSheet extends StatelessWidget {
  final _Palette palette;
  final ValueChanged<BillType> onSelect;

  const _BillTypeSheet({required this.palette, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: palette.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'choose_invoice_type'.tr(),
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 16),
            _BillTypeOption(
              palette: palette,
              icon: Icons.receipt_long_rounded,
              title: 'gst_invoice'.tr(),
              subtitle: 'gst_invoice_subtitle'.tr(),
              onTap: () => onSelect(BillType.gst),
            ),
            const SizedBox(height: 10),
            _BillTypeOption(
              palette: palette,
              icon: Icons.receipt_rounded,
              title: 'normal_invoice'.tr(),
              subtitle: 'normal_invoice_subtitle'.tr(),
              onTap: () => onSelect(BillType.normal),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillTypeOption extends StatelessWidget {
  final _Palette palette;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BillTypeOption({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: _Surface(
        palette: palette,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        background: palette.isDark ? AppTheme.gray800 : AppTheme.gray50,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: palette.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: palette.inkFaint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: palette.inkFaint,
            ),
          ],
        ),
      ),
    );
  }
}
