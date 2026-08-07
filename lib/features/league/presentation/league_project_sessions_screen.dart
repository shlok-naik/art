import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../feed/domain/feed_post.dart';
import '../../posts/presentation/post_detail_screen.dart';
import '../../projects/providers.dart';
import '../domain/league.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _formatLoggedAt(dynamic value) {
  if (value == null) return '—';
  final date = DateTime.tryParse(value.toString());
  if (date == null) return value.toString();
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

String _formatDuration(int totalSeconds) {
  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

/// Read-only view of every session behind a league submission — this is
/// someone else's (or your own) project as entered into the league, browsed
/// session by session. Unlike ProjectDetailScreen, this never lets the
/// viewer start a new session: RLS would reject it for another artist's
/// project anyway, and starting one on your own project belongs in the
/// Projects tab, not here.
class LeagueProjectSessionsScreen extends ConsumerWidget {
  const LeagueProjectSessionsScreen({super.key, required this.submission});

  final LeagueSubmission submission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsListProvider(submission.projectId));
    final project = {
      'id': submission.projectId,
      'title': submission.projectTitle,
      'user_id': submission.userId,
      'completion_percent': submission.projectCompletionPercent,
      'finished_status': submission.projectFinishedStatus,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appThemedAppBar(context, submission.projectTitle),
      body: SafeArea(
        child: sessionsAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return Center(
                child: Text('No sessions logged yet.', style: GoogleFonts.chewy(fontSize: 15, color: Colors.black54)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final photoUrl = session['photo_url']?.toString();
                final durationSeconds = int.tryParse(session['duration']?.toString() ?? '') ?? 0;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(
                        post: FeedPost.fromRow(
                          session: session,
                          project: project,
                          artist: submission.artistUsername,
                        ),
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: appCardDecoration(),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? Container(
                                  width: 52,
                                  height: 52,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_not_supported, color: Colors.black38),
                                )
                              : CachedNetworkImage(imageUrl: photoUrl, width: 52, height: 52, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDuration(durationSeconds),
                                style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Logged: ${_formatLoggedAt(session['created_at'])}',
                                style: GoogleFonts.chewy(fontSize: 13, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.black38),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: kAccentColor)),
          error: (error, _) => Center(child: Text('Failed to load sessions: $error', style: GoogleFonts.chewy())),
        ),
      ),
    );
  }
}
