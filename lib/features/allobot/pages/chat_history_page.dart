/// History — every conversation she has had with AlloBot, newest first.
///
/// Chat and Ask Allo read the same transcript, so picking one here puts it
/// back on both: the page pops, and whichever screen opened it is now showing
/// that conversation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';

class ChatHistoryPage extends StatelessWidget {
  const ChatHistoryPage({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.selectionClick();
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChatHistoryPage()));
  }

  static const Color _accent = Color(0xFFFF4E6A);

  OfflineChatbotController get _controller => OfflineChatbotController.instance;

  Future<void> _open(BuildContext context, ChatHistoryEntry entry) async {
    HapticFeedback.selectionClick();
    await _controller.openChat(entry.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _startNew(BuildContext context) async {
    HapticFeedback.selectionClick();
    await _controller.createNewChat();
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'Every past conversation with AlloBot will be removed from this phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final titleColor = p.pick(const Color(0xFF1E2024), p.textPrimary);
    return Scaffold(
      backgroundColor: p.pick(const Color(0xFFFAF6F7), p.scaffoldSoft),
      appBar: AppBar(
        backgroundColor: p.pick(const Color(0xFFFAF6F7), p.scaffoldSoft),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: titleColor, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'History',
          style: GoogleFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        actions: [
          Obx(() {
            if (_controller.history.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep_outlined, color: _accent),
              onPressed: () => _confirmClearAll(context),
            );
          }),
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.add_comment_outlined, color: _accent),
            onPressed: () => _startNew(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Obx(() {
        final entries = _controller.history.toList();
        final currentId = _controller.currentChatId.value;
        if (entries.isEmpty) return _buildEmptyState(context);

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Dismissible(
              key: ValueKey(entry.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: _accent),
              ),
              onDismissed: (_) => _controller.deleteChat(entry.id),
              child: _HistoryTile(
                entry: entry,
                isCurrent: entry.id == currentId,
                onTap: () => _open(context, entry),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: p.pick(const Color(0xFFFFF0F3), p.accentSoft),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                color: _accent,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No conversations yet',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: p.pick(const Color(0xFF1E2024), p.textPrimary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Everything you ask AlloBot, in Chat or Ask Allo, '
              'is saved here to pick up again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                height: 1.45,
                color: p.pick(const Color(0xFF8E95A5), p.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ChatHistoryEntry entry;
  final bool isCurrent;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.entry,
    required this.isCurrent,
    required this.onTap,
  });

  static const Color _accent = Color(0xFFFF4E6A);

  String _when(BuildContext context, DateTime at) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final diff = today.difference(day).inDays;
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(at));
    if (diff == 0) return time;
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[at.weekday - 1];
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final label = '${at.day} ${months[at.month - 1]}';
    return at.year == now.year ? label : '$label ${at.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? p.pick(const Color(0xFFFFD2DC), p.accentBorder)
                  : p.pick(const Color(0xFFF1ECEE), p.border),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.pick(const Color(0xFFFFF0F3), p.accentSoft),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: _accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: p.pick(
                                const Color(0xFF1E2024),
                                p.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _when(context, entry.updatedAt),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: p.pick(const Color(0xFF8E95A5), p.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: p.pick(
                                const Color(0xFF8E95A5),
                                p.textMuted,
                              ),
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: p.pick(
                                const Color(0xFFFFF0F3),
                                p.accentSoft,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Current',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
