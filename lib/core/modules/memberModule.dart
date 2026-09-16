import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/core/components/moduleBase.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/types/member.dart';

/// Team members and invites of the selected business.
class MemberModule extends CoreModule {
  MemberModule(super.core);

  final LoadState<List<Member>> members = LoadState();
  final LoadState<List<Invite>> invites = LoadState();

  Future<void> fetch({bool refresh = false}) async {
    final businessId = core.businessId;
    await loadValue(
      members,
      () async => (await Api.instance.member.list(businessId))
          .map(Member.fromJson)
          .toList(),
      refresh: refresh,
    );
    if (core.can(MemberRole.admin)) {
      await loadValue(
        invites,
        () async => (await Api.instance.member.invites(businessId))
            .map(Invite.fromJson)
            .toList(),
        refresh: refresh,
      );
    }
  }

  /// The returned invite carries the one-time token to share.
  Future<Invite?> invite({required String email, required MemberRole role}) async {
    final json = await runSave(
      () => Api.instance.member.createInvite(
        core.businessId,
        email: email,
        role: role.value,
      ),
    );
    if (json == null) return null;
    await fetch(refresh: true);
    return Invite.fromJson(json);
  }

  Future<bool> revokeInvite(String inviteId) async {
    final done = await runSave(
      () => Api.instance.member
          .revokeInvite(core.businessId, inviteId)
          .then((_) => true),
    );
    if (done != true) return false;
    await fetch(refresh: true);
    return true;
  }

  Future<bool> changeRole(String userId, MemberRole role) async {
    final json = await runSave(
      () => Api.instance.member.changeRole(core.businessId, userId, role.value),
    );
    if (json == null) return false;
    await fetch(refresh: true);
    return true;
  }

  Future<bool> removeMember(String userId) async {
    final done = await runSave(
      () => Api.instance.member
          .remove(core.businessId, userId)
          .then((_) => true),
    );
    if (done != true) return false;
    await fetch(refresh: true);
    return true;
  }

  /// Joins a business with an invite code and switches to it.
  Future<Business?> acceptInvite(String token) async {
    final json = await runSave(() => Api.instance.member.acceptInvite(token));
    if (json == null) return null;
    final joined = Business.fromJson(json);
    await core.business.fetchBusinesses();
    final fresh = core.business.businesses.where((b) => b.id == joined.id);
    await core.business.selectBusiness(fresh.firstOrNull ?? joined);
    return joined;
  }

  void clear() {
    members.reset();
    invites.reset();
  }
}
