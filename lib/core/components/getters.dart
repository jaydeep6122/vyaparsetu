import 'package:vyaparsetu/core/Core.dart';

extension CoreGetters on Core {
  bool get hasActiveBusiness => business.selectedBusiness != null;
  String? get currentBusinessId => business.selectedBusiness?.id;
}
