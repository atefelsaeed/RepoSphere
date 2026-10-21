import 'inbox_item_entity.dart';

/// Which part of a connected account belongs to a workspace.
///
/// [namespace] null → the whole account. Otherwise only repos under that
/// owner/org/group (e.g. `acme-corp`), so one GitHub login can serve several
/// clients.
class WorkspaceRule {
  final String connectionId;
  final String? namespace;
  const WorkspaceRule(this.connectionId, [this.namespace]);

  bool get isSpecific => namespace != null && namespace!.isNotEmpty;

  bool matches(InboxItem item) {
    if (item.connectionId != connectionId) return false;
    if (!isSpecific) return true;
    return item.repoFullName
        .toLowerCase()
        .startsWith('${namespace!.toLowerCase()}/');
  }

  Map<String, dynamic> toJson() =>
      {'c': connectionId, if (isSpecific) 'n': namespace};

  static WorkspaceRule fromJson(Map<String, dynamic> j) =>
      WorkspaceRule(j['c'] as String, j['n'] as String?);
}

/// A named group of accounts/orgs — typically one client.
class Workspace {
  final String id;
  final String name;

  /// ARGB colour value.
  final int color;
  final List<WorkspaceRule> rules;

  const Workspace({
    required this.id,
    required this.name,
    required this.color,
    this.rules = const [],
  });

  Workspace copyWith({String? name, int? color, List<WorkspaceRule>? rules}) =>
      Workspace(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        rules: rules ?? this.rules,
      );

  /// Strongest match for [item]: 2 = namespace rule, 1 = whole account, 0 = none.
  int matchStrength(InboxItem item) {
    var best = 0;
    for (final r in rules) {
      if (!r.matches(item)) continue;
      if (r.isSpecific) return 2;
      best = 1;
    }
    return best;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'rules': rules.map((r) => r.toJson()).toList(),
      };

  static Workspace fromJson(Map<String, dynamic> j) => Workspace(
        id: j['id'] as String,
        name: j['name'] as String,
        color: j['color'] as int,
        rules: (j['rules'] as List? ?? const [])
            .map((r) => WorkspaceRule.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  /// The workspace [item] belongs to, or null (unassigned). A namespace rule
  /// beats an account-wide rule; ties go to the earlier workspace in [all].
  static Workspace? resolve(Iterable<Workspace> all, InboxItem item) {
    Workspace? best;
    var bestStrength = 0;
    for (final w in all) {
      final s = w.matchStrength(item);
      if (s > bestStrength) {
        best = w;
        bestStrength = s;
      }
    }
    return best;
  }
}
