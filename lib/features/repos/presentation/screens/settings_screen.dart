import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../auth/data/secure_token_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/gitlab_remote_datasource.dart';
import '../providers/repos_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _gitlabTokenCtrl = TextEditingController();
  bool _gitlabObscure = true;
  bool _verifying = false;
  String? _gitlabError;

  @override
  void dispose() {
    _gitlabTokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _connectGitLab() async {
    final token = _gitlabTokenCtrl.text.trim();
    if (token.isEmpty) return;
    setState(() {
      _verifying = true;
      _gitlabError = null;
    });
    try {
      final ds = GitLabRemoteDatasource(client: http.Client(), token: token);
      await ds.verifyToken();
      await SecureTokenStorage.writeGitLabToken(token);
      ref.invalidate(gitlabDatasourceProvider);
      ref.invalidate(gitlabConnectedUserProvider);
      ref.invalidate(gitlabReposProvider);
      ref.invalidate(allReposProvider);
      _gitlabTokenCtrl.clear();
    } catch (_) {
      setState(() => _gitlabError = 'Invalid token. Check scopes and try again.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _disconnectGitLab() async {
    await SecureTokenStorage.deleteGitLabToken();
    ref.invalidate(gitlabDatasourceProvider);
    ref.invalidate(gitlabConnectedUserProvider);
    ref.invalidate(gitlabReposProvider);
    ref.invalidate(allReposProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final gitlabUser = ref.watch(gitlabConnectedUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ── Connected Providers ──────────────────────────────────
              _SectionHeader(label: 'Connected Providers', icon: Icons.link_rounded),
              const SizedBox(height: 12),

              // GitHub card
              _ProviderCard(
                color: cs.primary,
                icon: Icons.hub_rounded,
                name: 'GitHub',
                child: user != null
                    ? _ConnectedRow(
                        avatarUrl: user.avatarUrl,
                        login: user.login,
                        onDisconnect: () async {
                          final ok = await _confirmDisconnect(
                              context, 'GitHub',
                              'This will log you out of RepoSphere.');
                          if (ok) ref.read(authProvider.notifier).logout();
                        },
                      )
                    : _DisconnectedRow(label: 'Not connected'),
              ),

              const SizedBox(height: 12),

              // GitLab card
              _ProviderCard(
                color: const Color(0xFFFC6D26),
                icon: Icons.code_rounded,
                name: 'GitLab',
                child: gitlabUser.when(
                  data: (username) => username != null
                      ? _ConnectedRow(
                          login: username,
                          onDisconnect: () async {
                            final ok = await _confirmDisconnect(
                                context, 'GitLab',
                                'Your GitLab repos will be removed from the list.');
                            if (ok) _disconnectGitLab();
                          },
                        )
                      : _GitLabConnectForm(
                          controller: _gitlabTokenCtrl,
                          obscure: _gitlabObscure,
                          verifying: _verifying,
                          error: _gitlabError,
                          onToggleObscure: () =>
                              setState(() => _gitlabObscure = !_gitlabObscure),
                          onConnect: _connectGitLab,
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                  error: (_, __) => _GitLabConnectForm(
                    controller: _gitlabTokenCtrl,
                    obscure: _gitlabObscure,
                    verifying: _verifying,
                    error: _gitlabError,
                    onToggleObscure: () =>
                        setState(() => _gitlabObscure = !_gitlabObscure),
                    onConnect: _connectGitLab,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Appearance ───────────────────────────────────────────
              _SectionHeader(label: 'Appearance', icon: Icons.palette_outlined),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                  color: cs.surface,
                ),
                child: ListTile(
                  leading: Icon(_themeModeIcon(themeMode),
                      color: cs.primary),
                  title: const Text('Theme'),
                  subtitle: Text(_themeModeLabel(themeMode),
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded, size: 16)),
                      ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded, size: 16)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded, size: 16)),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (s) async {
                      final next = s.first;
                      ref.read(themeModeProvider.notifier).state = next;
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setString('themeMode', next.name);
                    },
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── About ────────────────────────────────────────────────
              _SectionHeader(label: 'About', icon: Icons.info_outline_rounded),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                  color: cs.surface,
                ),
                child: Column(
                  children: [
                    _AboutRow(label: 'App', value: 'RepoSphere'),
                    const Divider(height: 20),
                    _AboutRow(label: 'Version', value: '1.0.0-alpha'),
                    const Divider(height: 20),
                    _AboutRow(label: 'Built with', value: 'Flutter + Riverpod'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDisconnect(
      BuildContext context, String provider, String subtitle) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Disconnect $provider'),
            content: Text(subtitle),
            actions: [
              TextButton(
                  onPressed: () => ctx.pop(false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => ctx.pop(true),
                  child: const Text('Disconnect')),
            ],
          ),
        ) ??
        false;
  }

  IconData _themeModeIcon(ThemeMode m) => switch (m) {
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
        _ => Icons.brightness_auto_rounded,
      };

  String _themeModeLabel(ThemeMode m) => switch (m) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        _ => 'System default',
      };
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String name;
  final Widget child;
  const _ProviderCard(
      {required this.color,
      required this.icon,
      required this.name,
      required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: cs.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: color.withAlpha(60), width: 0.5),
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                const SizedBox(width: 10),
                Text(name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ConnectedRow extends StatelessWidget {
  final String? avatarUrl;
  final String login;
  final VoidCallback onDisconnect;
  const _ConnectedRow(
      {this.avatarUrl, required this.login, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (avatarUrl != null) ...[
          CircleAvatar(
              radius: 14, backgroundImage: NetworkImage(avatarUrl!)),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('@$login',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 12, color: const Color(0xFF3FB950)),
                  const SizedBox(width: 4),
                  Text('Connected',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: const Color(0xFF3FB950))),
                ],
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onDisconnect,
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.error,
            side: BorderSide(color: cs.error.withAlpha(80)),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text('Disconnect'),
        ),
      ],
    );
  }
}

class _DisconnectedRow extends StatelessWidget {
  final String label;
  const _DisconnectedRow({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.radio_button_unchecked_rounded,
            size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _GitLabConnectForm extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final bool verifying;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onConnect;

  const _GitLabConnectForm({
    required this.controller,
    required this.obscure,
    required this.verifying,
    required this.error,
    required this.onToggleObscure,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: 'glpat-xxxxxxxxxxxxxxxxxxxx',
            labelText: 'Personal Access Token',
            helperText: 'Required scopes: api, read_user',
            suffixIcon: IconButton(
              icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: onToggleObscure,
            ),
          ),
          onSubmitted: (_) => onConnect(),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 14, color: cs.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(error!,
                    style: TextStyle(
                        fontSize: 12, color: cs.error)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: verifying ? null : onConnect,
          icon: verifying
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.link_rounded, size: 16),
          label: Text(verifying ? 'Verifying…' : 'Connect GitLab'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFC6D26),
          ),
        ),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant)),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
