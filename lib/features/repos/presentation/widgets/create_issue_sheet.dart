import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/repos_provider.dart';
import '../../../../l10n/l10n.dart';

class CreateIssueSheet extends ConsumerStatefulWidget {
  final RepoEntity repo;
  final VoidCallback onCreated;

  const CreateIssueSheet({
    super.key,
    required this.repo,
    required this.onCreated,
  });

  @override
  ConsumerState<CreateIssueSheet> createState() => _CreateIssueSheetState();
}

class _CreateIssueSheetState extends ConsumerState<CreateIssueSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ds = ref.read(
        githubDatasourceForConnectionProvider(widget.repo.connectionId));
    if (ds == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ds.createIssue(
        widget.repo.ownerLogin,
        widget.repo.name,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  Icon(Icons.circle_outlined,
                      size: 18, color: const Color(0xFF3FB950)),
                  const SizedBox(width: 8),
                  Text(l.newIssue,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(widget.repo.fullName,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l.titleLabel,
                  labelText: l.titleLabel,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.titleRequired : null,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(
                  hintText: l.describeIssueHint,
                  labelText: l.descriptionLabel,
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                minLines: 3,
                textInputAction: TextInputAction.newline,
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: cs.onErrorContainer, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: TextStyle(color: cs.onErrorContainer)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: Text(l.submitIssue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
