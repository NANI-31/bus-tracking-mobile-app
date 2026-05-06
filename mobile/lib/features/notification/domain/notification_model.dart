import 'package:collegebus/core/utils/type_converters.dart';

class NotificationModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final String? groupId;
  final Map<String, dynamic>? data;
  final String? audioUrl; // Transient field for pre-signed URL from server

  NotificationModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.groupId,
    this.data,
    this.audioUrl,
  });

  bool get isVoice => type == 'VOICE_NOTIFICATION';
  String? get voiceKey => data?['voiceKey'];

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      isRead: parseBool(map['isRead'], false),
      groupId: map['groupId'],
      data: map['data'],
      audioUrl: map['audioUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'groupId': groupId,
      'data': data,
      'audioUrl': audioUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? message,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    String? groupId,
    Map<String, dynamic>? data,
    String? audioUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      groupId: groupId ?? this.groupId,
      data: data ?? this.data,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}
