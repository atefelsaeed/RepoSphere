class GitHubAuthException implements Exception {
  final String message;
  const GitHubAuthException(this.message);
  @override
  String toString() => message;
}

class GitHubRateLimitException implements Exception {
  final String message;
  const GitHubRateLimitException(this.message);
  @override
  String toString() => message;
}

class GitHubApiException implements Exception {
  final String message;
  const GitHubApiException(this.message);
  @override
  String toString() => message;
}
