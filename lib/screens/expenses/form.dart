import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/expense.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/core/Core.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? existingExpense;
  const ExpenseFormScreen({super.key, this.existingExpense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Expense? _existingExpense;
  bool _isEdit = false;
  bool _isInitialized = false;

  final _customCategoryController = TextEditingController();
  final _expNumberController = TextEditingController();
  final _totalController = TextEditingController();
  final _paidController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _expenseDate = DateTime.now();
  String _category = 'Rent';
  PaymentMode _paymentMode = PaymentMode.cash;

  final List<String> _categories = ['Rent', 'Salaries', 'Electricity', 'Internet', 'Office Supplies', 'Travel', 'Marketing', 'Custom...'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      final args = widget.existingExpense;
      if (args is Expense) {
        _existingExpense = args;
        _isEdit = true;
        _initForm();
      } else {
        // Auto generate expense number
        final selectedBusiness = context.read<Core>().business.selectedBusiness;

        if (selectedBusiness != null) {
          _expNumberController.text = 'EXP-${DateTime.now().millisecondsSinceEpoch ~/ 10000}';
        }
      }
    }
  }

  void _initForm() {
    if (_existingExpense == null) return;
    final exp = _existingExpense!;
    if (_categories.contains(exp.expenseCategory)) {
      _category = exp.expenseCategory;
    } else {
      _category = 'Custom...';
      _customCategoryController.text = exp.expenseCategory;
    }
    _expNumberController.text = exp.expenseNumber;
    _totalController.text = exp.totalAmount.toString();
    _paidController.text = exp.paidAmount.toString();
    _descController.text = exp.description ?? '';
    _expenseDate = exp.expenseDate;
    _paymentMode = exp.paymentMode;
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    _expNumberController.dispose();
    _totalController.dispose();
    _paidController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _expenseDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId == null) return;

    final expenseProvider = context.read<Core>().expense;

    final finalCategory = _category == 'Custom...' 
        ? _customCategoryController.text.trim() 
        : _category;

    if (finalCategory.isEmpty) {
      showErrorToast('Please specify an expense category');
      return;
    }

    final total = double.parse(_totalController.text.trim());
    final paid = double.tryParse(_paidController.text.trim()) ?? 0.0;
    
    if (paid > total) {
      showErrorToast('Paid amount cannot exceed total expense amount');
      return;
    }

    final data = {
      'expense_category': finalCategory,
      'expense_number': _expNumberController.text.trim(),
      'expense_date': _expenseDate.toUtc().toIso8601String(),
      'total_amount': total,
      'paid_amount': paid,
      'payment_mode': _paymentMode.value, // CHECK constraint: cash, bank, upi, credit
      'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
    };

    bool success;
    if (_isEdit) {
      success = await expenseProvider.updateExpense(businessId, _existingExpense!.id, data);
    } else {
      success = await expenseProvider.createExpense(businessId, data);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      context.read<Core>().business.fetchBusinesses();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSuccessToast(_isEdit ? 'Expense updated successfully' : 'Expense recorded successfully');
      });
    } else if (mounted) {
      showErrorToast(expenseProvider.error ?? 'Failed to save expense');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'edit_expense'.tr() : 'add_expense'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Selection
                Text(
                  'expense_category'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _category = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Custom Category Field (conditionally visible)
                if (_category == 'Custom...') ...[
                  AppTextField(
                    controller: _customCategoryController,
                    labelText: 'Specify Category',
                    hintText: 'e.g. Office Rent, Taxes, Refreshments',
                    validator: (val) => Validators.validateRequired(val, 'Category'),
                  ),
                  const SizedBox(height: 16),
                ],

                // Expense Number
                AppTextField(
                  controller: _expNumberController,
                  labelText: 'expense_number'.tr(),
                  hintText: 'EXP-101',
                  validator: (val) => Validators.validateRequired(val, 'Expense number'),
                ),
                const SizedBox(height: 16),

                // Pricing
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _totalController,
                        labelText: 'Total Amount (₹)',
                        hintText: 'Total expense cost',
                        keyboardType: TextInputType.number,
                        validator: (val) => Validators.validatePositiveAmount(val, 'Total Amount'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        controller: _paidController,
                        labelText: 'paid_amount'.tr(),
                        hintText: 'Enter amount paid',
                        keyboardType: TextInputType.number,
                        readOnly: _paymentMode == PaymentMode.credit,
                        validator: (val) => Validators.validateAmount(val, 'Paid Amount'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Expense Date
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'expense_date'.tr(),
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      Formatters.formatDate(_expenseDate),
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Mode (Cash, Bank, UPI, Credit)
                Text(
                  'payment_mode'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<PaymentMode>(
                  value: _paymentMode,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  // Note: expenses table CHECK constraint: cash, bank, upi, credit
                  items: [PaymentMode.cash, PaymentMode.bank, PaymentMode.upi, PaymentMode.credit].map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode.displayName, style: GoogleFonts.outfit()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _paymentMode = val;
                        if (val == PaymentMode.credit) {
                          _paidController.text = '0';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Description
                AppTextField(
                  controller: _descController,
                  labelText: 'description'.tr(),
                  hintText: 'Add remarks...',
                  maxLines: 3,
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: 32),

                // Save button
                AppButton(
                  text: 'save'.tr(),
                  isLoading: context.select<Core, bool>((c) => c.expense.isLoading),
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
