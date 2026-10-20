import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/core/git/git_provider_type.dart';
import 'package:repo_sphere/features/repos/domain/entities/inbox_item_entity.dart';
import 'package:repo_sphere/features/repos/domain/entities/workspace_entity.dart';

InboxItem _item(String conn, String repo) => InboxItem(
      connectionId: conn,
      provider: GitProviderType.github,
      accountLogin: 'me',
      kind: InboxItemKind.pullRequest,
      repoFullName: repo,
      number: 1,
      title: 't',
      htmlUrl: 'u',
      updatedAt: DateTime(2024),
      reasons: const [InboxReason.assigned],
    );

void main() {
  const personal = Workspace(
      id: 'p', name: 'Personal', color: 1, rules: [WorkspaceRule('gh')]);
  const acme = Workspace(
      id: 'a',
      name: 'Acme',
      color: 2,
      rules: [WorkspaceRule('gh', 'acme-corp'), WorkspaceRule('gl')]);

  test('namespace rule beats whole-account rule regardless of order', () {
    final item = _item('gh', 'acme-corp/site');
    expect(Workspace.resolve([personal, acme], item)?.id, 'a');
    expect(Workspace.resolve([acme, personal], item)?.id, 'a');
  });

  test('falls back to the account-wide workspace', () {
    expect(Workspace.resolve([personal, acme], _item('gh', 'me/app'))?.id, 'p');
  });

  test('namespace match is case-insensitive and needs a full segment', () {
    expect(
        Workspace.resolve([acme], _item('gh', 'ACME-CORP/x'))?.id, 'a');
    expect(Workspace.resolve([acme], _item('gh', 'acme-corp-labs/x')), isNull);
  });

  test('whole GitLab account (nested groups) and unassigned', () {
    expect(Workspace.resolve([acme], _item('gl', 'g/sub/proj'))?.id, 'a');
    expect(Workspace.resolve([acme], _item('other', 'x/y')), isNull);
  });

  test('JSON round-trips', () {
    final back = Workspace.fromJson(acme.toJson());
    expect(back.name, 'Acme');
    expect(back.rules.length, 2);
    expect(back.rules.first.namespace, 'acme-corp');
    expect(back.rules.last.namespace, isNull);
  });
}
