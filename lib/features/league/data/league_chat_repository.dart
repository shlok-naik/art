import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/league_chat_message.dart';

class LeagueChatRepository {
  LeagueChatRepository(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// One query for the messages, then a batched profiles lookup to resolve
  /// usernames — same shape as CommentsRepository.fetchComments, since
  /// there's no direct foreign key from league_chat_messages to profiles for
  /// PostgREST to embed (both merely reference auth.users).
  Future<List<LeagueChatMessage>> fetchMessages(String leagueId) async {
    final rows = await _client
        .from('league_chat_messages')
        .select()
        .eq('league_id', leagueId)
        .order('created_at', ascending: true);
    final messages = List<Map<String, dynamic>>.from(rows);

    final userIds = {for (final m in messages) m['user_id'].toString()};
    final usernames = await _fetchUsernames(userIds);

    return [
      for (final m in messages)
        LeagueChatMessage.fromRow(m, username: usernames[m['user_id'].toString()] ?? 'unknown'),
    ];
  }

  /// Resolves a single sender's username — used to hydrate a message that
  /// arrives over the realtime channel from a sender not already seen this
  /// session.
  Future<String> fetchUsername(String userId) async {
    final usernames = await _fetchUsernames({userId});
    return usernames[userId] ?? 'unknown';
  }

  Future<Map<String, String>> _fetchUsernames(Set<String> userIds) async {
    if (userIds.isEmpty) return const {};
    final rows = await _client.from('profiles').select('id, username').inFilter('id', userIds.toList());
    return {
      for (final p in List<Map<String, dynamic>>.from(rows)) p['id'].toString(): p['username'].toString(),
    };
  }

  Future<Map<String, dynamic>> sendMessage({required String leagueId, required String body}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not signed in');
    final rows = await _client.from('league_chat_messages').insert({
      'league_id': leagueId,
      'user_id': userId,
      'body': body,
    }).select();
    return Map<String, dynamic>.from(rows.first);
  }

  Future<void> deleteMessage(String messageId) async {
    await _client.from('league_chat_messages').delete().eq('id', messageId);
  }

  /// Files a report against [messageId]. Upserts with `ignoreDuplicates`
  /// against the (message_id, reporter_id) unique constraint, so reporting
  /// the same message twice is a silent no-op — same pattern as
  /// CommentsRepository.reportComment.
  Future<void> reportMessage(String messageId, {String? reason}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not signed in');
    await _client.from('league_chat_message_reports').upsert(
      {'message_id': messageId, 'reporter_id': userId, 'reason': reason},
      onConflict: 'message_id,reporter_id',
      ignoreDuplicates: true,
    );
  }

  /// Opens a realtime channel delivering every new message posted to
  /// [leagueId]'s chat. The caller owns the returned channel and must
  /// `unsubscribe()` it when done.
  RealtimeChannel subscribeToNewMessages(
    String leagueId,
    void Function(Map<String, dynamic> row) onInsert,
  ) {
    final channel = _client.channel('league-chat-$leagueId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'league_chat_messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'league_id', value: leagueId),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
    return channel;
  }
}
