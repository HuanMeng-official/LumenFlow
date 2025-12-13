class UserProfile {
  final String id;
  final String username;
  final String? avatarPath;
  final String? avatarEmoji;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.username,
    this.avatarPath,
    this.avatarEmoji,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? username,
    String? avatarPath,
    String? avatarEmoji,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarPath: avatarPath ?? this.avatarPath,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatarPath': avatarPath,
      'avatarEmoji': avatarEmoji,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarPath: json['avatarPath'] as String?,
      avatarEmoji: json['avatarEmoji'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static UserProfile getDefault() {
    return UserProfile(
      id: 'default_user',
      username: '用户',
      avatarEmoji: '😊',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
