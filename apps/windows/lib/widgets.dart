import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';

const appBlue = Color(0xFF129BFF);
const appCyan = Color(0xFF20D3FF);
const appBackground = Color(0xFF050507);
const appPanel = Color(0xFF111114);
const appCard = Color(0xFF191A1E);
const appCardSoft = Color(0xFF22242A);
const appMuted = Color(0xFF8E8E98);
const appWarning = Color(0xFFFFC857);
const appGreen = Color(0xFF30D158);

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: appCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class CircleTimer extends StatelessWidget {
  const CircleTimer({
    super.key,
    required this.progress,
    required this.remainingSeconds,
    required this.phase,
  });

  final double progress;
  final int remainingSeconds;
  final SessionPhase phase;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(
          min(constraints.maxWidth, constraints.maxHeight),
          430.0,
        ).clamp(280.0, 430.0);
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(progress: progress),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatSeconds(remainingSeconds),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 78,
                      fontWeight: FontWeight.w800,
                      height: 0.95,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    phase == SessionPhase.microBreak
                        ? '看远处，放松呼吸'
                        : phase == SessionPhase.resting
                        ? '休息，让大脑整理'
                        : '保持当前小目标',
                    style: const TextStyle(
                      color: appMuted,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 18;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF101116);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..color = appBlue.withValues(alpha: 0.13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Color(0xFF0E7AFF), Color(0xFF20D3FF), Color(0xFF0E7AFF)],
      ).createShader(rect);

    canvas.drawCircle(center, radius, base);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, glow);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, active);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class IconActionButton extends StatelessWidget {
  const IconActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 62,
    this.background,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final Color? background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            backgroundColor: background ?? appCardSoft,
            disabledBackgroundColor: const Color(0xFF111113),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, color: iconColor, size: size * 0.42),
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.accent = appBlue,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: appMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScienceNote extends StatelessWidget {
  const ScienceNote({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_rounded, color: appWarning, size: 19),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '基于持续注意力衰减、微休息和自我调节研究设计。只做本地个性化，不作医学或保证性结论。',
            style: TextStyle(
              color: appWarning,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

String formatDurationCompact(int seconds) {
  final safeSeconds = max(0, seconds);
  final hours = safeSeconds ~/ 3600;
  final minutes = (safeSeconds % 3600) ~/ 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

String formatSeconds(int seconds) {
  final safeSeconds = max(0, seconds);
  final minutes = safeSeconds ~/ 60;
  final rest = safeSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
}
