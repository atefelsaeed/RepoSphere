import 'package:repo_sphere/core/git/git_provider_type.dart';
import 'package:repo_sphere/features/auth/domain/git_connection.dart';
import 'package:repo_sphere/features/repos/domain/entities/inbox_item_entity.dart';
import 'package:repo_sphere/features/repos/domain/entities/item_detail_entity.dart';
import 'package:repo_sphere/features/repos/domain/repositories/git_provider.dart';

const ghConn = GitConnection(
    id: 'gh', type: GitProviderType.github, accountLogin: 'maya', token: 't');
const glConn = GitConnection(
    id: 'gl', type: GitProviderType.gitlab, accountLogin: 'maya', token: 't');

InboxItem item(
  GitConnection c,
  int n,
  String title,
  List<InboxReason> reasons, {
  String repo = 'acme/app',
  bool pr = true,
}) =>
    InboxItem(
      connectionId: c.id,
      provider: c.type,
      accountLogin: c.accountLogin,
      kind: pr ? InboxItemKind.pullRequest : InboxItemKind.issue,
      repoFullName: repo,
      number: n,
      title: title,
      htmlUrl: 'https://example.com/$repo/$n',
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      reasons: reasons,
    );

/// Scriptable in-memory [GitProvider]; anything not overridden throws.
class FakeProvider implements GitProvider {
  @override
  final GitConnection connection;
  @override
  final ProviderCapabilities capabilities;

  /// Throw this from getInboxItems when set.
  Object? inboxError;
  List<InboxItem> items;
  InboxBatch Function()? batch;
  ItemDetail? detail;
  Object? detailError;
  final actions = <String>[];

  FakeProvider(
    this.connection, {
    this.items = const [],
    this.capabilities = const ProviderCapabilities(inbox: true),
    this.detail,
  });

  @override
  GitProviderType get type => connection.type;

  @override
  Future<InboxBatch> getInboxItems() async {
    if (inboxError != null) throw inboxError!;
    return batch?.call() ?? InboxBatch(items);
  }

  @override
  Future<ItemDetail> getItemDetail(InboxItem item) async {
    if (detailError != null) throw detailError!;
    return detail!;
  }

  @override
  Future<void> performPrAction(InboxItem item, PrAction action,
      {String? comment}) async {
    actions.add('${action.name}:${item.number}');
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnsupportedError('${i.memberName}');
}
