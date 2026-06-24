class UserSession {
  final String? userId;
  final String? name;
  final String? status;
  final String? currentAction;
  final String? lastActive;

  const UserSession({
    this.userId,
    this.name,
    this.status,
    this.currentAction,
    this.lastActive,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['userId']?.toString(),
      name: json['name']?.toString(),
      status: json['status']?.toString(),
      currentAction: json['currentAction']?.toString(),
      lastActive: json['lastActive']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'status': status,
      'currentAction': currentAction,
      'lastActive': lastActive,
    };
  }

  bool get isOnline => status == 'online';

  @override
  String toString() {
    return 'UserSession(userId: $userId, name: $name, status: $status, action: $currentAction)';
  }
}
