import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/utils/type_converters.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserModel {
  @JsonKey(name: '_id')
  final String id;
  final String fullName;
  final String email;
  @JsonKey(fromJson: fromUserRoleValue, toJson: toUserRoleValue)
  final UserRole role;
  final String collegeId;
  @JsonKey(defaultValue: false)
  final bool approved;
  @JsonKey(defaultValue: false)
  final bool emailVerified;
  @JsonKey(defaultValue: false)
  final bool needsManualApproval;
  final String? approverId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? phoneNumber;
  final String? rollNumber;
  final String? preferredStop;
  final String? routeId;
  final String? stopId;
  final String? stopName;
  final Map<String, double>? stopLocation;
  final String? fcmToken;
  @JsonKey(defaultValue: 'en')
  final String language;
  @JsonKey(defaultValue: false)
  final bool isPremium;
  final String? subscriptionPlan;
  final DateTime? premiumUntil;
  final String? referralCode;

  // --- Dynamic Expiry Getters ---
  bool get hasActivePremium {
    if (!isPremium) return false;
    if (premiumUntil == null) return false;
    return premiumUntil!.isAfter(DateTime.now());
  }

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.collegeId,
    this.approved = false,
    this.emailVerified = false,
    this.needsManualApproval = false,
    this.approverId,
    required this.createdAt,
    this.updatedAt,
    this.phoneNumber,
    this.rollNumber,
    this.preferredStop,
    this.routeId,
    this.stopId,
    this.stopName,
    this.stopLocation,
    this.fcmToken,
    this.language = 'en',
    this.isPremium = false,
    this.subscriptionPlan,
    this.premiumUntil,
    this.referralCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  // Backward compatibility alias
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    if (!map.containsKey('_id')) {
      map['_id'] = id;
    }
    // Handle potential nulls for required fields to prevent cast errors
    if (map['collegeId'] == null) map['collegeId'] = '';
    if (map['fullName'] == null) map['fullName'] = 'Unknown User';
    if (map['email'] == null) map['email'] = '';

    // Sanitize boolean fields before passing to fromJson
    map['approved'] = parseBool(map['approved'], false);
    map['emailVerified'] = parseBool(map['emailVerified'], false);
    map['needsManualApproval'] = parseBool(map['needsManualApproval'], false);
    map['isPremium'] = parseBool(map['isPremium'], false);

    return UserModel.fromJson(map);
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  Map<String, dynamic> toMap() => toJson();

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    UserRole? role,
    String? collegeId,
    bool? approved,
    bool? emailVerified,
    bool? needsManualApproval,
    String? approverId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phoneNumber,
    String? rollNumber,
    String? preferredStop,
    String? routeId,
    String? stopId,
    String? stopName,
    Map<String, double>? stopLocation,
    String? fcmToken,
    String? language,
    bool? isPremium,
    String? subscriptionPlan,
    DateTime? premiumUntil,
    String? referralCode,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      collegeId: collegeId ?? this.collegeId,
      approved: approved ?? this.approved,
      emailVerified: emailVerified ?? this.emailVerified,
      needsManualApproval: needsManualApproval ?? this.needsManualApproval,
      approverId: approverId ?? this.approverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      rollNumber: rollNumber ?? this.rollNumber,
      preferredStop: preferredStop ?? this.preferredStop,
      routeId: routeId ?? this.routeId,
      stopId: stopId ?? this.stopId,
      stopName: stopName ?? this.stopName,
      stopLocation: stopLocation ?? this.stopLocation,
      fcmToken: fcmToken ?? this.fcmToken,
      language: language ?? this.language,
      isPremium: isPremium ?? this.isPremium,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      referralCode: referralCode ?? this.referralCode,
    );
  }
}

UserRole fromUserRoleValue(dynamic value) {
  if (value is UserRole) return value;
  if (value is String) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.student,
    );
  }
  return UserRole.student;
}

String toUserRoleValue(UserRole role) => role.value;
