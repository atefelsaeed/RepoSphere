import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/core/git/git_provider_type.dart';
import 'package:repo_sphere/features/notifications/inbox_alerts.dart';
import 'package:repo_sphere/l10n/app_localizations_ar.dart';
import 'package:repo_sphere/l10n/app_localizations_en.dart';
import 'package:repo_sphere/features/repos/domain/entities/inbox_item_entity.dart';

InboxItem _item(int n, List<InboxReason> reasons) => InboxItem(
      connectionId: 'c',
      provider: GitProviderType.github,
      accountLogin: 'me',
      kind: InboxItemKind.pullRequest,
      repoFullName: 'o/r',
      number: n,
      title: 'PR $n',
      htmlUrl: 'u',
      updatedAt: DateTime(2024),
      reasons: reasons,
    );

void main() {
  test('first run seeds without alerting', () {
    final plan = planAlerts([
      _item(1, [InboxReason.ciFailed])
    ], null);
    expect(plan.fresh, isEmpty);
    expect(plan.nextSeen, isNotEmpty);
  });

  test('alerts only for newly urgent items', () {
    final a = _item(1, [InboxReason.ciFailed]);
    final seed = planAlerts([a], null).nextSeen;

    final plan = planAlerts([
      a,
      _item(2, [InboxReason.reviewRequested])
    ], seed);

    expect(plan.fresh.map((i) => i.number), [2]);
  });

  test('assignments and mentions never alert', () {
    final plan = planAlerts([
      _item(1, [InboxReason.assigned]),
      _item(2, [InboxReason.mentioned]),
    ], <String>{});
    expect(plan.fresh, isEmpty);
    expect(plan.nextSeen, isEmpty);
  });

  test('a new urgent reason on an already-seen item alerts again', () {
    final seed = planAlerts([
      _item(1, [InboxReason.reviewRequested])
    ], null)
        .nextSeen;
    final plan = planAlerts([
      _item(1, [InboxReason.ciFailed, InboxReason.reviewRequested])
    ], seed);
    expect(plan.fresh.length, 1);
  });

  test('a fixed item that breaks again alerts again', () {
    final broken = _item(1, [InboxReason.ciFailed]);
    var seen = planAlerts([broken], null).nextSeen;
    seen = planAlerts(const [], seen).nextSeen; // fixed → forgotten
    expect(planAlerts([broken], seen).fresh.length, 1);
  });

  test('alertText summarises one item and many', () {
    final one = alertText([
      _item(1, [InboxReason.ciFailed])
    ], AppLocalizationsEn());
    expect(one.title, 'PR 1');
    expect(one.body, 'CI failed · o/r#1');

    final many = alertText([
      for (var i = 1; i <= 5; i++) _item(i, [InboxReason.reviewRequested])
    ], AppLocalizationsEn());
    expect(many.title, '5 items need your attention');
    expect(many.body.split('\n').length, 4);
    expect(many.body, endsWith('and 2 more'));
  });

  test('alertText speaks Arabic with correct plural forms', () {
    final l = AppLocalizationsAr();
    final one = alertText([
      _item(1, [InboxReason.ciFailed])
    ], l);
    expect(one.body, 'فشل CI · o/r#1');

    String title(int n) => alertText([
          for (var i = 1; i <= n; i++) _item(i, [InboxReason.reviewRequested])
        ], l)
            .title;
    expect(title(2), 'عنصران يحتاجان انتباهك');
    expect(title(5), '5 عناصر تحتاج انتباهك');
    expect(title(11), '11 عنصرًا يحتاج انتباهك');
  });
}
