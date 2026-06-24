import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vyaparsetu/global/themes.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool isShimmer;

  const LoadingIndicator({super.key, this.message, this.isShimmer = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isShimmer) {
      return _buildShimmerList(isDark);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSpinner(size: 44),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.shimmerBaseDark
                : AppTheme.shimmerBaseLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isDark ? AppTheme.gray800 : AppTheme.gray100,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerContainer(
                width: double.infinity,
                height: 14,
                borderRadius: 4,
              ),
              const SizedBox(height: 12),
              const ShimmerContainer(width: 150, height: 12, borderRadius: 4),
              const SizedBox(height: 10),
              const ShimmerContainer(width: 90, height: 12, borderRadius: 4),
            ],
          ),
        );
      },
    );
  }
}

class AppSpinner extends StatefulWidget {
  final double size;
  final Color? color;

  const AppSpinner({super.key, this.size = 44, this.color});

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spinnerColor =
        widget.color ?? (isDark ? AppTheme.primaryDark : AppTheme.primary);

    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(painter: _SpinnerPainter(color: spinnerColor)),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final Color color;

  _SpinnerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final gradient = SweepGradient(
      colors: [color.withValues(alpha: 0.0), color],
      stops: const [0.0, 1.0],
    );
    paint.shader = gradient.createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class ShimmerContainer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppTheme.shimmerBaseDark
        : AppTheme.shimmerBaseLight;
    final highlightColor = isDark
        ? AppTheme.shimmerHighlightDark
        : AppTheme.shimmerHighlightLight;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.3, 0.5, 0.7],
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {ui.TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent - 0.5) * 2,
      0.0,
      0.0,
    );
  }
}
