import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerCodeView extends StatelessWidget {
  const ShimmerCodeView({super.key});

  static const _lineLengths = [
    0.55, 0.90, 0.70, 0.40, 0.80, 0.30, 0.65, 0.85, 0.50, 0.75,
    0.45, 0.90, 0.35, 0.70, 0.80, 0.40, 0.60, 0.55, 0.90, 0.30,
    0.70, 0.85, 0.45, 0.65, 0.50, 0.80, 0.35, 0.90, 0.60, 0.75,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
      highlightColor:
          isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            color: isDark
                ? const Color(0xFF161B22)
                : const Color(0xFFF6F8FA),
            padding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                _lineLengths.length,
                (_) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.5),
                  child: Container(
                    height: 12,
                    width: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _lineLengths.map((len) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.5),
                    child: FractionallySizedBox(
                      widthFactor: len,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
      highlightColor:
          isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ShimmerRepoCard extends StatelessWidget {
  const ShimmerRepoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
      highlightColor:
          isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1F2937)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _box(32, 32, radius: 16),
                const SizedBox(width: 8),
                Expanded(child: _box(12, 120)),
                const SizedBox(width: 8),
                _box(12, 50),
              ],
            ),
            const SizedBox(height: 12),
            _box(16, 180),
            const SizedBox(height: 8),
            _box(12, double.infinity),
            const SizedBox(height: 4),
            _box(12, 240),
            const Spacer(),
            Row(
              children: [
                _box(10, 10, radius: 5),
                const SizedBox(width: 6),
                _box(12, 60),
                const SizedBox(width: 16),
                _box(12, 30),
                const Spacer(),
                _box(12, 70),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(double h, double w, {double radius = 6}) => Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
      highlightColor:
          isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _box(20, 20, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(14, 260),
                  const SizedBox(height: 6),
                  _box(11, 180),
                  const SizedBox(height: 6),
                  _box(11, 120),
                ],
              ),
            ),
            _box(11, 50),
          ],
        ),
      ),
    );
  }

  Widget _box(double h, double w, {double radius = 6}) => Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
