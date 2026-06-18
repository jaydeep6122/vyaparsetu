import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/expense.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/expenses/form.dart';
import 'package:vyaparsetu/core/Core.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final Expense expense;
  const ExpenseDetailScreen({super.key, required this.expense});

  void _deleteExpense(BuildContext context, Expense expense) async {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId == null) return;
    
    final expenseProvider = context.read<Core>().expense;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Delete Expense',
        content: 'Are you sure you want to delete this recorded expense?',
        confirmText: 'Delete',
        isDestructive: true,
        icon: Icons.delete_outline_rounded,
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await expenseProvider.deleteExpense(businessId, expense.id);
      if (success && context.mounted) {
        Navigator.of(context).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) showSuccessToast('Expense deleted successfully');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          expense.expenseNumber,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(getPageRoute(ExpenseFormScreen(existingExpense: expense)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _deleteExpense(context, expense),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Total Expense Amount',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.formatCurrency(expense.totalAmount),
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetaValue('Paid Amount', Formatters.formatCurrency(expense.paidAmount), Colors.green),
                        _buildMetaValue('Balance Due', Formatters.formatCurrency(expense.totalAmount - expense.paidAmount), Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Details section
            _buildDetailsCard(
              context,
              title: 'Expense Details',
              items: {
                'Expense Category': expense.expenseCategory,
                'Expense Code': expense.expenseNumber,
                'Date': Formatters.formatDate(expense.expenseDate),
                'Payment Mode': expense.paymentMode.displayName,
              },
            ),
            const SizedBox(height: 16),

            // Description card
            if (expense.description != null && expense.description!.isNotEmpty) ...[
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'description'.tr(),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        expense.description!,
                        style: GoogleFonts.outfit(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaValue(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context, {required String title, required Map<String, String> items}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            ...items.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        entry.key,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
