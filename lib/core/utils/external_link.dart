import 'package:url_launcher/url_launcher.dart';

/// Parses [raw] and returns it only when it is safe to hand to the OS: a web
/// link or a mailto. Anything else (tel:, intent:, file:, custom app schemes,
/// unparsable text) comes back null. Links inside PR/issue/README text are
/// written by other people, so they are never trusted as-is.
Uri? safeExternalUri(String? raw) {
  if (raw == null) return null;
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return null;
  switch (uri.scheme.toLowerCase()) {
    case 'http':
    case 'https':
      return uri.host.isEmpty ? null : uri;
    case 'mailto':
      return uri;
    default:
      return null;
  }
}

/// Opens [raw] in the system browser/mail app when [safeExternalUri] allows it.
/// Returns whether a launch was attempted.
Future<bool> openExternalLink(String? raw) async {
  final uri = safeExternalUri(raw);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}
