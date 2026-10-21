import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/git_connection.dart';
import '../../../auth/presentation/providers/connections_provider.dart';
import '../../domain/entities/workspace_entity.dart';
import '../providers/inbox_provider.dart';
import '../providers/workspaces_provider.dart';

const _palette = <int>[
  0xFF3B82F6,
  0xFF10B981,
  0xFFF59E0B,
  0xFFEF4444,
  0xFF8B5CF6,
  0xFFEC4899,
  0xFF14B8A6,
  0xFF6B7280,
];

/// Manage client workspaces: each groups whole accounts and/or specific
/// orgs/groups from any provider.
class WorkspacesScreen extends ConsumerWidget {
  const WorkspacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final workspaces = ref.watch(workspacesProvider);
    final connections = ref.watch(connectionsProvider).valueOrNull ?? const [];
    final byId = {for (final c in connections) c.id: c};

    return Scaffold(
      appBar: AppBar(title: const Text('Workspaces')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New workspace'),
      ),
      body: workspaces.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.business_center_outlined,
                        size: 56, color: cs.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text('Group your work by client',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'A workspace combines accounts and orgs from GitHub, '
                      'GitLab or Azure DevOps under one client name, so your '
                      'Inbox can show one client at a time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: workspaces.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (_, i) {
                final w = workspaces[i];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(w.color),
                    child: Text(
                      w.name.isEmpty ? '?' : w.name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(w.name),
                  subtitle: Text(
                    w.rules.isEmpty
                        ? 'No accounts yet'
                        : w.rules.map((r) {
                            final c = byId[r.connectionId];
                            final who = c?.displayName ?? 'Removed account';
                            return r.isSpecific ? '$who / ${r.namespace}' : who;
                          }).join('  ·  '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _edit(context, w),
                );
              },
            ),
    );
  }

  void _edit(BuildContext context, Workspace? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _WorkspaceEditor(existing: existing),
      ),
    );
  }
}

class _WorkspaceEditor extends ConsumerStatefulWidget {
  final Workspace? existing;
  const _WorkspaceEditor({this.existing});

  @override
  ConsumerState<_WorkspaceEditor> createState() => _WorkspaceEditorState();
}

class _EditableRule {
  String? connectionId;
  final TextEditingController namespace;
  _EditableRule(this.connectionId, String? ns)
      : namespace = TextEditingController(text: ns ?? '');
}

class _WorkspaceEditorState extends ConsumerState<_WorkspaceEditor> {
  late final TextEditingController _name;
  late int _color;
  late final List<_EditableRule> _rules;

  @override
  void initState() {
    super.initState();
    final w = widget.existing;
    _name = TextEditingController(text: w?.name ?? '');
    _color = w?.color ?? _palette.first;
    _rules = [
      for (final r in w?.rules ?? const <WorkspaceRule>[])
        _EditableRule(r.connectionId, r.namespace),
    ];
  }

  @override
  void dispose() {
    _name.dispose();
    for (final r in _rules) {
      r.namespace.dispose();
    }
    super.dispose();
  }

  /// Owners/orgs already seen in the inbox for [connectionId] — one-tap hints.
  List<String> _suggestions(String? connectionId) {
    if (connectionId == null) return const [];
    final items = ref.read(inboxProvider).valueOrNull?.items ?? const [];
    return items
        .where((i) => i.connectionId == connectionId)
        .map((i) => i.repoFullName.split('/').first)
        .where((s) => s.isNotEmpty)
        .toSet()
        .take(6)
        .toList();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final rules = <WorkspaceRule>[
      for (final r in _rules)
        if (r.connectionId != null)
          WorkspaceRule(
              r.connectionId!,
              r.namespace.text.trim().isEmpty ? null : r.namespace.text.trim()),
    ];
    final w = Workspace(
      id: widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      name: name,
      color: _color,
      rules: rules,
    );
    ref.read(workspacesProvider.notifier).upsert(w);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final connections = ref.watch(connectionsProvider).valueOrNull ?? const [];
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Client / workspace name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                for (final c in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(c),
                      child: _color == c
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Accounts & orgs',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Leave the org field empty to include the whole account.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            for (final (i, r) in _rules.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: connections.any((c) => c.id == r.connectionId)
                                ? r.connectionId
                                : null,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(labelText: 'Account'),
                            items: [
                              for (final GitConnection c in connections)
                                DropdownMenuItem(
                                    value: c.id, child: Text(c.displayName)),
                            ],
                            onChanged: (v) =>
                                setState(() => r.connectionId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: r.namespace,
                            decoration: const InputDecoration(
                                labelText: 'Org / group (optional)'),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _rules.removeAt(i).namespace.dispose();
                          }),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final s in _suggestions(r.connectionId))
                          ActionChip(
                            label: Text(s),
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                setState(() => r.namespace.text = s),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: connections.isEmpty
                  ? null
                  : () => setState(() => _rules.add(_EditableRule(
                      connections.length == 1 ? connections.first.id : null,
                      null))),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add account or org'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.existing != null)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: cs.error),
                    onPressed: () {
                      ref
                          .read(workspacesProvider.notifier)
                          .remove(widget.existing!.id);
                      if (ref.read(inboxWorkspaceFilterProvider) ==
                          widget.existing!.id) {
                        ref.read(inboxWorkspaceFilterProvider.notifier).state =
                            null;
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Delete'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _name.text.trim().isEmpty ? null : _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
