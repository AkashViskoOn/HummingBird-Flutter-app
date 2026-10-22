/// A local follow-up reminder attached to a chat message.
///
/// Reminders are stored in GetStorage (never in Hive / the backend) and fire
/// as a local notification when [remindAt] is reached. They only remind the
/// user — they never auto-send a message.
class Reminder {
  /// Stable unique id, also used (via [reminderNotificationId]) as the local
  /// notification id so re-scheduling/snoozing replaces the same alert.
  String id;

  /// Chat message this reminder is attached to (may be empty for generic
  /// "follow up on this conversation" reminders created from the chat list).
  String messageId;

  /// Plaintext preview of the attached message shown in the notification.
  String messageText;

  String roomId;
  String receiverId;
  String roomUsers;
  String name;
  String userNumber;
  String userProfile;
  bool isGroup;

  /// When the reminder should fire.
  DateTime remindAt;

  DateTime createdAt;

  /// active -> triggered -> completed | snoozed
  String state;

  int snoozeCount;

  Reminder({
    required this.id,
    required this.messageId,
    required this.messageText,
    required this.roomId,
    required this.receiverId,
    required this.roomUsers,
    required this.name,
    required this.userNumber,
    required this.userProfile,
    required this.isGroup,
    required this.remindAt,
    required this.createdAt,
    this.state = 'active',
    this.snoozeCount = 0,
  });

  /// Notification id used by [NotificationService] — stable per reminder.
  int get reminderNotificationId => id.hashCode;

  bool get isActive => state == 'active' || state == 'snoozed';

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: (json['id'] ?? '').toString(),
      messageId: (json['messageId'] ?? '').toString(),
      messageText: (json['messageText'] ?? '').toString(),
      roomId: (json['roomId'] ?? '').toString(),
      receiverId: (json['receiverId'] ?? '').toString(),
      roomUsers: (json['roomUsers'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      userNumber: (json['userNumber'] ?? '').toString(),
      userProfile: (json['userProfile'] ?? '').toString(),
      isGroup: json['isGroup'] == true || json['isGroup'] == '1',
      remindAt: DateTime.fromMillisecondsSinceEpoch(
        (json['remindAt'] ?? 0),
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] ?? 0),
      ),
      state: (json['state'] ?? 'active').toString(),
      snoozeCount: (json['snoozeCount'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'messageId': messageId,
        'messageText': messageText,
        'roomId': roomId,
        'receiverId': receiverId,
        'roomUsers': roomUsers,
        'name': name,
        'userNumber': userNumber,
        'userProfile': userProfile,
        'isGroup': isGroup,
        'remindAt': remindAt.millisecondsSinceEpoch,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'state': state,
        'snoozeCount': snoozeCount,
      };
}
