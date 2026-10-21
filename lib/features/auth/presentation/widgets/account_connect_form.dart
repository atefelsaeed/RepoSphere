import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/git/git_provider_type.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../repos/data/datasources/azure_remote_datasource.dart';
import '../../../repos/data/datasources/github_remote_datasource.dart';
import '../../../repos/data/datasources/gitlab_remote_datasource.dart';
import '../../data/secure_token_storage.dart';
import '../../domain/git_connection.dart';

/// Brand colour and icon for a provider, shared by the account list and the
/// connect form.
({Color color, IconData icon}) providerStyle(GitProviderType t) => switch (t) {
      GitProviderType.github =>
        (color: const Color(0xFF6E7681), icon: Icons.hub_rounded),
      GitProviderType.gitlab =>
        (color: const Color(0xFFFC6D26), icon: Icons.code_rounded),
      GitProviderType.azureDevOps =>
        (color: const Color(0xFF0078D4), icon: Icons.cloud_rounded),
      GitProviderType.bitbucket =>
        (color: const Color(0xFF2684FF), icon: Icons.merge_type_rounded),
      GitProviderType.gitea =>
        (color: const Color(0xFF609926), icon: Icons.coffee_rounded),
    };

/// Cleans a user-typed instance/organisation URL: trims, adds `https://` when
/// there is no scheme, and drops trailing slashes. Empty stays empty.
String normalizeInstanceUrl(String input) {
  var s = input.trim();
  if (s.isEmpty) return '';
  if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(s)) s = 'https://$s';
  return s.replaceAll(RegExp(r'/+$'), '');
}

/// Where to create a token for [type], and which scopes it needs.
({Uri url, String scopes}) tokenHelp(GitProviderType type, String baseUrl) {
  switch (type) {
    case GitProviderType.gitlab:
      final base = baseUrl.isEmpty ? 'https://gitlab.com' : baseUrl;
      return (
        url: Uri.parse(
            '$base/-/user_settings/personal_access_tokens?name=RepoSphere&scopes=api,read_user'),
        scopes: 'api, read_user',
      );
    case GitProviderType.azureDevOps:
      return (
        url: Uri.parse(baseUrl.isEmpty
            ? 'https://dev.azure.com'
            : '$baseUrl/_usersSettings/tokens'),
        scopes: 'Code (read), Work Items (read)',
      );
    default:
      return (
        url: Uri.parse(
            'https://github.com/settings/tokens/new?scopes=repo,read:user,notifications,gist&description=RepoSphere'),
        scopes: 'repo, read:user, notifications, gist',
      );
  }
}

/// Provider picker + URL/token fields that verifies the token and hands back a
/// ready [GitConnection]. Used on the login screen and in Settings.
class AccountConnectForm extends StatefulWidget {
  /// Persists the verified connection.
  final Future<void> Function(GitConnection) onConnect;

  /// Called after [onConnect] succeeds (e.g. to close a sheet).
  final VoidCallback? onConnected;

  final GitProviderType initialType;

  const AccountConnectForm({
    super.key,
    required this.onConnect,
    this.onConnected,
    this.initialType = GitProviderType.github,
  });

  @override
  State<AccountConnectForm> createState() => _AccountConnectFormState();
}

class _AccountConnectFormState extends State<AccountConnectForm> {
  late GitProviderType _type = widget.initialType;
  final _tokenCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
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
    _urlCtrl.dispose();
    super.dispose();
  }

  bool get _urlRequired => _type == GitProviderType.azureDevOps;
  bool get _urlVisible =>
      _type == GitProviderType.gitlab || _type == GitProviderType.azureDevOps;

  String get _urlLabel => _type == GitProviderType.azureDevOps
      ? 'Organisation URL (https://dev.azure.com/your-org)'
      : 'Self-hosted GitLab URL (optional)';

  String get _tokenHint => switch (_type) {
        GitProviderType.github => 'ghp_xxxxxxxx',
        GitProviderType.gitlab => 'glpat-xxxxxxxx',
        GitProviderType.azureDevOps => 'Azure DevOps PAT',
        _ => 'Personal Access Token',
      };

  Future<void> _connect() async {
    final token = _tokenCtrl.text.trim();
    final url = _urlVisible ? normalizeInstanceUrl(_urlCtrl.text) : '';
    if (token.isEmpty) {
      setState(() => _error = 'Enter a token.');
      return;
    }
    if (_urlRequired && url.isEmpty) {
      setState(() => _error = 'Azure DevOps needs an organisation URL.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final client = http.Client();
    try {
      final connection = await _verify(client, token, url);
      await widget.onConnect(connection);
      if (mounted) widget.onConnected?.call();
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
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
    if (e is GitHubAuthException) {
      return 'Invalid token. Check the value and its scopes.';
    }
    if (e is GitHubRateLimitException) return e.message;
    final s = e.toString();
    if (s.contains('401') || s.contains('Invalid')) {
      return 'Invalid token. Check the value and its scopes.';
    }
    return _urlVisible
        ? 'Could not connect. Check the token and the URL.'
        : 'Could not connect. Check the token and your internet connection.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final help = tokenHelp(
        _type, _urlVisible ? normalizeInstanceUrl(_urlCtrl.text) : '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _selectable.map((t) {
            final style = providerStyle(t);
            final selected = t == _type;
            return ChoiceChip(
              avatar: Icon(style.icon,
                  size: 16, color: selected ? Colors.white : style.color),
              label: Text(t.label),
              selected: selected,
              showCheckmark: false,
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
        if (_urlVisible) ...[
          TextField(
            controller: _urlCtrl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            onChanged: (_) => setState(() {}), // refresh the token link
            decoration: InputDecoration(
              labelText: _urlLabel,
              hintText: _type == GitProviderType.gitlab
                  ? 'Empty = gitlab.com'
                  : 'https://dev.azure.com/your-org',
              prefixIcon: const Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _tokenCtrl,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Personal Access Token',
            hintText: _tokenHint,
            prefixIcon: const Icon(Icons.key_rounded),
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Show token' : 'Hide token',
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
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () =>
              launchUrl(help.url, mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: Text('Create a token on ${_type.label}'),
        ),
        Text(
          'Needs: ${help.scopes}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
