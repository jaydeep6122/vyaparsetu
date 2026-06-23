import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/factorySetup/factory.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/core/Core.dart';

class FactoryFormScreen extends StatefulWidget {
  final Factory? existingFactory;
  const FactoryFormScreen({super.key, this.existingFactory});

  @override
  State<FactoryFormScreen> createState() => _FactoryFormScreenState();
}

class _FactoryFormScreenState extends State<FactoryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Factory? _existingFactory;
  bool _isEdit = false;
  bool _isInitialized = false;

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      final args = widget.existingFactory;
      if (args is Factory) {
        _existingFactory = args;
        _isEdit = true;
        _nameController.text = args.name;
        _locationController.text = args.location ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    };

    bool success;
    if (_isEdit) {
      success = await context.read<Core>().factory.updateFactory(
        _existingFactory!.id, data,
      );
    } else {
      success = await context.read<Core>().factory.createFactory(data);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showSuccessToast(
            _isEdit ? 'factory.factory_updated'.tr() : 'factory.factory_added'.tr(),
          );
        }
      });
    } else if (mounted) {
      showErrorToast(
        context.read<Core>().factory.factoriesError ?? 'factory.factory_save_failed'.tr(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'factory.edit_factory'.tr() : 'factory.add_factory'.tr(),
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
                  labelText: 'factory.factory_name'.tr(),
                  hintText: 'factory.enter_factory_name'.tr(),
                  prefixIcon: Icons.factory_outlined,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'factory.factory_name_required'.tr()
                      : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _locationController,
                  labelText: 'factory.location'.tr(),
                  hintText: 'factory.enter_factory_location'.tr(),
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'save'.tr(),
                  isLoading: context.select<Core, bool>(
                    (c) => c.factory.isLoadingFactories,
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
