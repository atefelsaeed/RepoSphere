import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/repo_content_entity.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/repo_contents_provider.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class RepoBrowserScreen extends ConsumerWidget {
  final RepoEntity repo;
  final String path;

  const RepoBrowserScreen({
    super.key,
    required this.repo,
    required this.path,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentsAsync = ref.watch(repoContentsProvider(
      (owner: repo.ownerLogin, repo: repo.name, path: path),
    ));

    final breadcrumbs = _buildBreadcrumbs();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(repo.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (path.isNotEmpty)
              Text(
                path,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Breadcrumb nav
          if (breadcrumbs.isNotEmpty)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _BreadcrumbItem(
                      label: repo.name,
                      onTap: () => context.goNamed(
                        'repo-browser',
                        pathParameters: {'id': '${repo.id}'},
                        extra: (repo: repo, path: ''),
                      ),
                    ),
                    ...breadcrumbs,
                  ],
                ),
              ),
            ),

          // File list
          Expanded(
            child: contentsAsync.when(
              data: (items) => items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_rounded,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text('Empty directory',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                        ],
                      ).animate().fadeIn(duration: 300.ms),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color:
                            Theme.of(context).colorScheme.outlineVariant,
                      ),
                      itemBuilder: (ctx, i) =>
                          _ContentTile(item: items[i], repo: repo)
                              .animate(delay: (i * 25).clamp(0, 250).ms)
                              .fadeIn(duration: 200.ms)
                              .slideY(begin: 0.04, curve: Curves.easeOut),
                    ),
              loading: () => ListView.separated(
                itemCount: 14,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                itemBuilder: (_, __) => const ShimmerListTile(),
              ),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(repoContentsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbs() {
    if (path.isEmpty) return [];
    final parts = path.split('/');
    final crumbs = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      final crumbPath = parts.sublist(0, i + 1).join('/');
      final isLast = i == parts.length - 1;
      crumbs.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chevron_right_rounded, size: 16),
          if (isLast)
            Text(parts[i],
                style: const TextStyle(fontWeight: FontWeight.w600))
          else
            Builder(
              builder: (ctx) => _BreadcrumbItem(
                label: parts[i],
                onTap: () => ctx.goNamed(
                  'repo-browser',
                  pathParameters: {'id': '${repo.id}'},
                  extra: (repo: repo, path: crumbPath),
                ),
              ),
            ),
        ],
      ));
    }
    return crumbs;
  }
}

class _BreadcrumbItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BreadcrumbItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class _ContentTile extends StatelessWidget {
  final RepoContentItem item;
  final RepoEntity repo;

  const _ContentTile({required this.item, required this.repo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDir = item.isDir;

    return ListTile(
      leading: Icon(
        isDir ? Icons.folder_rounded : _fileIcon(item.name),
        color: isDir ? const Color(0xFF54AEFF) : cs.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        item.name,
        style: TextStyle(
          fontWeight: isDir ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: !isDir && item.size != null
          ? Text(
              _formatSize(item.size!),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            )
          : isDir
              ? Icon(Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant, size: 18)
              : null,
      onTap: () {
        if (isDir) {
          context.goNamed(
            'repo-browser',
            pathParameters: {'id': '${repo.id}'},
            extra: (repo: repo, path: item.path),
          );
        } else {
          context.goNamed(
            'file-viewer',
            pathParameters: {'id': '${repo.id}'},
            extra: (repo: repo, path: item.path, name: item.name),
          );
        }
      },
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'dart' || 'py' || 'js' || 'ts' || 'java' || 'kt' || 'swift' ||
      'go' || 'rs' || 'cpp' || 'c' || 'cs' || 'rb' || 'php' =>
        Icons.code_rounded,
      'md' || 'txt' || 'rst' => Icons.article_outlined,
      'json' || 'yaml' || 'yml' || 'toml' || 'xml' =>
        Icons.data_object_rounded,
      'png' || 'jpg' || 'jpeg' || 'gif' || 'svg' || 'webp' =>
        Icons.image_outlined,
      'pdf' => Icons.picture_as_pdf_outlined,
      'zip' || 'tar' || 'gz' => Icons.folder_zip_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
