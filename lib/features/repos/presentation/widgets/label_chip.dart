import 'package:flutter/material.dart';
import '../../domain/entities/pull_request_entity.dart';

class LabelChip extends StatelessWidget {
  final LabelEntity label;
  const LabelChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(label.color);
    final isDark = color.computeLuminance() < 0.4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label.name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? color.withAlpha(220) : color,
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
