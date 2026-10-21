import 'package:flutter/material.dart';
import '../../../../core/constants/app_version.dart';
import '../../../notifications/background_inbox_check.dart';
import '../../../notifications/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../auth/domain/git_connection.dart';
import '../../../auth/presentation/providers/connections_provider.dart';
import '../../../auth/presentation/widgets/account_connect_form.dart';
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

              // ── Notifications (mobile only) ──────────────────────────
              if (NotificationService.supported) ...[
                _SectionHeader(
                    label: 'Notifications',
                    icon: Icons.notifications_active_outlined),
                const SizedBox(height: 12),
                const _InboxAlertsCard(),
                const SizedBox(height: 32),
              ],

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
                    _AboutRow(label: 'Version', value: appVersion),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
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
                AccountConnectForm(
                  onConnect: (conn) async {
                    await ref.read(connectionsProvider.notifier).add(conn);
                    ref.invalidate(allReposProvider);
                  },
                  onConnected: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ConnectionTile extends StatelessWidget {
  final GitConnection connection;
  final VoidCallback onRemove;
  const _ConnectionTile({required this.connection, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = providerStyle(connection.type);
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


/// Toggle + "check now" for background inbox alerts.
class _InboxAlertsCard extends StatefulWidget {
  const _InboxAlertsCard();

  @override
  State<_InboxAlertsCard> createState() => _InboxAlertsCardState();
}

class _InboxAlertsCardState extends State<_InboxAlertsCard> {
  bool _enabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    inboxAlertsEnabled().then((v) {
      if (mounted) setState(() => _enabled = v);
    });
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _toggle(bool on) async {
    setState(() => _busy = true);
    try {
      final ok = await setInboxAlerts(on);
      if (!mounted) return;
      if (on && !ok) {
        _toast('Notification permission was denied. Enable it in system settings.');
      } else {
        setState(() => _enabled = on);
      }
    } on Object catch (e) {
      if (mounted) _toast('Could not change alerts: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkNow() async {
    setState(() => _busy = true);
    try {
      final n = await runInboxCheck(force: true);
      if (mounted) {
        _toast(n == 0 ? 'Checked — nothing new.' : 'Checked — $n new item(s).');
      }
    } on Object catch (e) {
      if (mounted) _toast('Check failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: cs.surface,
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _enabled,
            onChanged: _busy ? null : _toggle,
            title: const Text('Urgent inbox alerts'),
            subtitle: Text(
              'Failing CI, requested changes, conflicts and review requests. '
              'Checked in the background about every 30 minutes; iOS may '
              'run it less often.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          if (_enabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Check now'),
              enabled: !_busy,
              onTap: _checkNow,
            ),
          ],
        ],
      ),
    );
  }
}
