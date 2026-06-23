import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/factorySetup/worker.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/core/Core.dart';

class TruckDistFormScreen extends StatefulWidget {
  final String factoryId;
  const TruckDistFormScreen({super.key, required this.factoryId});

  @override
  State<TruckDistFormScreen> createState() => _TruckDistFormScreenState();
}

class _TruckDistFormScreenState extends State<TruckDistFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;

  final _totalQuantityController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  List<Worker> _truckWorkers = [];
  final Set<String> _selectedTruckWorkerIds = {};
  bool _isIn = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadWorkers();
    }
  }

  void _loadWorkers() {
    final factoryModule = context.read<Core>().factory;

    void initializeSelections() {
      _truckWorkers = factoryModule.workers
          .where((w) => w.workerType == WorkerType.truck_worker)
          .toList();
    }

    if (factoryModule.workers.isNotEmpty &&
        factoryModule.selectedFactory?.id == widget.factoryId) {
      setState(() {
        initializeSelections();
      });
    } else {
      factoryModule.fetchWorkers(widget.factoryId).then((_) {
        if (mounted) {
          setState(() {
            initializeSelections();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _totalQuantityController.dispose();
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
    if (_selectedTruckWorkerIds.isEmpty) {
      showErrorToast('factory.select_truck_worker_error'.tr());
      return;
    }

    final data = {
      'truck_worker_ids': _selectedTruckWorkerIds.toList(),
      'total_quantity': int.tryParse(_totalQuantityController.text.trim()) ?? 0,
      'date': Formatters.apiDateFormat(_selectedDate),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'is_in': _isIn,
    };

    final success = await context.read<Core>().factory.createTruckDistribution(
      widget.factoryId, data,
    );

    if (success && mounted) {
      Navigator.of(context).pop({
        'type': 'truck_dist',
        'quantity': data['total_quantity'],
        'workerIds': data['truck_worker_ids'],
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showSuccessToast('factory.truck_dist_saved'.tr());
        }
      });
    } else if (mounted) {
      showErrorToast(
        context.read<Core>().factory.transactionsError ??
            'factory.truck_dist_failed'.tr(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'factory.new_truck_dist'.tr(),
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
                  'factory.select_truck_workers'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                ..._truckWorkers.map((w) => CheckboxListTile(
                      title: Text(w.name, style: GoogleFonts.outfit()),
                      value: _selectedTruckWorkerIds.contains(w.id),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedTruckWorkerIds.add(w.id);
                          } else {
                            _selectedTruckWorkerIds.remove(w.id);
                          }
                        });
                      },
                    )),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _totalQuantityController,
                  labelText: 'factory.total_quantity'.tr(),
                  hintText: 'factory.total_quantity_hint'.tr(),
                  prefixIcon: Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.trim().isEmpty ? 'factory.quantity_required'.tr() : null,
                ),
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
                const SizedBox(height: 16),

                _buildIsInToggle(theme),
                const SizedBox(height: 32),

                AppButton(
                  text: 'factory.record_truck_dist'.tr(),
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

  Widget _buildIsInToggle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray800 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          'factory.is_in_label'.tr(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          'factory.is_in_description'.tr(),
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
        value: _isIn,
        activeColor: AppTheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onChanged: (val) => setState(() => _isIn = val),
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
