import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/factorySetup/worker.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/core/Core.dart';

class DirectFormScreen extends StatefulWidget {
  final String factoryId;
  final Worker? selectedWorker;
  const DirectFormScreen({
    super.key,
    required this.factoryId,
    this.selectedWorker,
  });

  @override
  State<DirectFormScreen> createState() => _DirectFormScreenState();
}

class _DirectFormScreenState extends State<DirectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;

  String? _workerId;
  final _quantityController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _entryMode = 'quantity'; // 'quantity' or 'amount'

  List<Worker> _workers = [];
  Worker? _selectedWorker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _workerId = widget.selectedWorker?.id;
      _loadWorkers();
    }
  }

  void _loadWorkers() {
    final factoryModule = context.read<Core>().factory;

    void initializeSelections() {
      if (widget.selectedWorker != null) {
        _selectedWorker = _workers
            .where((w) => w.id == widget.selectedWorker!.id)
            .firstOrNull;
      }
    }

    if (factoryModule.workers.isNotEmpty &&
        factoryModule.selectedFactory?.id == widget.factoryId) {
      setState(() {
        _workers = factoryModule.workers;
        initializeSelections();
      });
    } else {
      factoryModule.fetchWorkers(widget.factoryId).then((_) {
        if (mounted) {
          setState(() {
            _workers = factoryModule.workers;
            initializeSelections();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_workerId == null) {
      showErrorToast('factory.select_worker_error'.tr());
      return;
    }

    final Map<String, dynamic> data = {
      'worker_id': _workerId,
      'date': Formatters.apiDateFormat(_selectedDate),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    if (_entryMode == 'quantity') {
      data['quantity'] = int.tryParse(_quantityController.text.trim()) ?? 0;
    } else {
      data['amount'] = double.tryParse(_amountController.text.trim()) ?? 0.0;
    }

    final success = await context.read<Core>().factory.createDirect(
      widget.factoryId,
      data,
    );

    if (success && mounted) {
      Navigator.of(context).pop({
        'type': 'direct',
        'quantity': data['quantity'],
        'amount': data['amount'],
        'workerId': data['worker_id'],
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSuccessToast('factory.direct_saved'.tr());
      });
    } else if (mounted) {
      showErrorToast(
        context.read<Core>().factory.transactionsError ??
            'factory.direct_failed'.tr(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'factory.new_direct'.tr(),
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
                Text(
                  'factory.select_worker'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Worker>(
                  initialValue: _selectedWorker,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                  hint: Text('factory.select_worker'.tr()),
                  items: _workers.map((w) {
                    return DropdownMenuItem<Worker>(
                      value: w,
                      child: Text(w.name, style: GoogleFonts.outfit()),
                    );
                  }).toList(),
                  onChanged: (w) {
                    setState(() {
                      _selectedWorker = w;
                      _workerId = w?.id;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _entryMode = 'quantity'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _entryMode == 'quantity'
                                  ? (isDark ? AppTheme.primaryDark : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _entryMode == 'quantity' ? AppTheme.shadowSm : null,
                            ),
                            child: Text(
                              'factory.quantity_based'.tr(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _entryMode == 'quantity'
                                    ? (isDark ? Colors.white : AppTheme.primary)
                                    : (isDark ? AppTheme.gray400 : AppTheme.gray600),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _entryMode = 'amount'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _entryMode == 'amount'
                                  ? (isDark ? AppTheme.primaryDark : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _entryMode == 'amount' ? AppTheme.shadowSm : null,
                            ),
                            child: Text(
                              'factory.amount_based'.tr(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _entryMode == 'amount'
                                    ? (isDark ? Colors.white : AppTheme.primary)
                                    : (isDark ? AppTheme.gray400 : AppTheme.gray600),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_entryMode == 'quantity') ...[
                  AppTextField(
                    controller: _quantityController,
                    labelText: 'factory.quantity'.tr(),
                    hintText: 'factory.brick_quantity_hint'.tr(),
                    prefixIcon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'factory.quantity_required'.tr()
                        : null,
                  ),
                ] else ...[
                  AppTextField(
                    controller: _amountController,
                    labelText: 'factory.amount'.tr(),
                    hintText: 'factory.direct_wage_hint'.tr(),
                    prefixIcon: Icons.currency_rupee_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'factory.amount_required'.tr()
                        : null,
                  ),
                ],
                const SizedBox(height: 16),

                _buildDatePicker(),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _notesController,
                  labelText: 'factory.notes'.tr(),
                  hintText: 'factory.optional_notes'.tr(),
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 32),

                AppButton(
                  text: 'factory.record_direct'.tr(),
                  isLoading: context.select<Core, bool>(
                    (c) => c.factory.isLoadingTransactions,
                  ),
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: AppTextField(
          controller: TextEditingController(
            text: Formatters.apiDateFormat(_selectedDate),
          ),
          labelText: 'factory.date'.tr(),
          prefixIcon: Icons.calendar_today_rounded,
        ),
      ),
    );
  }
}
