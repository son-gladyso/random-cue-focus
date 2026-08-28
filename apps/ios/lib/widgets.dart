import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'models.dart';

const appBlue = Color(0xFF129BFF);
const appCard = Color(0xFF242426);
const appCardSoft = Color(0xFF1C1C1E);
const appMuted = Color(0xFF8E8E93);
const appWarning = Color(0xFFFFCC33);

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: appCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 28,
            offset: const Offset(0, 16),
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
    this.maxSize = 420,
  });

  final double progress;
  final int remainingSeconds;
  final SessionPhase phase;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    final size = min(
      MediaQuery.sizeOf(context).width.clamp(180.0, 420.0),
      maxSize,
    );
    return SizedBox(
      width: size.toDouble(),
      height: size.toDouble(),
      child: CustomPaint(
        painter: _RingPainter(progress: progress),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatSeconds(remainingSeconds),
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (size * 0.19).clamp(42.0, 76.0),
                  fontWeight: FontWeight.w800,
                  height: 0.95,
                  letterSpacing: 0,
                ),
              ),
              if (phase == SessionPhase.microBreak) ...[
                const SizedBox(height: 14),
                const Text(
                  '回看目标，记录当下状态',
                  style: TextStyle(
                    color: appMuted,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GoalCheckCard extends StatelessWidget {
  const GoalCheckCard({
    super.key,
    required this.goal,
    required this.onTask,
    required this.offTask,
    required this.onSkip,
  });

  final String goal;
  final VoidCallback onTask;
  final VoidCallback offTask;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '目标检查',
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        child: Column(
          children: [
            Text(
              goal.isEmpty ? '还在做刚才决定的事吗？' : '当前目标：$goal',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: [
                CupertinoButton(
                  minimumSize: const Size(44, 44),
                  onPressed: onTask,
                  child: const Text('仍在目标'),
                ),
                CupertinoButton(
                  minimumSize: const Size(44, 44),
                  onPressed: offTask,
                  child: const Text('刚刚走神'),
                ),
                CupertinoButton(
                  minimumSize: const Size(44, 44),
                  onPressed: onSkip,
                  child: const Text('跳过'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF101013);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..color = appBlue.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
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

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 78,
    this.background,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          backgroundColor: background ?? const Color(0xFF151517),
          disabledBackgroundColor: const Color(0xFF111113),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: iconColor, size: size * 0.42),
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.value,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                color: appMuted,
                fontSize: 21,
                fontWeight: FontWeight.w500,
              ),
            ),
          ?trailing,
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right, color: appMuted),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      onPressed: onTap,
      child: content,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 30, 4, 10),
      child: Text(
        text,
        style: const TextStyle(
          color: appMuted,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
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
        Icon(Icons.info_rounded, color: appWarning, size: 22),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '规划与自我监控有一定研究支持；短休息更稳定地改善疲劳感，不能保证认知表现。数据仅留在本地，不作医学结论。',
            style: TextStyle(
              color: appWarning,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
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

String _formatSeconds(int seconds) {
  final safeSeconds = max(0, seconds);
  final minutes = safeSeconds ~/ 60;
  final rest = safeSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
}
