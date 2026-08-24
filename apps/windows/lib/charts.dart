import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';
import 'widgets.dart';

class HourDistributionChart extends StatelessWidget {
  const HourDistributionChart({super.key, required this.hourSeconds});

  final List<int> hourSeconds;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HourDistributionPainter(hourSeconds: hourSeconds),
      child: const SizedBox.expand(),
    );
  }
}

class _HourDistributionPainter extends CustomPainter {
  const _HourDistributionPainter({required this.hourSeconds});

  final List<int> hourSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    final values = List<double>.generate(
      24,
      (index) => (index < hourSeconds.length ? hourSeconds[index] : 0) / 3600,
    );
    final maxValue = max(1.0, values.reduce(max));
    final top = 16.0;
    final left = 44.0;
    final bottom = 32.0;
    final chartWidth = size.width - left - 12;
    final chartHeight = size.height - top - bottom;
    final barGap = chartWidth / 24;
    final barWidth = min(10.0, barGap * 0.56);
    final track = Paint()..color = const Color(0xFF30333A);
    final active = Paint()..color = appBlue;
    final label = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i <= 3; i += 1) {
      final y = top + chartHeight * i / 3;
      label.text = TextSpan(
        text: '${((3 - i) * maxValue / 3).round()}h',
        style: const TextStyle(color: appMuted, fontSize: 11),
      );
      label.layout(maxWidth: left - 6);
      label.paint(canvas, Offset(left - label.width - 8, y - label.height / 2));
    }

    for (var hour = 0; hour < 24; hour += 1) {
      final x = left + barGap * hour + (barGap - barWidth) / 2;
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, chartHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(trackRect, track);
      final valueHeight = chartHeight * (values[hour] / maxValue);
      if (valueHeight <= 0) continue;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top + chartHeight - valueHeight, barWidth, valueHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, active);
    }

    for (final hour in [0, 6, 12, 18]) {
      final x = left + barGap * hour;
      label.text = TextSpan(
        text: hour.toString().padLeft(2, '0'),
        style: const TextStyle(color: appMuted, fontSize: 11),
      );
      label.layout();
      label.paint(canvas, Offset(x - label.width / 2, top + chartHeight + 10));
    }
  }

  @override
  bool shouldRepaint(covariant _HourDistributionPainter oldDelegate) {
    return oldDelegate.hourSeconds != hourSeconds;
  }
}

class YearHeatmap extends StatelessWidget {
  const YearHeatmap({super.key, required this.sessions});

  final List<FocusSession> sessions;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _YearHeatmapPainter(sessions: sessions),
      child: const SizedBox.expand(),
    );
  }
}

class _YearHeatmapPainter extends CustomPainter {
  const _YearHeatmapPainter({required this.sessions});

  final List<FocusSession> sessions;

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final start = DateTime(now.year);
    final daysInYear = DateTime(now.year + 1).difference(start).inDays;
    final byDay = <int, int>{};
    for (final session in sessions) {
      if (session.startedAt.year != now.year) continue;
      final dayIndex = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      ).difference(start).inDays;
      byDay[dayIndex] = (byDay[dayIndex] ?? 0) + session.focusSeconds;
    }

    const rows = 7;
    final columns = (daysInYear / rows).ceil();
    final cell = min((size.width - 4) / columns, (size.height - 24) / rows);
    final gap = max(1.5, cell * 0.2);
    final actual = cell - gap;
    final top = 22.0;
    final paint = Paint();
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final entry in {0: '1月', 13: '4月', 26: '7月', 39: '10月'}.entries) {
      textPainter.text = TextSpan(
        text: entry.value,
        style: const TextStyle(color: appMuted, fontSize: 11),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(entry.key * cell, 0));
    }

    for (var day = 0; day < daysInYear; day += 1) {
      final col = day ~/ rows;
      final row = day % rows;
      paint.color = _heatmapColor(byDay[day] ?? 0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(col * cell, top + row * cell, actual, actual),
          Radius.circular(actual * 0.22),
        ),
        paint,
      );
    }
  }

  Color _heatmapColor(int seconds) {
    if (seconds <= 0) return const Color(0xFF2C2F36);
    if (seconds < 3600) return const Color(0xFF0A4269);
    if (seconds < 3 * 3600) return const Color(0xFF0B65A8);
    if (seconds < 5 * 3600) return const Color(0xFF0C89DE);
    return appBlue;
  }

  @override
  bool shouldRepaint(covariant _YearHeatmapPainter oldDelegate) {
    return oldDelegate.sessions != sessions;
  }
}
