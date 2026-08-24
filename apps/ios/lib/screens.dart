import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'focus_engine.dart';
import 'models.dart';
import 'stores.dart';
import 'widgets.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({
    super.key,
    required this.engine,
    required this.settingsStore,
    required this.sessionStore,
  });

  final FocusEngine engine;
  final SettingsStore settingsStore;
  final SessionStore sessionStore;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final isRunning =
            engine.phase == SessionPhase.focusing ||
            engine.phase == SessionPhase.microBreak;
        final isResting = engine.phase == SessionPhase.resting;
        final canStop = engine.isActive;
        final primaryIcon = isRunning
            ? CupertinoIcons.pause_fill
            : isResting
            ? CupertinoIcons.hourglass
            : CupertinoIcons.play_fill;
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                children: [
                  _TopBar(
                    onStats: () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => StatsScreen(sessionStore: sessionStore),
                      ),
                    ),
                    onSettings: () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => SettingsScreen(
                          settings: engine.settings,
                          onChanged: engine.updateSettings,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                  const Text(
                    'Focus',
                    style: TextStyle(
                      color: appBlue,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    engine.phaseLabel,
                    style: const TextStyle(
                      color: appMuted,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  CircleTimer(
                    progress: engine.progress,
                    remainingSeconds: engine.remainingSeconds,
                    phase: engine.phase,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      RoundIconButton(
                        icon: CupertinoIcons.music_note_2,
                        onPressed: () => _showSoundSheet(context, engine),
                      ),
                      RoundIconButton(
                        icon: primaryIcon,
                        background: appBlue,
                        size: 96,
                        onPressed: isResting
                            ? null
                            : () {
                                if (isRunning) {
                                  engine.pause();
                                } else if (engine.phase ==
                                    SessionPhase.paused) {
                                  engine.resume();
                                } else {
                                  engine.startFocus();
                                }
                              },
                      ),
                      RoundIconButton(
                        icon: CupertinoIcons.stop_fill,
                        iconColor: canStop ? Colors.white : appMuted,
                        onPressed: canStop ? engine.stop : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSoundSheet(BuildContext context, FocusEngine engine) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('提示音'),
        message: const Text('前台使用系统提示音与轻触反馈；锁屏使用 iOS 本地通知声音。'),
        actions: SoundPreset.values
            .map(
              (preset) => CupertinoActionSheetAction(
                onPressed: () {
                  engine.updateSettings(
                    engine.settings.copyWith(soundPreset: preset),
                  );
                  Navigator.of(context).pop();
                },
                child: Text(preset.label),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onStats, required this.onSettings});

  final VoidCallback onStats;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RoundIconButton(
          icon: CupertinoIcons.chart_pie_fill,
          size: 58,
          iconColor: appBlue,
          onPressed: onStats,
        ),
        const Spacer(),
        Container(
          constraints: const BoxConstraints(maxWidth: 230),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: appCardSoft,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Text(
            '专注算法 v1',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        RoundIconButton(
          icon: CupertinoIcons.gear_alt_fill,
          size: 58,
          iconColor: appMuted,
          onPressed: onSettings,
        ),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final FocusSettings settings;
  final Future<void> Function(FocusSettings settings) onChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late FocusSettings settings;

  @override
  void initState() {
    super.initState();
    settings = widget.settings;
  }

  Future<void> _save(FocusSettings next) async {
    setState(() => settings = next.normalized());
    await widget.onChanged(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 40),
          children: [
            _NavTitle(title: '设置', onBack: Navigator.of(context).pop),
            const SectionLabel('模式选择'),
            const GlassCard(
              child: Column(
                children: [
                  SettingsRow(
                    title: '随机提示音（默认）',
                    trailing: Icon(
                      CupertinoIcons.check_mark,
                      color: appBlue,
                      size: 28,
                    ),
                  ),
                  Divider(color: Color(0xFF3A3A3C)),
                  SettingsRow(title: '番茄时钟法'),
                  Divider(color: Color(0xFF3A3A3C)),
                  SettingsRow(title: '防走神模式'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const ScienceNote(),
            const SectionLabel('计时'),
            GlassCard(
              child: Column(
                children: [
                  SettingsRow(
                    title: '专注时间',
                    value: '${settings.focusDurationMinutes} 分钟',
                    onTap: () => _pickNumber(
                      title: '专注时间',
                      min: 15,
                      max: 180,
                      value: settings.focusDurationMinutes,
                      unit: '分钟',
                      onSelected: (value) =>
                          _save(settings.copyWith(focusDurationMinutes: value)),
                    ),
                  ),
                  const Divider(color: Color(0xFF3A3A3C)),
                  SettingsRow(
                    title: '休息时间',
                    value: '${settings.restDurationMinutes} 分钟',
                    onTap: () => _pickNumber(
                      title: '休息时间',
                      min: 1,
                      max: 45,
                      value: settings.restDurationMinutes,
                      unit: '分钟',
                      onSelected: (value) =>
                          _save(settings.copyWith(restDurationMinutes: value)),
                    ),
                  ),
                ],
              ),
            ),
            const SectionLabel('随机提示音'),
            GlassCard(
              child: Column(
                children: [
                  SettingsRow(
                    title: '最小间隔',
                    value: '${settings.minPromptIntervalMinutes} 分钟',
                    onTap: () => _pickNumber(
                      title: '最小间隔',
                      min: 1,
                      max: settings.maxPromptIntervalMinutes,
                      value: settings.minPromptIntervalMinutes,
                      unit: '分钟',
                      onSelected: (value) => _save(
                        settings.copyWith(minPromptIntervalMinutes: value),
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFF3A3A3C)),
                  SettingsRow(
                    title: '最大间隔',
                    value: '${settings.maxPromptIntervalMinutes} 分钟',
                    onTap: () => _pickNumber(
                      title: '最大间隔',
                      min: settings.minPromptIntervalMinutes,
                      max: 30,
                      value: settings.maxPromptIntervalMinutes,
                      unit: '分钟',
                      onSelected: (value) => _save(
                        settings.copyWith(maxPromptIntervalMinutes: value),
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFF3A3A3C)),
                  SettingsRow(
                    title: '微休息时长',
                    value: '${settings.microBreakSeconds} 秒',
                    onTap: () => _pickNumber(
                      title: '微休息时长',
                      min: 3,
                      max: 30,
                      value: settings.microBreakSeconds,
                      unit: '秒',
                      onSelected: (value) =>
                          _save(settings.copyWith(microBreakSeconds: value)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '每隔 ${settings.minPromptIntervalMinutes}-${settings.maxPromptIntervalMinutes} 分钟随机播放微休息提示音，并在 ${settings.microBreakSeconds} 秒后结束。',
              style: const TextStyle(
                color: appMuted,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SectionLabel('声音'),
            GlassCard(
              child: Column(
                children: [
                  SettingsRow(
                    title: '专注期间提示音',
                    trailing: CupertinoSwitch(
                      value: settings.foregroundPromptSoundEnabled,
                      onChanged: (value) => _save(
                        settings.copyWith(foregroundPromptSoundEnabled: value),
                      ),
                      activeTrackColor: const Color(0xFF30D158),
                    ),
                  ),
                  const Divider(color: Color(0xFF3A3A3C)),
                  SettingsRow(
                    title: '微休息开始',
                    value: settings.soundPreset.label,
                    onTap: () => _pickSound(),
                  ),
                  const Divider(color: Color(0xFF3A3A3C)),
                  SettingsRow(
                    title: '锁屏通知',
                    trailing: CupertinoSwitch(
                      value: settings.lockScreenNotifications,
                      onChanged: (value) => _save(
                        settings.copyWith(lockScreenNotifications: value),
                      ),
                      activeTrackColor: const Color(0xFF30D158),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickSound() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('微休息开始'),
        actions: SoundPreset.values
            .map(
              (preset) => CupertinoActionSheetAction(
                onPressed: () {
                  _save(settings.copyWith(soundPreset: preset));
                  Navigator.of(context).pop();
                },
                child: Text(preset.label),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _pickNumber({
    required String title,
    required int min,
    required int max,
    required int value,
    required String unit,
    required ValueChanged<int> onSelected,
  }) {
    var selected = value.clamp(min, max).toInt();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 320,
        color: const Color(0xFF1C1C1E),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    onPressed: () {
                      onSelected(selected);
                      Navigator.of(context).pop();
                    },
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 48,
                scrollController: FixedExtentScrollController(
                  initialItem: selected - min,
                ),
                onSelectedItemChanged: (index) => selected = min + index,
                children: [
                  for (var item = min; item <= max; item += 1)
                    Center(child: Text('$item $unit')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: FutureBuilder<List<FocusSession>>(
          future: sessionStore.loadSessions(),
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? const <FocusSession>[];
            final now = DateTime.now();
            final today = sessions.where((session) {
              return session.startedAt.year == now.year &&
                  session.startedAt.month == now.month &&
                  session.startedAt.day == now.day;
            }).toList();
            final todaySeconds = today.fold<int>(
              0,
              (sum, session) => sum + session.focusSeconds,
            );
            final totalSeconds = sessions.fold<int>(
              0,
              (sum, session) => sum + session.focusSeconds,
            );
            final completed = sessions.where((s) => s.completed).length;
            final completionRate = sessions.isEmpty
                ? 0
                : (completed / sessions.length * 100).round();

            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 40),
              children: [
                _NavTitle(title: '数据统计', onBack: Navigator.of(context).pop),
                const SizedBox(height: 26),
                const ScienceNote(),
                const SizedBox(height: 22),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.45,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MetricCard(
                      title: '今日专注',
                      value: formatDurationCompact(todaySeconds),
                    ),
                    _MetricCard(title: '今日周期', value: '${today.length} 个'),
                    _MetricCard(
                      title: '总专注',
                      value: formatDurationCompact(totalSeconds),
                    ),
                    _MetricCard(title: '完成率', value: '$completionRate%'),
                  ],
                ),
                const SectionLabel('专注记录'),
                GlassCard(
                  child: sessions.isEmpty
                      ? const Text(
                          '开始第一轮专注后，这里会显示记录。',
                          style: TextStyle(color: appMuted, fontSize: 18),
                        )
                      : Column(
                          children: sessions.reversed.take(6).map((session) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${session.startedAt.month.toString().padLeft(2, '0')}-${session.startedAt.day.toString().padLeft(2, '0')}  ${session.startedAt.hour.toString().padLeft(2, '0')}:${session.startedAt.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatDurationCompact(session.focusSeconds),
                                    style: const TextStyle(
                                      color: appBlue,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SectionLabel('最佳专注时间'),
                GlassCard(
                  child: SizedBox(
                    height: 300,
                    child: _HourDistributionChart(sessions: sessions),
                  ),
                ),
                const SectionLabel('年度热力图'),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 260,
                        child: _YearHeatmap(sessions: sessions),
                      ),
                      const SizedBox(height: 18),
                      const _HeatmapLegend(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavTitle extends StatelessWidget {
  const _NavTitle({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: RoundIconButton(
              icon: CupertinoIcons.chevron_left,
              size: 62,
              onPressed: onBack,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: appMuted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: appBlue,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HourDistributionChart extends StatelessWidget {
  const _HourDistributionChart({required this.sessions});

  final List<FocusSession> sessions;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HourDistributionPainter(sessions: sessions),
      child: const SizedBox.expand(),
    );
  }
}

class _HourDistributionPainter extends CustomPainter {
  const _HourDistributionPainter({required this.sessions});

  final List<FocusSession> sessions;

  @override
  void paint(Canvas canvas, Size size) {
    final values = List<double>.filled(24, 0);
    for (final session in sessions) {
      values[session.startedAt.hour] += session.focusSeconds / 3600;
    }
    final maxValue = max(1.0, values.reduce(max));
    final top = 26.0;
    final left = 56.0;
    final bottom = 42.0;
    final chartWidth = size.width - left - 12;
    final chartHeight = size.height - top - bottom;
    final barGap = chartWidth / 24;
    final barWidth = min(11.0, barGap * 0.55);
    final track = Paint()..color = const Color(0xFF4A4A4F);
    final active = Paint()..color = appBlue;
    final label = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );
    final yLabels = ['23h', '17h', '11h', '5h', '0h'];

    for (var i = 0; i < yLabels.length; i += 1) {
      final y = top + chartHeight * i / (yLabels.length - 1);
      label.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(color: appMuted, fontSize: 18),
      );
      label.layout(maxWidth: left - 8);
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
      if (valueHeight > 0) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            top + chartHeight - valueHeight,
            barWidth,
            valueHeight,
          ),
          const Radius.circular(8),
        );
        canvas.drawRRect(rect, active);
      }
    }

    final xLabels = {
      0: '00:00',
      4: '04:00',
      8: '08:00',
      12: '12:00',
      16: '16:00',
      20: '20:00',
    };
    for (final entry in xLabels.entries) {
      final x = left + barGap * entry.key;
      label.text = TextSpan(
        text: entry.value,
        style: const TextStyle(color: appMuted, fontSize: 16),
      );
      label.layout();
      label.paint(canvas, Offset(x - label.width / 2, top + chartHeight + 12));
    }
  }

  @override
  bool shouldRepaint(covariant _HourDistributionPainter oldDelegate) {
    return oldDelegate.sessions != sessions;
  }
}

class _YearHeatmap extends StatelessWidget {
  const _YearHeatmap({required this.sessions});

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
    final start = DateTime(now.year, 1);
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
    final cell = min((size.width - 8) / columns, (size.height - 34) / rows);
    final gap = max(2.0, cell * 0.18);
    final actual = cell - gap;
    final top = 32.0;
    final paint = Paint();

    final monthLabels = {0: '1月', 13: '4月', 26: '7月', 39: '10月'};
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final entry in monthLabels.entries) {
      textPainter.text = TextSpan(
        text: entry.value,
        style: const TextStyle(color: appMuted, fontSize: 16),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(entry.key * cell, 0));
    }

    for (var day = 0; day < daysInYear; day += 1) {
      final col = day ~/ rows;
      final row = day % rows;
      final seconds = byDay[day] ?? 0;
      paint.color = _heatmapColor(seconds);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(col * cell, top + row * cell, actual, actual),
        Radius.circular(actual * 0.22),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  Color _heatmapColor(int seconds) {
    if (seconds <= 0) return const Color(0xFF3A3A3C);
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

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('0m', Color(0xFF3A3A3C)),
      ('0-1h', Color(0xFF0A4269)),
      ('1h-3h', Color(0xFF0B65A8)),
      ('3h-5h', Color(0xFF0C89DE)),
      ('>5h', appBlue),
    ];
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: item.$2,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item.$1,
                style: const TextStyle(
                  color: appMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
