import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/appTextField.dart';
import 'package:vyaparsetu/components/avatar.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/components/formFields.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/pickerSheet.dart';
import 'package:vyaparsetu/components/sectionHeader.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/validators.dart';
import 'package:vyaparsetu/screens/auth/sessionRouter.dart';
import 'package:vyaparsetu/types/member.dart';

/// Roles a user may give: those below their own.
List<MemberRole> _assignableRoles(MemberRole myRole) => const [
  MemberRole.admin,
  MemberRole.accountant,
  MemberRole.staff,
].where((role) => role.rank < myRole.rank).toList();

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<Core>().member.fetch(refresh: true),
    );
  }

  Future<void> _refresh() => context.read<Core>().member.fetch(refresh: true);

  Future<void> _changeRole(Member member) async {
    final core = context.read<Core>();
    final role = await showPickerSheet<MemberRole>(
      context: context,
      title: 'change_role_for'.tr(namedArgs: {'name': member.name}),
      options: _assignableRoles(core.role),
      labelOf: (role) => role.displayName,
      subtitleOf: (role) => role.description,
      isSelected: (role) => role == member.role,
      searchable: false,
    );
    if (role == null || role == member.role || !mounted) return;
    if (await core.member.changeRole(member.userId, role)) {
      showSuccessToast('role_changed'.tr(namedArgs: {'name': member.name, 'role': role.displayName}));
    } else {
      showErrorToast(core.member.error ?? 'error_generic'.tr());
    }
  }

  Future<void> _remove(Member member) async {
    final core = context.read<Core>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'remove_member_title'.tr(),
      message: 'remove_member_message'.tr(namedArgs: {'name': member.name}),
      confirmText: 'remove'.tr(),
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    if (!await core.member.removeMember(member.userId)) {
      showErrorToast(core.member.error ?? 'error_generic'.tr());
    }
  }

  Future<void> _leave(String userId) async {
    final core = context.read<Core>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'leave_business_title'.tr(),
      message: 'leave_business_message'.tr(
        namedArgs: {'name': core.business.selectedBusiness?.name ?? ''},
      ),
      confirmText: 'leave'.tr(),
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    if (await core.member.removeMember(userId)) {
      if (mounted) await openAfterSignIn(context);
    } else {
      showErrorToast(core.member.error ?? 'error_generic'.tr());
    }
  }

  Future<void> _revoke(Invite invite) async {
    final core = context.read<Core>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'revoke_invite_title'.tr(),
      message: 'revoke_invite_message'.tr(namedArgs: {'email': invite.email}),
      confirmText: 'revoke'.tr(),
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    if (!await core.member.revokeInvite(invite.id)) {
      showErrorToast(core.member.error ?? 'error_generic'.tr());
    }
  }

  Future<void> _invite() async {
    final invite = await showModalBottomSheet<Invite>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _InviteSheet(),
    );
    if (invite == null || !mounted) return;
    final businessName = context.read<Core>().business.selectedBusiness?.name ?? '';
    await showDialog<void>(
      context: context,
      builder: (_) => _InviteCodeDialog(invite: invite, businessName: businessName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final me = core.auth.user?.id;
    final myRole = core.role;
    final isAdmin = core.can(MemberRole.admin);

    return Scaffold(
      appBar: AppBar(title: Text('team'.tr())),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'invite-member',
              onPressed: _invite,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text('invite_member'.tr()),
            )
          : null,
      body: LoadStateBody<List<Member>>(
        state: core.member.members,
        onRetry: _refresh,
        builder: (context, members) {
          final invites = core.member.invites.value ?? const <Invite>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceSm,
                AppTheme.spaceLg,
                AppTheme.fabClearance,
              ),
              children: [
                SectionHeader(
                  title: 'members_count'.tr(namedArgs: {'count': '${members.length}'}),
                ),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (index, member) in members.indexed) ...[
                        if (index > 0) const Divider(indent: 72),
                        ListTile(
                          leading: InitialsAvatar(name: member.name),
                          title: Text(
                            member.userId == me
                                ? 'member_you'.tr(namedArgs: {'name': member.name})
                                : member.name,
                          ),
                          subtitle: Text(member.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusChip(
                                label: member.role.displayName,
                                tone: member.role == MemberRole.owner
                                    ? ChipTone.primary
                                    : ChipTone.neutral,
                              ),
                              if (isAdmin &&
                                  member.userId != me &&
                                  member.role.rank < myRole.rank)
                                PopupMenuButton<String>(
                                  onSelected: (action) => action == 'role'
                                      ? _changeRole(member)
                                      : _remove(member),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(value: 'role', child: Text('change_role'.tr())),
                                    PopupMenuItem(value: 'remove', child: Text('remove'.tr())),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: AppTheme.space2xl),
                  SectionHeader(title: 'pending_invites'.tr()),
                  if (invites.isEmpty)
                    Text('no_pending_invites'.tr(), style: context.text.bodyMedium)
                  else
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (index, invite) in invites.indexed) ...[
                            if (index > 0) const Divider(indent: 72),
                            ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.mail_outline_rounded)),
                              title: Text(invite.email),
                              subtitle: Text([
                                invite.role.displayName,
                                if (invite.expiresAt != null)
                                  'expires_on'.tr(namedArgs: {
                                    'date': Formatters.formatDate(invite.expiresAt!),
                                  }),
                              ].join(' · ')),
                              trailing: IconButton(
                                tooltip: 'revoke'.tr(),
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => _revoke(invite),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: AppTheme.space2xl),
                SectionHeader(title: 'roles_guide'.tr()),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final role in MemberRole.values.reversed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(role.displayName, style: context.text.titleSmall),
                              Text(role.description, style: context.text.bodySmall),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (me != null && myRole != MemberRole.owner) ...[
                  const SizedBox(height: AppTheme.space2xl),
                  AppButton(
                    text: 'leave_business'.tr(),
                    icon: Icons.logout_rounded,
                    variant: AppButtonVariant.text,
                    onPressed: () => _leave(me),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet();

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  MemberRole _role = MemberRole.staff;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final core = context.read<Core>();
    final invite = await core.member.invite(
      email: _email.text.trim().toLowerCase(),
      role: _role,
    );
    if (!mounted) return;
    if (invite == null) {
      showErrorToast(core.member.error ?? 'error_generic'.tr());
      return;
    }
    Navigator.of(context).pop(invite);
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final roles = _assignableRoles(core.role);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spaceLg,
        0,
        AppTheme.spaceLg,
        MediaQuery.viewInsetsOf(context).bottom + AppTheme.spaceLg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('invite_member'.tr(), style: context.text.titleLarge),
            const SizedBox(height: AppTheme.spaceXs),
            Text('invite_member_hint'.tr(), style: context.text.bodyMedium),
            const SizedBox(height: AppTheme.spaceLg),
            AppTextField(
              controller: _email,
              labelText: 'email'.tr(),
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline_rounded,
              autofocus: true,
              validator: Validators.email,
            ),
            const SizedBox(height: AppTheme.spaceLg),
            ChoiceChipsField<MemberRole>(
              label: 'role'.tr(),
              options: roles,
              value: _role,
              labelOf: (role) => role.displayName,
              onChanged: (role) => setState(() => _role = role),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(_role.description, style: context.text.bodySmall),
            const SizedBox(height: AppTheme.space2xl),
            AppButton(
              text: 'create_invite'.tr(),
              isLoading: core.member.isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCodeDialog extends StatelessWidget {
  final Invite invite;
  final String businessName;

  const _InviteCodeDialog({required this.invite, required this.businessName});

  @override
  Widget build(BuildContext context) {
    final code = invite.inviteToken ?? '';

    return AlertDialog(
      icon: Icon(Icons.mark_email_read_outlined, color: context.colors.primary),
      title: Text('invite_created'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'invite_created_hint'.tr(namedArgs: {'email': invite.email}),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceLg),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: BoxDecoration(
              color: context.colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: SelectableText(
              code,
              textAlign: TextAlign.center,
              style: context.text.titleSmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text('copy'.tr()),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            showSuccessToast('copied'.tr());
          },
        ),
        FilledButton.icon(
          icon: const Icon(Icons.share_rounded, size: 18),
          label: Text('share'.tr()),
          onPressed: () => SharePlus.instance.share(
            ShareParams(
              text: 'invite_share_message'.tr(
                namedArgs: {'business': businessName, 'code': code},
              ),
            ),
          ),
        ),
      ],
    );
  }
}
