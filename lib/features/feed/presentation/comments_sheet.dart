import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../../shared/moderation_service.dart';
import '../../profile/providers.dart';
import '../domain/comment.dart';
import '../providers.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatCommentTime(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_monthNames[local.month - 1]}, $hour:$minute';
}

/// Opens the comments thread for a session as a bottom sheet. [postOwnerUserId]
/// lets the post's own author moderate (delete) any comment on it, not just
/// their own.
Future<void> showCommentsSheet(
  BuildContext context, {
  required String sessionId,
  required String postOwnerUserId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _CommentsSheet(sessionId: sessionId, postOwnerUserId: postOwnerUserId),
  );
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.sessionId, required this.postOwnerUserId});

  final String sessionId;
  final String postOwnerUserId;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      if (await containsFlaggedContent(text)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please remove inappropriate language before posting.')),
        );
        return;
      }
      await ref
          .read(commentsRepositoryProvider)
          .createComment(sessionId: widget.sessionId, body: text);
      if (!mounted) return;
      ref.invalidate(sessionCommentsProvider(widget.sessionId));
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete(String commentId) async {
    try {
      await ref.read(commentsRepositoryProvider).deleteComment(commentId);
      if (!mounted) return;
      ref.invalidate(sessionCommentsProvider(widget.sessionId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete comment: $e')),
      );
    }
  }

  Future<void> _report(String commentId) async {
    try {
      await ref.read(commentsRepositoryProvider).reportComment(commentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment reported. Thanks for flagging it.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(sessionCommentsProvider(widget.sessionId));
    final currentUserId = ref.watch(currentProfileProvider).value?.id;

    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  'Comments',
                  style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                Expanded(
                  child: commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return Center(
                          child: Text(
                            'No comments yet — be the first to say something.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.chewy(fontSize: 15, color: Colors.black54),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: comments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          final canDelete = comment.userId == currentUserId ||
                              widget.postOwnerUserId == currentUserId;
                          return _CommentTile(
                            comment: comment,
                            canDelete: canDelete,
                            onDelete: () => _delete(comment.id),
                            onReport: () => _report(comment.id),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: AppErrorText('Failed to load comments: $error'),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !_isSubmitting,
                          maxLength: 500,
                          minLines: 1,
                          maxLines: 4,
                          style: GoogleFonts.chewy(fontSize: 15, color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: GoogleFonts.chewy(color: Colors.black38, fontSize: 15),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: kBorderColor, width: kBorderWidth),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send, color: kAccentColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
    required this.onReport,
  });

  final Comment comment;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '@${comment.username}',
                    style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatCommentTime(comment.createdAt),
                    style: GoogleFonts.chewy(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(comment.body, style: GoogleFonts.chewy(fontSize: 15)),
            ],
          ),
        ),
        PopupMenuButton<void>(
          icon: const Icon(Icons.more_horiz, size: 18, color: Colors.black45),
          padding: EdgeInsets.zero,
          itemBuilder: (context) => [
            if (canDelete)
              PopupMenuItem(
                onTap: onDelete,
                child: Text('Delete', style: GoogleFonts.chewy(fontSize: 14)),
              )
            else
              PopupMenuItem(
                onTap: onReport,
                child: Text('Report', style: GoogleFonts.chewy(fontSize: 14)),
              ),
          ],
        ),
      ],
    );
  }
}
