class Comment {
  const Comment({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.username,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String userId;
  final String username;
  final String body;
  final DateTime createdAt;
}
