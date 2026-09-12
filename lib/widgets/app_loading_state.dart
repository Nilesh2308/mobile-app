import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Premium loading state with orbital animated dots in circular path
/// and pulsing gradient glow background.
class AppLoadingState extends StatefulWidget {
  const AppLoadingState({
    super.key,
    this.message = 'Loading...',
    this.subMessage,
  });

  final String message;
  final String? subMessage;

  @override
  State<AppLoadingState> createState() => _AppLoadingStateState();
}

class _AppLoadingStateState extends State<AppLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Orbital dots loader
            SizedBox(
              width: 56,
              height: 56,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _OrbitalDotsPainter(
                      progress: _controller.value,
                      colors: [
                        colors.primary,
                        AppColors.auroraViolet,
                        AppColors.neonCyan,
                      ],
                    ),
                  );
                },
              ),
            ),
            AppSpacing.vGap16,
            Text(
              widget.message,
              style: AppTextStyles.bodyMedium(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.subMessage != null) ...[
              AppSpacing.vGap6,
              Text(
                widget.subMessage!,
                style: AppTextStyles.caption(color: colors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        )
            .animate()
            .fadeIn(duration: 300.ms, curve: Curves.easeOut),
      ),
    );
  }
}

class _OrbitalDotsPainter extends CustomPainter {
  _OrbitalDotsPainter({
    required this.progress,
    required this.colors,
  });

  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    for (int i = 0; i < 3; i++) {
      final angle = progress * 2 * pi + (i * 2 * pi / 3);
      final dotSize = 5.0 - i * 0.8;
      final dotCenter = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      // Glow
      canvas.drawCircle(
        dotCenter,
        dotSize + 3,
        Paint()
          ..color = colors[i % colors.length].withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      canvas.drawCircle(dotCenter, dotSize, paint);
    }

    // Center subtle ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = colors.first.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitalDotsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Shimmer skeleton block for placeholder loading
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppRadius.borderR6,
  });

  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: borderRadius,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(begin: 0.5, end: 1.0, duration: 800.ms, curve: Curves.easeInOut);
  }
}
