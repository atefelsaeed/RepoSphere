import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repo_sphere/core/git/git_provider_type.dart';
import 'package:repo_sphere/features/auth/domain/git_connection.dart';
import 'package:repo_sphere/features/auth/presentation/providers/connections_provider.dart';
import 'package:repo_sphere/features/repos/data/git_provider_factory.dart';
import 'package:repo_sphere/features/repos/presentation/providers/repos_provider.dart';

const _a = GitConnection(
    id: 'a', type: GitProviderType.github, accountLogin: 'alice', token: 'tok-a');
const _b = GitConnection(
    id: 'b', type: GitProviderType.github, accountLogin: 'bob', token: 'tok-b');

class _Conns extends ConnectionsNotifier {
  @override
  Future<List<GitConnection>> build() async => const [_a, _b];
}

void main() {
  late List<String?> auth;
  late ProviderContainer container;

  setUp(() async {
    auth = [];
    container = ProviderContainer(overrides: [
      connectionsProvider.overrideWith(_Conns.new),
      sharedHttpClientProvider.overrideWithValue(MockClient((req) async {
        auth.add(req.headers['Authorization']);
        return http.Response('', 404);
      })),
    ]);
    await container.read(connectionsProvider.future);
  });

  tearDown(() => container.dispose());

  test('a repo of the second GitHub account is requested with its own token',
      () async {
    await container
        .read(githubDatasourceForConnectionProvider('b'))!
        .isStarred('o', 'r');
    expect(auth, ['token tok-b']);
  });

  test('an unknown account id yields no datasource (no token borrowed)', () {
    expect(container.read(githubDatasourceForConnectionProvider('gone')),
        isNull);
  });

  test('legacy repos without a connection id use the first GitHub account',
      () async {
    await container
        .read(githubDatasourceForConnectionProvider(''))!
        .isStarred('o', 'r');
    expect(auth, ['token tok-a']);
  });
}
