class PollOption {
  final String id;
  final String text;
  int votes;

  PollOption({required this.id, required this.text, this.votes = 0});

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'votes': votes};

  factory PollOption.fromMap(Map<String, dynamic> map) => PollOption(
        id: map['id'] as String,
        text: map['text'] as String,
        votes: map['votes'] as int? ?? 0,
      );
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'update', 'announcement', 'feature', 'maintenance', 'poll', 'feedback'
  final DateTime createdAt;
  final bool isRead;
  final String? actionUrl;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final bool broadcast;
  final List<String>? targetUserIds;
  final List<PollOption>? pollOptions;
  final String? userVote;
  final String? userFeedback;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.actionUrl,
    this.imageUrl,
    this.metadata,
    this.broadcast = true,
    this.targetUserIds,
    this.pollOptions,
    this.userVote,
    this.userFeedback,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead ? 1 : 0,
        'actionUrl': actionUrl,
        'imageUrl': imageUrl,
        'metadata': metadata?.toString(),
        'broadcast': broadcast ? 1 : 0,
        'targetUserIds': targetUserIds?.join(','),
        'pollOptions': pollOptions != null
            ? pollOptions!.map((o) => o.toMap()).toList().toString()
            : null,
        'userVote': userVote,
        'userFeedback': userFeedback,
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    List<PollOption>? options;
    if (map['pollOptions'] != null && map['pollOptions'] is String) {
      try {
        final str = map['pollOptions'] as String;
        if (str.isNotEmpty && str != 'null') {
          // Parse string representation back to list
          options = [];
        }
      } catch (_) {}
    }
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isRead: (map['isRead'] as int?) == 1,
      actionUrl: map['actionUrl'] as String?,
      imageUrl: map['imageUrl'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
      broadcast: (map['broadcast'] as int?) == 1,
      targetUserIds: map['targetUserIds'] != null && map['targetUserIds'] != ''
          ? (map['targetUserIds'] as String).split(',')
          : null,
      pollOptions: options,
      userVote: map['userVote'] as String?,
      userFeedback: map['userFeedback'] as String?,
    );
  }

  factory AppNotification.fromFirestore(Map<String, dynamic> data) {
    List<PollOption>? options;
    if (data['pollOptions'] != null) {
      try {
        final list = data['pollOptions'] as List;
        options = list.map((o) => PollOption.fromMap(o as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return AppNotification(
      id: data['id'] as String,
      title: data['title'] as String,
      message: data['message'] as String,
      type: data['type'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      isRead: false,
      actionUrl: data['actionUrl'] as String?,
      imageUrl: data['imageUrl'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      broadcast: data['broadcast'] as bool? ?? true,
      targetUserIds: data['targetUserIds'] != null
          ? List<String>.from(data['targetUserIds'] as List)
          : null,
      pollOptions: options,
    );
  }

  AppNotification copyWith({
    bool? isRead,
    String? userVote,
    String? userFeedback,
    List<PollOption>? pollOptions,
  }) =>
      AppNotification(
        id: id,
        title: title,
        message: message,
        type: type,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        actionUrl: actionUrl,
        imageUrl: imageUrl,
        metadata: metadata,
        broadcast: broadcast,
        targetUserIds: targetUserIds,
        pollOptions: pollOptions ?? this.pollOptions,
        userVote: userVote ?? this.userVote,
        userFeedback: userFeedback ?? this.userFeedback,
      );

  bool get isPoll => type == 'poll';
  bool get isFeedback => type == 'feedback';
  bool get hasVoted => userVote != null;
  bool get hasFeedback => userFeedback != null && userFeedback!.isNotEmpty;
}
