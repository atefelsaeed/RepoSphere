import 'package:flutter/material.dart';
import '../../core/utils/exceptions.dart';
import '../../l10n/l10n.dart';

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.error, this.onRetry});

  /// Convenience: build from a raw string (legacy call sites).
  const ErrorView.message(String message, {super.key, this.onRetry})
      : error = message;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (icon, color, message) = _resolve(error, cs, context.l10n);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static (IconData, Color, String) _resolve(
      Object error, ColorScheme cs, AppLocalizations l) {
    if (error is GitHubAuthException) {
      return (
        Icons.lock_outline_rounded,
        cs.error,
        translateErrorMessage(l, error.message),
      );
    }
    if (error is GitHubRateLimitException) {
      return (
        Icons.hourglass_empty_rounded,
        const Color(0xFFF59E0B),
        translateErrorMessage(l, error.message),
      );
    }
    if (error is GitHubApiException) {
      return (
        Icons.cloud_off_rounded,
        cs.onSurfaceVariant,
        translateErrorMessage(l, error.message),
      );
    }
    // Raw string or unknown — strip "Exception: " prefix if present
    final msg = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('GitHubAuthException: ', '')
        .replaceFirst('GitHubApiException: ', '')
        .replaceFirst('GitHubRateLimitException: ', '');

    return (Icons.error_outline_rounded, cs.error, msg);
  }
}
