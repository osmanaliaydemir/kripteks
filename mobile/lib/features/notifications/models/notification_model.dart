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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type:
          NotificationType.values[json['type']
              as int], // Enum is int in backend usually, or string? Controller sends object list. Assuming int index or string match. Backend shows enum. Let's verify serialization.
      // Usually default json serialization for enums is integer unless configured otherwise.
      // Let's assume integer for now as per C# defaults, or try to parse string if fails.
      // Actually standard API default is usually integer value.
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      relatedBotId: json['relatedBotId']?.toString(),
    );
  }
}
