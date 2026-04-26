import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/repo_contents_provider.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class FileViewerScreen extends ConsumerWidget {
  final RepoEntity repo;
  final String path;
  final String name;

  const FileViewerScreen({
    super.key,
    required this.repo,
    required this.path,
    required this.name,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileAsync = ref.watch(fileContentProvider(
      (owner: repo.ownerLogin, repo: repo.name, path: path),
    ));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              path,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          fileAsync.whenOrNull(
            data: (file) => IconButton(
              tooltip: 'Copy content',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: file.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ) ?? const SizedBox.shrink(),
          IconButton(
            tooltip: 'Open on GitHub',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () => launchUrl(
              Uri.parse(
                  'https://github.com/${repo.ownerLogin}/${repo.name}/blob/${repo.defaultBranch ?? 'main'}/$path'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
      body: fileAsync.when(
        data: (file) => _CodeView(
          content: file.content,
          fileName: name,
          isDark: isDark,
        ),
        loading: () => const ShimmerCodeView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(fileContentProvider),
        ),
      ),
    );
  }
}

class _CodeView extends StatelessWidget {
  final String content;
  final String fileName;
  final bool isDark;

  const _CodeView({
    required this.content,
    required this.fileName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final language = _detectLanguage(fileName);

    // Binary/image files
    if (_isBinary(content)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hide_image_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Binary file — cannot display',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line numbers
        Container(
          color: isDark
              ? const Color(0xFF161B22)
              : const Color(0xFFF6F8FA),
          padding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              lines.length,
              (i) => SizedBox(
                height: 21,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(77),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Code
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 60,
              ),
              child: HighlightView(
                content,
                language: language,
                theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
                padding: const EdgeInsets.fromLTRB(12, 16, 24, 16),
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _detectLanguage(String name) {
    final ext =
        name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'dart' => 'dart',
      'py' => 'python',
      'js' => 'javascript',
      'ts' => 'typescript',
      'java' => 'java',
      'kt' => 'kotlin',
      'swift' => 'swift',
      'go' => 'go',
      'rs' => 'rust',
      'cpp' || 'cc' || 'cxx' => 'cpp',
      'c' => 'c',
      'cs' => 'csharp',
      'rb' => 'ruby',
      'php' => 'php',
      'html' || 'htm' => 'html',
      'css' => 'css',
      'scss' || 'sass' => 'scss',
      'json' => 'json',
      'yaml' || 'yml' => 'yaml',
      'xml' => 'xml',
      'md' => 'markdown',
      'sh' || 'bash' || 'zsh' => 'bash',
      'sql' => 'sql',
      'toml' => 'ini',
      _ => 'plaintext',
    };
  }

  bool _isBinary(String content) {
    final sample = content.length > 512 ? content.substring(0, 512) : content;
    return sample.contains('\x00');
  }
}
