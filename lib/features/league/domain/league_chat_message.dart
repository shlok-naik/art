class LeagueChatMessage {
  const LeagueChatMessage({
    required this.id,
    required this.leagueId,
    required this.userId,
    required this.username,
    required this.body,
    required this.createdAt,
  });

  factory LeagueChatMessage.fromRow(Map<String, dynamic> row, {required String username}) {
    return LeagueChatMessage(
      id: row['id'].toString(),
      leagueId: row['league_id'].toString(),
      userId: row['user_id'].toString(),
      username: username,
      body: row['body']?.toString() ?? '',
      createdAt: DateTime.parse(row['created_at'].toString()),
    );
  }

  final String id;
  final String leagueId;
  final String userId;
  final String username;
  final String body;
  final DateTime createdAt;
}
