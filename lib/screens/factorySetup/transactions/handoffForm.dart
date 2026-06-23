import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/factorySetup/worker.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/core/Core.dart';

class HandoffFormScreen extends StatefulWidget {
  final String factoryId;
  final Worker? selectedWorker;
  const HandoffFormScreen({
    super.key,
    required this.factoryId,
    this.selectedWorker,
  });

  @override
  State<HandoffFormScreen> createState() => _HandoffFormScreenState();
}

class _HandoffFormScreenState extends State<HandoffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;

  late String? _kilnWorkerId;
  late String? _producerMolderId;
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  List<Worker> _workers = [];
  Worker? _kilnWorker;
  Worker? _producerMolder;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _kilnWorkerId = null;
      _producerMolderId = null;
      if (widget.selectedWorker != null) {
        if (widget.selectedWorker!.workerType == WorkerType.kiln_worker) {
          _kilnWorkerId = widget.selectedWorker!.id;
        } else {
          _producerMolderId = widget.selectedWorker!.id;
        }
      }
      _loadWorkers();
    }
  }

  void _loadWorkers() {
    final factoryModule = context.read<Core>().factory;

    void initializeSelections() {
      if (widget.selectedWorker != null) {
        _kilnWorker = _workers.where(
          (w) => w.id == _kilnWorkerId,
        ).firstOrNull;
        _producerMolder = _workers.where(
          (w) => w.id == _producerMolderId,
        ).firstOrNull;
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
    if (_kilnWorkerId == null && _producerMolderId == null) {
      showErrorToast('factory.select_worker_handoff_error'.tr());
      return;
    }

    final data = {
      'kiln_worker_id': _kilnWorkerId,
      'producer_molder_id': _producerMolderId,
      'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
      'date': Formatters.apiDateFormat(_selectedDate),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    final success = await context.read<Core>().factory.createHandoff(
      widget.factoryId, data,
    );

    if (success && mounted) {
      Navigator.of(context).pop({
        'type': 'handoff',
        'quantity': data['quantity'],
        'kilnWorkerId': data['kiln_worker_id'],
        'producerMolderId': data['producer_molder_id'],
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSuccessToast('factory.handoff_saved'.tr());
      });
    } else if (mounted) {
      showErrorToast(
        context.read<Core>().factory.transactionsError ?? 'factory.handoff_failed'.tr(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'factory.new_handoff'.tr(),
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
                  'factory.select_kiln_worker'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                _buildWorkerDropdown(
                  value: _kilnWorker,
                  items: _workers.where((w) => w.workerType == WorkerType.kiln_worker).toList(),
                  hint: 'factory.select_kiln_worker'.tr(),
                  onChanged: (w) => setState(() {
                    _kilnWorker = w;
                    _kilnWorkerId = w?.id;
                  }),
                ),
                const SizedBox(height: 20),

                Text(
                  'factory.select_producer_molder'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                _buildWorkerDropdown(
                  value: _producerMolder,
                  items: _workers.where((w) => w.workerType == WorkerType.producer_molder).toList(),
                  hint: 'factory.select_producer_molder'.tr(),
                  onChanged: (w) => setState(() {
                    _producerMolder = w;
                    _producerMolderId = w?.id;
                  }),
                ),
                const SizedBox(height: 20),

                AppTextField(
                  controller: _quantityController,
                  labelText: 'factory.quantity'.tr(),
                  hintText: 'factory.brick_quantity_hint'.tr(),
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
                const SizedBox(height: 32),

                AppButton(
                  text: 'factory.record_handoff'.tr(),
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

  Widget _buildWorkerDropdown({
    required Worker? value,
    required List<Worker> items,
    required String hint,
    required ValueChanged<Worker?> onChanged,
  }) {
    return DropdownButtonFormField<Worker>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      hint: Text(hint),
      items: items.map((w) {
        return DropdownMenuItem<Worker>(
          value: w,
          child: Text(w.name, style: GoogleFonts.outfit()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
