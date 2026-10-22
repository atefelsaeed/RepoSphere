import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/git/git_provider_type.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../repos/data/datasources/azure_remote_datasource.dart';
import '../../../repos/data/datasources/github_remote_datasource.dart';
import '../../../repos/data/datasources/gitlab_remote_datasource.dart';
import '../../../repos/data/datasources/gitea_remote_datasource.dart';
import '../../data/secure_token_storage.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/git_connection.dart';
import '../../../../core/utils/external_link.dart';

/// Brand colour and icon for a provider, shared by the account list and the
/// connect form.
({Color color, IconData icon}) providerStyle(GitProviderType t) => switch (t) {
      GitProviderType.github => (
          color: const Color(0xFF6E7681),
          icon: Icons.hub_rounded
        ),
      GitProviderType.gitlab => (
          color: const Color(0xFFFC6D26),
          icon: Icons.code_rounded
        ),
      GitProviderType.azureDevOps => (
          color: const Color(0xFF0078D4),
          icon: Icons.cloud_rounded
        ),
      GitProviderType.bitbucket => (
          color: const Color(0xFF2684FF),
          icon: Icons.merge_type_rounded
        ),
      GitProviderType.gitea => (
          color: const Color(0xFF609926),
          icon: Icons.coffee_rounded
        ),
    };

/// Cleans a user-typed instance/organisation URL: trims, adds `https://` when
/// there is no scheme, and drops trailing slashes. Empty stays empty.
String normalizeInstanceUrl(String input) {
  var s = input.trim();
  if (s.isEmpty) return '';
  if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(s)) s = 'https://$s';
  return s.replaceAll(RegExp(r'/+$'), '');
}

/// True when [url] is plain `http://` to a host that is not on this machine or
/// a private network. A token sent there crosses the internet unencrypted.
bool isInsecureInstanceUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme.toLowerCase() != 'http') return false;
  final host = uri.host.toLowerCase();
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local') ||
      host.endsWith('.lan') ||
      host == '::1') {
    return false;
  }
  final m = RegExp(r'^(\d+)\.(\d+)\.\d+\.\d+$').firstMatch(host);
  if (m == null) return true;
  final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!);
  final private = a == 10 ||
      a == 127 ||
      (a == 192 && b == 168) ||
      (a == 172 && b >= 16 && b <= 31);
  return !private;
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
    case GitProviderType.gitea:
      return (
        url: Uri.parse(baseUrl.isEmpty
            ? 'https://codeberg.org/user/settings/applications'
            : '$baseUrl/user/settings/applications'),
        scopes: 'read:user, read:repository, write:repository, write:issue',
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
    GitProviderType.gitea,
  ];

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  bool get _urlRequired =>
      _type == GitProviderType.azureDevOps || _type == GitProviderType.gitea;
  bool get _urlVisible =>
      _type == GitProviderType.gitlab || _urlRequired;

  String _urlLabel(AppLocalizations l) => switch (_type) {
        GitProviderType.azureDevOps => l.connectAzureUrlLabel,
        GitProviderType.gitea => l.connectGiteaUrlLabel,
        _ => l.connectGitlabUrlLabel,
      };

  String _tokenHint(AppLocalizations l) => switch (_type) {
        GitProviderType.github => 'ghp_xxxxxxxx',
        GitProviderType.gitlab => 'glpat-xxxxxxxx',
        GitProviderType.azureDevOps => 'Azure DevOps PAT',
        GitProviderType.gitea => 'Forgejo / Gitea token',
        _ => l.tokenLabel,
      };

  Future<void> _connect() async {
    final l = context.l10n;
    final token = _tokenCtrl.text.trim();
    final url = _urlVisible ? normalizeInstanceUrl(_urlCtrl.text) : '';
    if (token.isEmpty) {
      setState(() => _error = l.enterToken);
      return;
    }
    if (_urlRequired && url.isEmpty) {
      setState(() => _error = _type == GitProviderType.gitea
          ? l.giteaNeedsUrl
          : l.azureNeedsOrg);
      return;
    }
    if (isInsecureInstanceUrl(url)) {
      setState(() => _error = l.insecureInstanceUrl);
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
      if (mounted) setState(() => _error = _friendly(e, l));
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
        final user = (await GitHubRemoteDatasource(client: client, token: token)
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
        final u =
            data['authenticatedUser'] as Map<String, dynamic>? ?? const {};
        return GitConnection(
          id: id,
          type: GitProviderType.azureDevOps,
          accountLogin: (u['providerDisplayName'] as String?) ?? 'azure',
          token: token,
          baseUrl: baseUrl,
        );
      case GitProviderType.gitea:
        final login = await GiteaRemoteDatasource(
                client: client, token: token, baseUrl: baseUrl)
            .verifyToken();
        return GitConnection(
          id: id,
          type: GitProviderType.gitea,
          accountLogin: login,
          token: token,
          baseUrl: baseUrl,
        );
      default:
        throw Exception('Unsupported provider');
    }
  }

  String _friendly(Object e, AppLocalizations l) {
    if (e is GitHubAuthException) return l.invalidToken;
    if (e is GitHubRateLimitException) return translateErrorMessage(l, e.message);
    final s = e.toString();
    if (s.contains('401') || s.contains('Invalid')) return l.invalidToken;
    return _urlVisible ? l.couldNotConnectUrl : l.couldNotConnectNet;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = context.l10n;
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
              labelText: _urlLabel(l),
              hintText: _type == GitProviderType.gitlab
                  ? l.connectGitlabUrlHint
                  : _type == GitProviderType.gitea
                      ? 'https://codeberg.org'
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
            labelText: l.tokenLabel,
            hintText: _tokenHint(l),
            prefixIcon: const Icon(Icons.key_rounded),
            suffixIcon: IconButton(
              tooltip: _obscure ? l.showToken : l.hideToken,
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
          label: Text(_busy ? l.connecting : l.connect),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => openExternalLink(help.url.toString()),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: Text(l.createTokenOn(_type.label)),
        ),
        Text(
          l.needsScopes(help.scopes),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
