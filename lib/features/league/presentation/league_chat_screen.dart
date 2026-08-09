import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/moderation_service.dart';
import '../../profile/providers.dart';
import '../domain/league_chat_message.dart';
import '../providers.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatMessageTime(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_monthNames[local.month - 1]}, $hour:$minute';
}

class LeagueChatScreen extends ConsumerStatefulWidget {
  const LeagueChatScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  ConsumerState<LeagueChatScreen> createState() => _LeagueChatScreenState();
}

class _LeagueChatScreenState extends ConsumerState<LeagueChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;
  int _lastMessageCount = -1;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Profanity detected', style: appBodyStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            content: Text(
              'Some words in your message were censored before posting.',
              style: appBodyStyle(fontSize: 14, color: kMutedColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kAccentColor)),
              ),
            ],
          ),
        );
      }
      if (!mounted) return;
      await ref.read(leagueChatMessagesProvider(widget.leagueId).notifier).send(result.censored);
      if (!mounted) return;
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete(String messageId) async {
    try {
      await ref.read(leagueChatMessagesProvider(widget.leagueId).notifier).delete(messageId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  Future<void> _report(String messageId) async {
    try {
      await ref.read(leagueChatMessagesProvider(widget.leagueId).notifier).report(messageId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message reported. Thanks for flagging it.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to report: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(leagueChatMessagesProvider(widget.leagueId));
    final currentUserId = ref.watch(currentProfileProvider).value?.id;

    final messageCount = messagesAsync.value?.length ?? 0;
    if (messageCount != _lastMessageCount) {
      _lastMessageCount = messageCount;
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppNavyHeader(title: 'League Chat'),
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet — say hello.',
                        style: appBodyStyle(fontSize: 14, color: kMutedColor),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageTile(
                        message: message,
                        canDelete: message.userId == currentUserId,
                        onDelete: () => _delete(message.id),
                        onReport: () => _report(message.id),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => AppErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(leagueChatMessagesProvider(widget.leagueId)),
                ),
              ),
            ),
            const Divider(color: kHairlineColor, height: 1, thickness: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).viewInsets.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isSubmitting,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 4,
                      style: appBodyStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Message the league...',
                        hintStyle: appBodyStyle(fontSize: 15, color: kMutedColor),
                        counterText: '',
                        filled: true,
                        fillColor: kSurfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
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
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.canDelete,
    required this.onDelete,
    required this.onReport,
  });

  final LeagueChatMessage message;
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
                    '@${message.username}',
                    style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatMessageTime(message.createdAt),
                    style: appBodyStyle(fontSize: 12, color: kMutedColor),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(message.body, style: appBodyStyle(fontSize: 15)),
            ],
          ),
        ),
        PopupMenuButton<void>(
          icon: const Icon(Icons.more_horiz, size: 18, color: kMutedColor),
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
