import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';

class Member {
  final String userId;
  final String name;
  final String email;
  final MemberRole role;
  final DateTime? joinedAt;

  const Member({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.joinedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      userId: json['user_id'] as String,
      name: asString(json['name']),
      email: asString(json['email']),
      role: MemberRole.fromString(json['role'] as String?),
      joinedAt: asDate(json['joined_at']),
    );
  }
}

class Invite {
  final String id;
  final String email;
  final MemberRole role;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  /// Only present right after creating the invite; it cannot be read again.
  final String? inviteToken;

  const Invite({
    required this.id,
    required this.email,
    required this.role,
    this.expiresAt,
    this.createdAt,
    this.inviteToken,
  });

  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      id: json['id'] as String,
      email: asString(json['email']),
      role: MemberRole.fromString(json['role'] as String?),
      expiresAt: asDate(json['expires_at']),
      createdAt: asDate(json['created_at']),
      inviteToken: json['invite_token'] as String?,
    );
  }
}

class DocumentSeries {
  final String id;

  /// sale, sale_non_gst, purchase, purchase_non_gst, sale_return,
  /// purchase_return, payment_in, payment_out or expense.
  final String docType;
  final String financialYear;
  final String prefix;
  final int nextNumber;
  final int padding;

  const DocumentSeries({
    required this.id,
    required this.docType,
    required this.financialYear,
    required this.prefix,
    required this.nextNumber,
    required this.padding,
  });

  factory DocumentSeries.fromJson(Map<String, dynamic> json) {
    return DocumentSeries(
      id: json['id'] as String,
      docType: asString(json['doc_type']),
      financialYear: asString(json['financial_year']),
      prefix: asString(json['prefix']),
      nextNumber: asInt(json['next_number'], 1),
      padding: asInt(json['padding'], 1),
    );
  }

  /// What the next document will be numbered, e.g. "INV/26-27/12".
  String get preview => '$prefix${nextNumber.toString().padLeft(padding, '0')}';
}
