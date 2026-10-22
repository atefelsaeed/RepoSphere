/// Percent-encodes each segment of a slash-separated path (`owner/name`,
/// `lib/src/a b.dart`) so values that came from a Git host cannot add `?`,
/// `#`, `%2e%2e` or extra segments to the request URL they are placed in.
String encodePath(String path) =>
    path.split('/').map(Uri.encodeComponent).join('/');
