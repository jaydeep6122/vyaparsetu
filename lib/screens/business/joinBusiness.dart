import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/screens/home/home.dart';

/// Asks for an invite code, joins that business and opens it.
Future<void> showJoinBusinessDialog(BuildContext context) async {
  final code = await showDialog<String>(
    context: context,
    builder: (_) => const _JoinBusinessDialog(),
  );
  if (code == null || code.isEmpty || !context.mounted) return;

  final core = context.read<Core>();
  final joined = await core.member.acceptInvite(code);
  if (!context.mounted) return;
  if (joined == null) {
    showErrorToast(core.member.error ?? 'error_generic'.tr());
    return;
  }
  showSuccessToast('joined_business'.tr(namedArgs: {'name': joined.name}));
  Navigator.of(context).pushAndRemoveUntil(
    getPageRoute(const HomeScreen()),
    (_) => false,
  );
}

class _JoinBusinessDialog extends StatefulWidget {
  const _JoinBusinessDialog();

  @override
  State<_JoinBusinessDialog> createState() => _JoinBusinessDialogState();
}

class _JoinBusinessDialogState extends State<_JoinBusinessDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('join_business'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('join_business_hint'.tr()),
          const SizedBox(height: AppTheme.spaceLg),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'invite_code'.tr(),
              prefixIcon: const Icon(Icons.vpn_key_outlined),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr()),
        ),
        FilledButton(onPressed: _submit, child: Text('join'.tr())),
      ],
    );
  }
}
