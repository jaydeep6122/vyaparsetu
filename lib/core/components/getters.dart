import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';

extension CoreGetters on Core {
  bool get hasActiveBusiness => business.selectedBusiness != null;
  String? get currentBusinessId => business.selectedBusiness?.id;

  /// The selected business id. Only use on screens reached after a business
  /// is selected.
  String get businessId => business.selectedBusiness!.id;

  MemberRole get role => business.selectedBusiness?.role ?? MemberRole.staff;

  /// Whether the signed-in user's role in the selected business is at least
  /// [minimum].
  bool can(MemberRole minimum) => role.atLeast(minimum);
}
