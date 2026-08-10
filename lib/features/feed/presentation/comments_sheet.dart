import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/app_theme.dart';
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
      final result = await moderateText(text);
      if (result.flagged && mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Profanity detected', style: appBodyStyle(fontWeight: FontWeight.w600)),
            content: Text(
              'Some words in your comment were censored before posting.',
              style: appBodyStyle(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: appBodyStyle(color: kAccentColor)),
              ),
            ],
          ),
        );
      }
      if (!mounted) return;
      await ref
          .read(commentsRepositoryProvider)
          .createComment(sessionId: widget.sessionId, body: result.censored);
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
      style: appBodyStyle(color: kInkColor),
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
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.space12),
                  decoration: BoxDecoration(
                    color: kMutedColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  'Comments',
                  style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 20),
                ),
                const SizedBox(height: AppSpacing.space8),
                const Divider(height: 1),
                Expanded(
                  child: commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return Center(
                          child: Text(
                            'No comments yet — be the first to say something.',
                            textAlign: TextAlign.center,
                            style: appBodyStyle(fontSize: 15, color: kMutedColor),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.space16),
                        itemCount: comments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space16),
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
                    loading: () => const AppSkeletonScreen(rows: 4),
                    error: (error, _) => AppErrorState(
                      error: error,
                      onRetry: () => ref.invalidate(sessionCommentsProvider(widget.sessionId)),
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
                          style: appBodyStyle(fontSize: 15, color: kInkColor),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: appBodyStyle(color: kMutedColor, fontSize: 15),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: kHairlineColor, width: 1),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space12),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space8),
                      IconButton(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const AppIcon(AppIcons.send, size: 20, color: kAccentColor),
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
                    style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Text(
                    _formatCommentTime(comment.createdAt),
                    style: appBodyStyle(fontSize: 12, color: kMutedColor),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(comment.body, style: appBodyStyle(fontSize: 15)),
            ],
          ),
        ),
        PopupMenuButton<void>(
          icon: const AppIcon(AppIcons.more, size: 18, color: kMutedColor),
          padding: EdgeInsets.zero,
          itemBuilder: (context) => [
            if (canDelete)
              PopupMenuItem(
                onTap: onDelete,
                child: Text('Delete', style: appBodyStyle(fontSize: 14)),
              )
            else
              PopupMenuItem(
                onTap: onReport,
                child: Text('Report', style: appBodyStyle(fontSize: 14)),
              ),
          ],
        ),
      ],
    );
  }
}
