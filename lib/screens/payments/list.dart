import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/payment.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/screens/payments/form.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/helpers/navigation.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  String? _filterType;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId != null) {
      context.read<Core>().payment.fetchPayments(
        businessId,
        paymentType: _filterType,
        fromDate: _fromDate?.toIso8601String(),
        toDate: _toDate?.toIso8601String(),
      );
    }
  }

  void _showNewPaymentSheet(String? businessId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      showDragHandle: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'New Payment',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.success.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: AppTheme.success,
                  ),
                ),
                title: Text(
                  'Payment In',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Record money received from a customer',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.slate500,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context)
                      .push(getPageRoute(const PaymentFormScreen.paymentIn()))
                      .then((_) {
                        if (businessId != null && mounted) _loadData();
                      });
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.error.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: AppTheme.error,
                  ),
                ),
                title: Text(
                  'Payment Out',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Record payment made to a supplier',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.slate500,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context)
                      .push(getPageRoute(const PaymentFormScreen.paymentOut()))
                      .then((_) {
                        if (businessId != null && mounted) _loadData();
                      });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _loadData();
    }
  }

  void _clearFilters() {
    setState(() {
      _filterType = null;
      _fromDate = null;
      _toDate = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final businessId = context.select<Core, String?>(
      (c) => c.business.selectedBusiness?.id,
    );
    final isLoading = context.select<Core, bool>((c) => c.payment.isLoading);
    final payments = context.select<Core, List<Payment>>(
      (c) => c.payment.payments,
    );
    final error = context.select<Core, String?>((c) => c.payment.error);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'payments'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildFilterChip('All', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Payment In', 'payment_in'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Payment Out', 'payment_out'),
                    const Spacer(),
                    if (_filterType != null ||
                        _fromDate != null ||
                        _toDate != null)
                      GestureDetector(
                        onTap: _clearFilters,
                        child: Text(
                          'Clear',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isDark ? Colors.white : AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(
                        'From',
                        _fromDate,
                        () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateButton(
                        'To',
                        _toDate,
                        () => _pickDate(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildPaymentList(
              isDark,
              theme,
              isLoading,
              payments,
              error,
              businessId,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'payments_fab',
        onPressed: () => _showNewPaymentSheet(businessId),
        child: const Icon(Icons.add_card_rounded),
      ),
    );
  }

  Widget _buildPaymentList(
    bool isDark,
    ThemeData theme,
    bool isLoading,
    List<Payment> payments,
    String? error,
    String? businessId,
  ) {
    if (isLoading && payments.isEmpty) {
      return const LoadingIndicator(
        message: 'Loading payments...',
        isShimmer: true,
      );
    }

    if (error != null) {
      return AppErrorWidget(errorMessage: error, onRetry: _loadData);
    }

    if (payments.isEmpty) {
      return EmptyState(
        icon: Icons.payment_outlined,
        title: 'No payments found',
        description: 'Record credit/debit payments collected from parties.',
        buttonText: 'add_payment'.tr(),
        onButtonPressed: () => _showNewPaymentSheet(businessId),
      );
    }

    return RefreshIndicator(
      color: isDark ? Colors.white : AppTheme.primary,
      onRefresh: () async {
        if (businessId != null) {
          context.read<Core>().payment.fetchPayments(
            businessId,
            paymentType: _filterType,
            fromDate: _fromDate?.toIso8601String(),
            toDate: _toDate?.toIso8601String(),
          );
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final p = payments[index];
          final isIn = p.paymentType == PaymentType.payment_in;
          final amountColor = isIn ? AppTheme.success : AppTheme.error;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () {
                Navigator.of(context)
                    .push(
                      getPageRoute(PaymentFormScreen.edit(existingPayment: p)),
                    )
                    .then((_) {
                      if (businessId != null && mounted) {
                        context.read<Core>().payment.fetchPayments(
                          businessId,
                          paymentType: _filterType,
                          fromDate: _fromDate?.toIso8601String(),
                          toDate: _toDate?.toIso8601String(),
                        );
                      }
                    });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.partyName ?? 'Contact',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(p.amount),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.formatDate(p.paymentDate),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: amountColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isIn
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                size: 12,
                                color: amountColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                p.paymentMode.displayName,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: amountColor,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildFilterChip(String label, String? value) {
    final theme = Theme.of(context);
    final isSelected = _filterType == value;
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = value;
        });
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.primary)
                  : (isDark ? AppTheme.cardDark : AppTheme.gray100),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color:
                isSelected
                    ? Colors.white
                    : theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.gray100,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border:
              date != null
                  ? Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppTheme.primary,
                  )
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color:
                  date != null
                      ? (isDark ? Colors.white : AppTheme.primary)
                      : AppTheme.gray400,
            ),
            const SizedBox(width: 6),
            Text(
              date != null ? DateFormat('dd/MM/yyyy').format(date) : label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: date != null ? FontWeight.bold : FontWeight.w500,
                color:
                    date != null
                        ? (isDark ? Colors.white : AppTheme.primary)
                        : null,
              ),
            ),
            if (date != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (label == 'From')
                      _fromDate = null;
                    else
                      _toDate = null;
                  });
                  _loadData();
                },
                child: Icon(Icons.close, size: 14, color: AppTheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
