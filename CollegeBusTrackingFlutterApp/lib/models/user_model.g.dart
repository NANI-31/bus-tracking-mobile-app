// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['_id'] as String,
  fullName: json['fullName'] as String,
  email: json['email'] as String,
  role: fromUserRoleValue(json['role']),
  collegeId: json['collegeId'] as String,
  approved: json['approved'] as bool? ?? false,
  emailVerified: json['emailVerified'] as bool? ?? false,
  needsManualApproval: json['needsManualApproval'] as bool? ?? false,
  approverId: json['approverId'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  phoneNumber: json['phoneNumber'] as String?,
  rollNumber: json['rollNumber'] as String?,
  preferredStop: json['preferredStop'] as String?,
  routeId: json['routeId'] as String?,
  stopId: json['stopId'] as String?,
  stopName: json['stopName'] as String?,
  stopLocation: (json['stopLocation'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  fcmToken: json['fcmToken'] as String?,
  language: json['language'] as String? ?? 'en',
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  '_id': instance.id,
  'fullName': instance.fullName,
  'email': instance.email,
  'role': toUserRoleValue(instance.role),
  'collegeId': instance.collegeId,
  'approved': instance.approved,
  'emailVerified': instance.emailVerified,
  'needsManualApproval': instance.needsManualApproval,
  'approverId': instance.approverId,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'phoneNumber': instance.phoneNumber,
  'rollNumber': instance.rollNumber,
  'preferredStop': instance.preferredStop,
  'routeId': instance.routeId,
  'stopId': instance.stopId,
  'stopName': instance.stopName,
  'stopLocation': instance.stopLocation,
  'fcmToken': instance.fcmToken,
  'language': instance.language,
};
