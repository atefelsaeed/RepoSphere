import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../core/utils/external_link.dart';
import 'remote_markdown_image.dart';

/// Markdown written by other people (PR/issue bodies, comments, READMEs,
/// release notes). Use these widgets instead of [MarkdownBody] / [Markdown]
/// directly: they always apply the two safety rules, so a new call site cannot
/// forget them.
///
///  * images are not fetched until the reader taps ([remoteMarkdownImage]);
///  * link taps go through [openExternalLink], which only opens http, https
///    and mailto.
///
/// `test/widget/safe_markdown_test.dart` fails if `lib/` renders Markdown
/// without them.
class SafeMarkdownBody extends StatelessWidget {
  final String data;
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;

  const SafeMarkdownBody({
    super.key,
    required this.data,
    this.selectable = true,
    this.styleSheet,
  });

  @override
  Widget build(BuildContext context) => MarkdownBody(
        data: data,
        selectable: selectable,
        styleSheet: styleSheet,
        imageBuilder: remoteMarkdownImage,
        onTapLink: _openLink,
      );
}

/// Scrollable variant of [SafeMarkdownBody].
class SafeMarkdown extends StatelessWidget {
  final String data;
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;
  final EdgeInsets padding;

  const SafeMarkdown({
    super.key,
    required this.data,
    this.selectable = true,
    this.styleSheet,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) => Markdown(
        data: data,
        selectable: selectable,
        styleSheet: styleSheet,
        padding: padding,
        imageBuilder: remoteMarkdownImage,
        onTapLink: _openLink,
      );
}

void _openLink(String text, String? href, String title) {
  if (href != null) openExternalLink(href);
}
