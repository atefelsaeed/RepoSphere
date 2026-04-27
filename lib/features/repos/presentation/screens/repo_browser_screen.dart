import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/repo_content_entity.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/repo_branches_provider.dart';
import '../providers/repo_contents_provider.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class RepoBrowserScreen extends ConsumerStatefulWidget {
  final RepoEntity repo;
  final String path;
  final String? initialBranch;

  const RepoBrowserScreen({
    super.key,
    required this.repo,
    required this.path,
    this.initialBranch,
  });

  @override
  ConsumerState<RepoBrowserScreen> createState() => _RepoBrowserScreenState();
}

class _RepoBrowserScreenState extends ConsumerState<RepoBrowserScreen> {
  late String _selectedBranch;

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.initialBranch ??
        widget.repo.defaultBranch ??
        'main';
  }

  ({String owner, String repo, String path, String? branch}) get _args => (
        owner: widget.repo.ownerLogin,
        repo: widget.repo.name,
        path: widget.path,
        branch: _selectedBranch,
      );

  void _goTo(String path) => context.goNamed(
        'repo-browser',
        pathParameters: {'id': '${widget.repo.id}'},
        extra: (repo: widget.repo, path: path, branch: _selectedBranch),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final contentsAsync = ref.watch(repoContentsProvider(_args));
    final branchesAsync = ref.watch(repoBranchesProvider(
      (owner: widget.repo.ownerLogin, repo: widget.repo.name),
    ));
    final breadcrumbs = _buildBreadcrumbs();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.repo.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (widget.path.isNotEmpty)
              Text(
                widget.path,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
          ],
        ),
        actions: [
          // Branch selector
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: branchesAsync.when(
              data: (branches) => _BranchSelector(
                branches: branches.map((b) => b.name).toList(),
                selected: _selectedBranch,
                defaultBranch: widget.repo.defaultBranch ?? 'main',
                onChanged: (branch) {
                  setState(() => _selectedBranch = branch);
                  // Reset to root on branch change
                  if (widget.path.isNotEmpty) _goTo('');
                },
              ),
              loading: () => _BranchSelector(
                branches: [_selectedBranch],
                selected: _selectedBranch,
                defaultBranch: _selectedBranch,
                onChanged: (_) {},
              ),
              error: (_, __) => _BranchSelector(
                branches: [_selectedBranch],
                selected: _selectedBranch,
                defaultBranch: _selectedBranch,
                onChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb nav
          if (breadcrumbs.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: cs.outlineVariant),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _BreadcrumbItem(
                      label: widget.repo.name,
                      onTap: () => _goTo(''),
                    ),
                    ...breadcrumbs,
                  ],
                ),
              ),
            ),

          // File list
          Expanded(
            child: contentsAsync.when(
              data: (items) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(repoContentsProvider),
                child: items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.folder_open_rounded,
                                      size: 48, color: cs.onSurfaceVariant),
                                  const SizedBox(height: 12),
                                  Text('Empty directory',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                              color: cs.onSurfaceVariant)),
                                ],
                              ).animate().fadeIn(duration: 300.ms),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: cs.outlineVariant),
                        itemBuilder: (ctx, i) => _ContentTile(
                          item: items[i],
                          repo: widget.repo,
                          branch: _selectedBranch,
                        )
                            .animate(delay: (i * 25).clamp(0, 250).ms)
                            .fadeIn(duration: 200.ms)
                            .slideY(begin: 0.04, curve: Curves.easeOut),
                      ),
              ),
              loading: () => ListView.separated(
                itemCount: 14,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: cs.outlineVariant),
                itemBuilder: (_, __) => const ShimmerListTile(),
              ),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(repoContentsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbs() {
    if (widget.path.isEmpty) return [];
    final parts = widget.path.split('/');
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
            _BreadcrumbItem(
              label: parts[i],
              onTap: () => _goTo(crumbPath),
            ),
        ],
      ));
    }
    return crumbs;
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _BranchSelector extends StatelessWidget {
  final List<String> branches;
  final String selected;
  final String defaultBranch;
  final ValueChanged<String> onChanged;

  const _BranchSelector({
    required this.branches,
    required this.selected,
    required this.defaultBranch,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final all = branches.contains(selected) ? branches : [selected, ...branches];

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
        color: cs.surfaceContainerHighest,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: false,
          icon: const Icon(Icons.unfold_more_rounded, size: 16),
          items: all.map((b) {
            final isDefault = b == defaultBranch;
            return DropdownMenuItem(
              value: b,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alt_route_rounded,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(b,
                      style: TextStyle(
                          fontWeight: isDefault
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13)),
                  if (isDefault) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('default',
                          style: TextStyle(
                              fontSize: 10,
                              color: cs.onPrimaryContainer)),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
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
        child: Text(label,
            style:
                TextStyle(color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }
}

class _ContentTile extends StatelessWidget {
  final RepoContentItem item;
  final RepoEntity repo;
  final String branch;

  const _ContentTile(
      {required this.item, required this.repo, required this.branch});

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
      title: Text(item.name,
          style: TextStyle(
              fontWeight: isDir ? FontWeight.w500 : FontWeight.normal)),
      trailing: !isDir && item.size != null
          ? Text(_formatSize(item.size!),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant))
          : isDir
              ? Icon(Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant, size: 18)
              : null,
      onTap: () {
        if (isDir) {
          context.goNamed(
            'repo-browser',
            pathParameters: {'id': '${repo.id}'},
            extra: (repo: repo, path: item.path, branch: branch),
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
      'json' || 'yaml' || 'yml' || 'toml' || 'xml' => Icons.data_object_rounded,
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
