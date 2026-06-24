import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/expenses/form.dart';
import 'package:vyaparsetu/screens/expenses/detail.dart';
import 'package:vyaparsetu/types/expense.dart';
import 'package:vyaparsetu/core/Core.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String? _selectedCategory;
  DateTime? _fromDate;
  DateTime? _toDate;

  static const List<String> _categories = [
    'All',
    'Rent',
    'Salaries',
    'Electricity',
    'Internet',
    'Office Supplies',
    'Travel',
    'Marketing',
    'Other',
  ];

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
      context.read<Core>().expense.fetchExpenses(businessId);
    }
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
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _fromDate = null;
      _toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final businessId = context.select<Core, String?>(
      (c) => c.business.selectedBusiness?.id,
    );
    final isLoading = context.select<Core, bool>((c) => c.expense.isLoading);
    final expenses = context.select<Core, List<Expense>>(
      (c) => c.expense.expenses,
    );
    final error = context.select<Core, String?>((c) => c.expense.error);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'expenses'.tr(),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : AppTheme.gray100,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                            hint: Text(
                              'all_categories'.tr(),
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                          isDense: true,
                          items:
                              _categories.map((cat) {
                                final isAll = cat == 'All';
                                return DropdownMenuItem<String>(
                                  value: isAll ? null : cat,
                                  child: Text(
                                    cat,
                                    style: GoogleFonts.outfit(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_selectedCategory != null ||
                        _fromDate != null ||
                        _toDate != null)
                      GestureDetector(
                        onTap: _clearFilters,
                        child: Text(
                          'clear'.tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color:
                                isDark
                                    ? Colors.white
                                    : AppTheme.primary,
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
                        'from'.tr(),
                        _fromDate,
                        () => _pickDate(true),
                        isFrom: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateButton(
                        'to'.tr(),
                        _toDate,
                        () => _pickDate(false),
                        isFrom: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildExpenseList(
              isDark,
              theme,
              isLoading,
              expenses,
              error,
              businessId,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expenses_fab',
        onPressed: () {
          Navigator.of(
            context,
          ).push(getPageRoute(const ExpenseFormScreen())).then((_) {
            if (mounted) _loadData();
          });
        },
        child: const Icon(Icons.add_shopping_cart_rounded),
      ),
    );
  }

  List<Expense> _filterExpenses(List<Expense> list) {
    return list.where((ex) {
      final matchesCategory = _selectedCategory == null ||
          _selectedCategory == 'All' ||
          ex.expenseCategory == _selectedCategory;

      if (!matchesCategory) return false;

      if (_fromDate != null && ex.expenseDate.isBefore(_fromDate!)) return false;
      if (_toDate != null && ex.expenseDate.isAfter(_toDate!.add(const Duration(days: 1)))) return false;

      return true;
    }).toList();
  }

  Widget _buildExpenseList(
    bool isDark,
    ThemeData theme,
    bool isLoading,
    List<Expense> expenses,
    String? error,
    String? businessId,
  ) {
    if (isLoading && expenses.isEmpty) {
      return LoadingIndicator(message: 'loading_expenses'.tr(), isShimmer: true);
    }

    if (error != null) {
      return AppErrorWidget(errorMessage: error, onRetry: _loadData);
    }

    final filtered = _filterExpenses(expenses);

    return RefreshIndicator(
      color: isDark ? Colors.white : AppTheme.primary,
      onRefresh: () async {
        if (businessId != null) {
          await context.read<Core>().expense.fetchExpenses(
            businessId,
            forceRefresh: true,
          );
        }
      },
      child: filtered.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: EmptyState(
                        icon: Icons.money_off_rounded,
                        title: 'no_expenses'.tr(),
                        description:
                            'no_expenses_subtitle'.tr(),
                        buttonText: 'add_expense'.tr(),
                        onButtonPressed:
                            () => Navigator.of(
                              context,
                            ).push(getPageRoute(const ExpenseFormScreen())).then((_) {
                              if (mounted) _loadData();
                            }),
                      ),
                    ),
                  ),
                );
              },
            )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final ex = filtered[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () {
                Navigator.of(context)
                    .push(getPageRoute(ExpenseDetailScreen(expense: ex)))
                    .then((_) {
                      if (mounted) _loadData();
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
                          ex.expenseCategory,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(ex.totalAmount),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.formatDate(ex.expenseDate),
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
                            color:
                                isDark ? AppTheme.cardDark : AppTheme.gray100,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            ex.paymentMode.displayName,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap, {required bool isFrom}) {
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
                    color: isDark ? Colors.white.withValues(alpha: 0.5) : AppTheme.primary,
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
                    if (isFrom)
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
