import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/git/git_provider_type.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../auth/data/secure_token_storage.dart';
import '../../../auth/domain/git_connection.dart';
import '../../../auth/presentation/providers/connections_provider.dart';
import '../../data/datasources/azure_remote_datasource.dart';
import '../../data/datasources/github_remote_datasource.dart';
import '../../data/datasources/gitlab_remote_datasource.dart';
import '../providers/repos_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final connections = ref.watch(connectionsProvider).valueOrNull ?? const [];

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
              // ── Connected accounts ───────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _SectionHeader(
                        label: 'Connected Accounts',
                        icon: Icons.link_rounded),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddAccount(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add account'),
                    style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (connections.isEmpty)
                _EmptyConnections()
              else
                ...connections.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ConnectionTile(
                        connection: c,
                        onRemove: () async {
                          final ok = await _confirmRemove(context, c);
                          if (ok) {
                            await ref
                                .read(connectionsProvider.notifier)
                                .remove(c.id);
                            ref.invalidate(allReposProvider);
                          }
                        },
                      ),
                    )),

              const SizedBox(height: 32),

              // ── Appearance ───────────────────────────────────────────
              _SectionHeader(
                  label: 'Appearance', icon: Icons.palette_outlined),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                  color: cs.surface,
                ),
                child: ListTile(
                  leading: Icon(_themeModeIcon(themeMode), color: cs.primary),
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
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── About ────────────────────────────────────────────────
              _SectionHeader(
                  label: 'About', icon: Icons.info_outline_rounded),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                  color: cs.surface,
                ),
                child: Column(
                  children: const [
                    _AboutRow(label: 'App', value: 'RepoSphere'),
                    Divider(height: 20),
                    _AboutRow(label: 'Version', value: '1.0.0-alpha'),
                    Divider(height: 20),
                    _AboutRow(
                        label: 'Providers',
                        value: 'GitHub · GitLab · Azure DevOps'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddAccount(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _AddAccountSheet(
          onConnect: (conn) async {
            await ref.read(connectionsProvider.notifier).add(conn);
            ref.invalidate(allReposProvider);
          },
        ),
      ),
    );
  }

  Future<bool> _confirmRemove(BuildContext context, GitConnection c) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Remove ${c.type.label}'),
            content: Text(
                'Disconnect ${c.displayName}? Its repos will be removed from the list.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Remove')),
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

// ─── Provider visuals ─────────────────────────────────────────────────────────

({Color color, IconData icon}) _providerStyle(GitProviderType t) => switch (t) {
      GitProviderType.github => (color: const Color(0xFF6E7681), icon: Icons.hub_rounded),
      GitProviderType.gitlab => (color: const Color(0xFFFC6D26), icon: Icons.code_rounded),
      GitProviderType.azureDevOps =>
        (color: const Color(0xFF0078D4), icon: Icons.cloud_rounded),
      GitProviderType.bitbucket =>
        (color: const Color(0xFF2684FF), icon: Icons.merge_type_rounded),
      GitProviderType.gitea => (color: const Color(0xFF609926), icon: Icons.coffee_rounded),
    };

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ConnectionTile extends StatelessWidget {
  final GitConnection connection;
  final VoidCallback onRemove;
  const _ConnectionTile({required this.connection, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = _providerStyle(connection.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: cs.surface,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: style.color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(style.icon, size: 17, color: style.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(connection.type.label,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text('@${connection.accountLogin}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant)),
                if (connection.baseUrl != null &&
                    connection.baseUrl!.isNotEmpty)
                  Text(connection.baseUrl!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline_rounded, color: cs.error),
          ),
        ],
      ),
    );
  }
}

class _EmptyConnections extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: cs.surface,
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text('No accounts connected. Tap "Add account" to connect.',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _AddAccountSheet extends StatefulWidget {
  final Future<void> Function(GitConnection) onConnect;
  const _AddAccountSheet({required this.onConnect});

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  GitProviderType _type = GitProviderType.github;
  final _tokenCtrl = TextEditingController();
  final _baseUrlCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  static const _selectable = [
    GitProviderType.github,
    GitProviderType.gitlab,
    GitProviderType.azureDevOps,
  ];

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _baseUrlCtrl.dispose();
    super.dispose();
  }

  String get _baseUrlLabel => _type == GitProviderType.azureDevOps
      ? 'Organisation URL (https://dev.azure.com/your-org)'
      : 'Instance URL (https://gitlab.example.com)';

  String get _tokenHint => switch (_type) {
        GitProviderType.github => 'ghp_xxxxxxxx',
        GitProviderType.gitlab => 'glpat-xxxxxxxx',
        GitProviderType.azureDevOps => 'Azure DevOps PAT',
        _ => 'Personal Access Token',
      };

  Future<void> _connect() async {
    final token = _tokenCtrl.text.trim();
    final baseUrl = _baseUrlCtrl.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Enter a token.');
      return;
    }
    if (_type == GitProviderType.azureDevOps && baseUrl.isEmpty) {
      setState(() => _error = 'Azure DevOps needs an organisation URL.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final client = http.Client();
    try {
      final connection = await _verify(client, token, baseUrl);
      await widget.onConnect(connection);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = _friendly(e));
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<GitConnection> _verify(
      http.Client client, String token, String baseUrl) async {
    final id = SecureTokenStorage.newConnectionId();
    switch (_type) {
      case GitProviderType.github:
        final user =
            (await GitHubRemoteDatasource(client: client, token: token)
                    .getUser())
                .toEntity();
        return GitConnection(
          id: id,
          type: GitProviderType.github,
          accountLogin: user.login,
          avatarUrl: user.avatarUrl,
          token: token,
        );
      case GitProviderType.gitlab:
        final username = await GitLabRemoteDatasource(
                client: client,
                token: token,
                baseUrl: baseUrl.isEmpty ? null : baseUrl)
            .verifyToken();
        return GitConnection(
          id: id,
          type: GitProviderType.gitlab,
          accountLogin: username,
          token: token,
          baseUrl: baseUrl.isEmpty ? null : baseUrl,
        );
      case GitProviderType.azureDevOps:
        final data = await AzureRemoteDatasource(
                client: client, pat: token, orgUrl: baseUrl)
            .getConnectionData();
        final u = data['authenticatedUser'] as Map<String, dynamic>? ?? const {};
        return GitConnection(
          id: id,
          type: GitProviderType.azureDevOps,
          accountLogin: (u['providerDisplayName'] as String?) ?? 'azure',
          token: token,
          baseUrl: baseUrl,
        );
      default:
        throw Exception('Unsupported provider');
    }
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('Auth') || s.contains('Invalid') || s.contains('401')) {
      return 'Invalid token. Check the value and scopes.';
    }
    return 'Could not connect. Check the token and URL.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final needsBaseUrl = _type.requiresBaseUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Connect an account',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _selectable.map((t) {
              final style = _providerStyle(t);
              final selected = t == _type;
              return ChoiceChip(
                avatar: Icon(style.icon,
                    size: 16,
                    color: selected ? Colors.white : style.color),
                label: Text(t.label),
                selected: selected,
                selectedColor: style.color,
                labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: FontWeight.w600),
                onSelected: (_) => setState(() {
                  _type = t;
                  _error = null;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (needsBaseUrl) ...[
            TextField(
              controller: _baseUrlCtrl,
              decoration: InputDecoration(
                labelText: _baseUrlLabel,
                prefixIcon: const Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _tokenCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Personal Access Token',
              hintText: _tokenHint,
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _connect(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: cs.error),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(_error!,
                        style: TextStyle(color: cs.error, fontSize: 13))),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _connect,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.link_rounded, size: 16),
            label: Text(_busy ? 'Connecting…' : 'Connect'),
          ),
        ],
      ),
    );
  }
}

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
