import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../providers/repos_provider.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Gists',
            icon: const Icon(Icons.code_rounded),
            onPressed: () => context.goNamed('gists'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.goNamed('settings'),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No profile data'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(currentUserProvider),
            child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar + name block
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: NetworkImage(user.avatarUrl),
                    ),
                    const SizedBox(height: 16),
                    if (user.name != null)
                      Text(
                        user.name!,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user.login}',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        user.bio!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06),

              const SizedBox(height: 24),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatBadge(value: user.publicRepos, label: 'Repos'),
                  _Divider(),
                  _StatBadge(value: user.followers, label: 'Followers'),
                  _Divider(),
                  _StatBadge(value: user.following, label: 'Following'),
                ],
              )
                  .animate(delay: 80.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.06),

              const SizedBox(height: 24),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: 16),

              // Info rows
              ...[
                if (user.location != null && user.location!.isNotEmpty)
                  _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: user.location!),
                if (user.company != null && user.company!.isNotEmpty)
                  _InfoRow(
                      icon: Icons.business_outlined,
                      text: user.company!.replaceAll('@', '')),
                if (user.email != null && user.email!.isNotEmpty)
                  _InfoRow(
                      icon: Icons.email_outlined,
                      text: user.email!,
                      onTap: () => launchUrl(
                          Uri.parse('mailto:${user.email}'),
                          mode: LaunchMode.externalApplication)),
                if (user.blog != null && user.blog!.isNotEmpty)
                  _InfoRow(
                      icon: Icons.link_rounded,
                      text: user.blog!,
                      onTap: () {
                        final url = user.blog!.startsWith('http')
                            ? user.blog!
                            : 'https://${user.blog}';
                        launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication);
                      }),
                if (user.createdAt != null)
                  _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: 'Joined ${timeago.format(user.createdAt!)}'),
              ]
                  .asMap()
                  .entries
                  .map((e) => e.value
                      .animate(delay: (120 + e.key * 40).ms)
                      .fadeIn(duration: 260.ms)
                      .slideX(begin: -0.04, curve: Curves.easeOut)),
            ],
          ),
          );
        },
        loading: () => _ProfileShimmer(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final int value;
  final String label;
  const _StatBadge({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          _format(value),
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  String _format(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  const _InfoRow({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: onTap != null ? cs.primary : null,
                  decoration:
                      onTap != null ? TextDecoration.underline : null,
                  decorationColor: cs.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Column(
            children: const [
              ShimmerBox(width: 96, height: 96, radius: 48),
              SizedBox(height: 16),
              ShimmerBox(width: 180, height: 22),
              SizedBox(height: 8),
              ShimmerBox(width: 120, height: 16),
              SizedBox(height: 12),
              ShimmerBox(width: 260, height: 14),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const ShimmerBox(height: 48, radius: 12),
        const SizedBox(height: 32),
        ...List.generate(4, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerBox(height: 20),
        )),
      ],
    );
  }
}
