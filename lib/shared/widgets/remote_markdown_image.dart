import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';

/// `imageBuilder` for Markdown that comes from other people (PR/issue bodies,
/// comments, READMEs). Images are not fetched until the reader taps, because
/// an automatic request tells the image's host the reader's IP and when they
/// looked.
Widget remoteMarkdownImage(Uri uri, String? title, String? alt) =>
    RemoteMarkdownImage(uri: uri, alt: alt);

class RemoteMarkdownImage extends StatefulWidget {
  final Uri uri;
  final String? alt;
  const RemoteMarkdownImage({super.key, required this.uri, this.alt});

  @override
  State<RemoteMarkdownImage> createState() => _RemoteMarkdownImageState();
}

class _RemoteMarkdownImageState extends State<RemoteMarkdownImage> {
  bool _load = false;

  bool get _isWeb =>
      widget.uri.scheme == 'http' || widget.uri.scheme == 'https';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    if (!_isWeb) {
      return Text(
          widget.alt?.isNotEmpty == true ? widget.alt! : l.remoteImageBlocked);
    }
    if (_load) {
      return Image.network(
        widget.uri.toString(),
        semanticLabel: widget.alt,
        errorBuilder: (_, __, ___) => Text(
          widget.alt?.isNotEmpty == true ? widget.alt! : l.remoteImageBlocked,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _load = true),
        icon: const Icon(Icons.image_outlined, size: 16),
        label: Text(l.loadRemoteImage(widget.uri.host)),
      ),
    );
  }
}
