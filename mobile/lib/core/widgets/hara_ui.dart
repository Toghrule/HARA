import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Small building blocks that give the screens one look: a coloured round icon, a countdown ring, a discount badge
/// and a ticket's dashed tear line.

/// An icon in a soft round background, for the top of a status screen.
class IconBadge extends StatelessWidget {
  const IconBadge({required this.icon, this.color, this.size = 96, super.key});

  final IconData icon;

  /// The accent; the theme's primary when `null`.
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.14)),
      child: Icon(icon, size: size * 0.5, color: accent),
    );
  }
}

/// A ring that empties as time runs out, with [child] (usually the time left) in the middle.
class CountdownRing extends StatelessWidget {
  const CountdownRing({required this.remaining, required this.total, required this.child, this.size = 140, this.color, super.key});

  final Duration remaining;
  final Duration total;
  final Widget child;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = total.inMilliseconds == 0 ? 0.0 : (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(fraction: fraction, track: scheme.outlineVariant, color: color ?? scheme.primary),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction, required this.track, required this.color});

  final double fraction;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 2 * math.pi, false, base..color = track);
    if (fraction > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, base..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction || old.color != color || old.track != track;
}

/// "-15%" in a gold pill.
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({required this.percent, super.key});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: scheme.secondary, borderRadius: BorderRadius.circular(20)),
      child: Text('$percent%', style: TextStyle(color: scheme.onSecondary, fontWeight: FontWeight.w800, fontSize: 16)),
    );
  }
}

/// The dashed line that separates the two halves of a ticket.
class TearLine extends StatelessWidget {
  const TearLine({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DashPainter(Theme.of(context).colorScheme.outline),
      );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
