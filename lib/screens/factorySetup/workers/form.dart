import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/factorySetup/worker.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/core/Core.dart';

class WorkerFormScreen extends StatefulWidget {
  final String factoryId;
  final Worker? existingWorker;
  const WorkerFormScreen({
    super.key,
    required this.factoryId,
    this.existingWorker,
  });

  @override
  State<WorkerFormScreen> createState() => _WorkerFormScreenState();
}

class _WorkerFormScreenState extends State<WorkerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Worker? _existingWorker;
  bool _isEdit = false;
  bool _isInitialized = false;

  final _nameController = TextEditingController();
  final _rateController = TextEditingController();

  WorkerType _workerType = WorkerType.producer_molder;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      final args = widget.existingWorker;
      if (args is Worker) {
        _existingWorker = args;
        _isEdit = true;
        _nameController.text = args.name;
        _rateController.text = args.ratePer1000?.toString() ?? '';
        _workerType = args.workerType;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'type': _workerType.value,
      'rate_per_1000': double.tryParse(_rateController.text.trim()) ?? 0,
    };

    bool success;
    if (_isEdit) {
      success = await context.read<Core>().factory.updateWorker(
        widget.factoryId,
        _existingWorker!.id,
        data,
      );
    } else {
      success = await context.read<Core>().factory.createWorker(
        widget.factoryId,
        data,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop({
        'type': 'add_worker',
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showSuccessToast(
            _isEdit
                ? 'factory.worker_updated'.tr()
                : 'factory.worker_added'.tr(),
          );
        }
      });
    } else if (mounted) {
      showErrorToast(
        context.read<Core>().factory.workersError ?? 'factory.worker_save_failed'.tr(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'factory.edit_worker'.tr() : 'factory.add_worker'.tr(),
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
                AppTextField(
                  controller: _nameController,
                  labelText: 'factory.worker_name'.tr(),
                  hintText: 'factory.enter_worker_name'.tr(),
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'factory.worker_name_required'.tr()
                      : null,
                ),
                const SizedBox(height: 16),

                Text(
                  'factory.worker_type'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:
                        theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<WorkerType>(
                  value: _workerType,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  items: WorkerType.values.map((type) {
                    return DropdownMenuItem<WorkerType>(
                      value: type,
                      child: Text(
                        type.displayName,
                        style: GoogleFonts.outfit(),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _workerType = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _rateController,
                  labelText: 'factory.rate_per_1000'.tr(),
                  hintText: 'factory.rate_per_1000_hint'.tr(),
                  prefixIcon: Icons.monetization_on_outlined,
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'factory.rate_required'.tr()
                      : null,
                ),
                const SizedBox(height: 32),

                AppButton(
                  text: 'save'.tr(),
                  isLoading: context.select<Core, bool>(
                    (c) => c.factory.isLoadingWorkers,
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
}
