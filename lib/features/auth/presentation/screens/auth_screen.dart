import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_config.dart';
import '../../data/github_device_auth.dart';
import '../../domain/git_connection.dart';
import '../providers/auth_provider.dart';
import '../providers/connections_provider.dart';
import '../widgets/account_connect_form.dart';

// Auth priority:
//   1. AppConfig.hasSupabase    → Supabase GitHub OAuth (web redirect)
//   2. AppConfig.hasGitHubOAuth → GitHub Device Flow
//   3. fallback                 → Personal Access Token form

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  bool _showOtherOptions = false;
  String? _errorMessage;

  Future<void> _addConnection(GitConnection connection) =>
      ref.read(connectionsProvider.notifier).add(connection);
  // The router redirects to the Inbox once connections becomes non-empty.

  Future<void> _signInWithSupabase() async {
    final service = ref.read(supabaseAuthServiceProvider);
    if (service == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await service.signInWithGitHub();
      // On web: browser redirects — loading stays true until navigation.
      // On error the catch below resets it.
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _startDeviceFlow() async {
    final deviceAuth = ref.read(githubDeviceAuthProvider);
    if (deviceAuth == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = await deviceAuth.requestDeviceCode();
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _showDeviceFlowDialog(deviceAuth, code);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _showDeviceFlowDialog(
      GitHubDeviceAuth deviceAuth, DeviceCodeResponse code) async {
    StreamSubscription<String?>? sub;
    String? oauthError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          sub ??= deviceAuth
              .pollForToken(code.deviceCode, interval: code.interval)
              .listen(
            (token) {
              if (token != null) {
                sub?.cancel();
                if (ctx.mounted) Navigator.of(ctx).pop();
                ref.read(authProvider.notifier).saveOAuthToken(token);
              }
            },
            onError: (e) {
              sub?.cancel();
              setLocal(() =>
                  oauthError = e.toString().replaceFirst('Exception: ', ''));
            },
          );

          final theme = Theme.of(ctx);
          final cs = theme.colorScheme;

          return AlertDialog(
            title: const Text('Sign in with GitHub'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (oauthError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: cs.onErrorContainer, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(oauthError!,
                                style:
                                    TextStyle(color: cs.onErrorContainer)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text('1. Open this URL in your browser:',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(code.verificationUri),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: Text(code.verificationUri,
                          style: const TextStyle(fontFamily: 'monospace')),
                      style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                    ),
                    const SizedBox(height: 20),
                    Text('2. Enter this code:',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 10),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: code.userCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: cs.primary.withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                code.userCode,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  letterSpacing: 4,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(Icons.copy_rounded,
                                  size: 16, color: cs.onPrimaryContainer),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Waiting for authorisation…',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  sub?.cancel();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasOAuth = AppConfig.hasGitHubOAuth;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo + title
                Icon(Icons.hub_rounded, size: 56, color: cs.primary)
                    .animate()
                    .scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.4, 0.4)),
                const SizedBox(height: 16),
                Text(
                  'RepoSphere',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold),
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
                const SizedBox(height: 6),
                Text(
                  'One inbox for all your Git work.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ).animate(delay: 320.ms).fadeIn(),

                const SizedBox(height: 36),

                // ── Optional GitHub OAuth (Supabase › Device Flow) ──
                if (AppConfig.hasSupabase || hasOAuth) ...[
                  FilledButton.icon(
                    onPressed: _isLoading
                        ? null
                        : AppConfig.hasSupabase
                            ? _signInWithSupabase
                            : _startDeviceFlow,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF24292F),
                      foregroundColor: Colors.white,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.login_rounded),
                    label: const Text('Sign in with GitHub',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    _ErrorBanner(message: _errorMessage!)
                        .animate()
                        .fadeIn(duration: 200.ms),
                  TextButton(
                    onPressed: () =>
                        setState(() => _showOtherOptions = !_showOtherOptions),
                    child: Text(
                      _showOtherOptions
                          ? 'Hide other options'
                          : 'GitLab, Azure DevOps or a token',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ).animate(delay: 480.ms).fadeIn(),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    child: _showOtherOptions
                        ? Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: AccountConnectForm(
                                  onConnect: _addConnection),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ] else
                  // ── Pick a provider and connect with a token ────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: AccountConnectForm(onConnect: _addConnection),
                    ),
                  ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.06),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: cs.onErrorContainer, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: cs.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
