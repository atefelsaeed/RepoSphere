import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/entities/commit_entity.dart';
import '../../../../core/utils/external_link.dart';

class CommitTile extends StatefulWidget {
  final CommitEntity commit;
  final VoidCallback? onTap;
  const CommitTile({super.key, required this.commit, this.onTap});

  @override
  State<CommitTile> createState() => _CommitTileState();
}

class _CommitTileState extends State<CommitTile> {
  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copySha() async {
    await Clipboard.setData(ClipboardData(text: widget.commit.sha));
    if (!mounted) return;
    setState(() => _copied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: cs.surfaceContainerHighest,
            backgroundImage: widget.commit.authorAvatarUrl != null
                ? NetworkImage(widget.commit.authorAvatarUrl!)
                : null,
            child: widget.commit.authorAvatarUrl == null
                ? Text(
                    widget.commit.authorName.isNotEmpty
                        ? widget.commit.authorName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.labelSmall,
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Message + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.onTap ??
                      () => openExternalLink(widget.commit.htmlUrl),
                  child: Text(
                    widget.commit.firstLine,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      widget.commit.authorLogin ?? widget.commit.authorName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' committed ${timeago.format(widget.commit.date)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // SHA chip — tap to copy with checkmark feedback
          Tooltip(
            message: _copied ? 'Copied!' : 'Copy full SHA',
            child: GestureDetector(
              onTap: _copySha,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _copied
                      ? const Color(0xFF3FB950).withAlpha(20)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _copied
                        ? const Color(0xFF3FB950).withAlpha(120)
                        : cs.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _copied
                            ? Icons.check_rounded
                            : Icons.commit_rounded,
                        key: ValueKey(_copied),
                        size: 12,
                        color: _copied
                            ? const Color(0xFF3FB950)
                            : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.commit.shortSha,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: _copied
                            ? const Color(0xFF3FB950)
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
