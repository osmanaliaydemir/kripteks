enum NotificationType {
  // ignore: constant_identifier_names
  Info,
  // ignore: constant_identifier_names
  Success,
  // ignore: constant_identifier_names
  Warning,
  // ignore: constant_identifier_names
  Error,
  // ignore: constant_identifier_names
  Trade,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedBotId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedBotId,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      relatedBotId: relatedBotId,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _parseNotificationType(json['type']),
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      relatedBotId: json['relatedBotId']?.toString(),
    );
  }

  static NotificationType _parseNotificationType(dynamic value) {
    if (value is int) {
      return NotificationType.values[value];
    }
    if (value is String) {
      return NotificationType.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => NotificationType.Info,
      );
    }
    return NotificationType.Info;
  }
}
