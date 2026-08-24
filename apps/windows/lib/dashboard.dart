import 'package:flutter/material.dart';

import 'charts.dart';
import 'focus_controller.dart';
import 'models.dart';
import 'repositories.dart';
import 'widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.repository,
  });

  final FocusController controller;
  final SessionRepository repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _statsService = const StatsQueryService();
  late Future<List<FocusSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = widget.repository.loadSessions();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.phase == SessionPhase.idle ||
        widget.controller.phase == SessionPhase.completed) {
      setState(() => _sessionsFuture = widget.repository.loadSessions());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: appBackground,
          body: SafeArea(
            child: FutureBuilder<List<FocusSession>>(
              future: _sessionsFuture,
              builder: (context, snapshot) {
                final sessions = snapshot.data ?? const <FocusSession>[];
                final stats = _statsService.summarize(sessions);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final content = wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 11,
                                child: _FocusPanel(
                                  controller: widget.controller,
                                  sessions: sessions,
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 410,
                                child: _SidePanel(
                                  controller: widget.controller,
                                  sessions: sessions,
                                  stats: stats,
                                  onSettingsChanged:
                                      widget.controller.updateSettings,
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            children: [
                              SizedBox(
                                height: 660,
                                child: _FocusPanel(
                                  controller: widget.controller,
                                  sessions: sessions,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _SidePanel(
                                controller: widget.controller,
                                sessions: sessions,
                                stats: stats,
                                onSettingsChanged:
                                    widget.controller.updateSettings,
                              ),
                            ],
                          );
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: content,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FocusPanel extends StatelessWidget {
  const _FocusPanel({required this.controller, required this.sessions});

  final FocusController controller;
  final List<FocusSession> sessions;

  @override
  Widget build(BuildContext context) {
    final isRunning =
        controller.phase == SessionPhase.focusing ||
        controller.phase == SessionPhase.microBreak;
    final canStop = controller.isActive;
    final nextPrompt = controller.nextPromptRemainingSeconds;
    final latest = sessions.isEmpty ? null : sessions.last;
    final primaryIcon = isRunning ? Icons.pause_rounded : Icons.play_arrow;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq_rounded, color: appBlue, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Random Cue Focus',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: appBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: appBlue.withValues(alpha: 0.28)),
                ),
                child: Text(
                  controller.phaseLabel,
                  style: const TextStyle(
                    color: appBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const ScienceNote(),
          const Spacer(),
          Expanded(
            flex: 12,
            child: Center(
              child: CircleTimer(
                progress: controller.progress,
                remainingSeconds: controller.remainingSeconds,
                phase: controller.phase,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _PromptStrip(controller: controller, nextPrompt: nextPrompt),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconActionButton(
                icon: Icons.music_note_rounded,
                tooltip: '切换提示音',
                onPressed: () => _cycleSound(controller),
              ),
              const SizedBox(width: 24),
              IconActionButton(
                icon: primaryIcon,
                tooltip: isRunning ? '暂停' : '开始 / 恢复',
                size: 84,
                background: appBlue,
                onPressed: controller.startOrResume,
              ),
              const SizedBox(width: 24),
              IconActionButton(
                icon: Icons.stop_rounded,
                tooltip: '停止',
                iconColor: canStop ? Colors.white : appMuted,
                onPressed: canStop ? controller.stop : null,
              ),
            ],
          ),
          const Spacer(),
          if (latest != null)
            Text(
              '最近一轮 ${formatDurationCompact(latest.focusSeconds)}，完成率 ${(latest.completionRate * 100).round()}%',
              style: const TextStyle(
                color: appMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _cycleSound(FocusController controller) {
    final values = SoundPreset.values;
    final index = values.indexOf(controller.settings.soundPreset);
    final next = values[(index + 1) % values.length];
    return controller.updateSettings(
      controller.settings.copyWith(soundPreset: next),
    );
  }
}

class _PromptStrip extends StatelessWidget {
  const _PromptStrip({required this.controller, required this.nextPrompt});

  final FocusController controller;
  final int? nextPrompt;

  @override
  Widget build(BuildContext context) {
    final microBreak = controller.phase == SessionPhase.microBreak;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: microBreak
            ? appBlue.withValues(alpha: 0.14)
            : appPanel.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: microBreak
              ? appBlue.withValues(alpha: 0.34)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: microBreak
          ? Row(
              children: [
                const Icon(Icons.visibility_rounded, color: appBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '微休息 ${controller.microBreakRemaining} 秒：看远处，放松肩颈。',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.acknowledgePrompt,
                  child: const Text('完成'),
                ),
                TextButton(
                  onPressed: controller.delayPrompt,
                  child: const Text('延后'),
                ),
                TextButton(
                  onPressed: controller.skipPrompt,
                  child: const Text('跳过'),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.notifications_rounded, color: appMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nextPrompt == null
                        ? '本轮暂无更多提示，保持当前节奏。'
                        : '下次随机提示约 ${formatSeconds(nextPrompt!)} 后出现。',
                    style: const TextStyle(
                      color: appMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.controller,
    required this.sessions,
    required this.stats,
    required this.onSettingsChanged,
  });

  final FocusController controller;
  final List<FocusSession> sessions;
  final StatsSummary stats;
  final Future<void> Function(FocusSettings settings) onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            MetricTile(
              label: '今日专注',
              value: formatDurationCompact(stats.todaySeconds),
            ),
            MetricTile(label: '完成率', value: '${stats.completionPercent}%'),
            MetricTile(
              label: '总专注',
              value: formatDurationCompact(stats.totalSeconds),
            ),
            MetricTile(label: '提示反馈', value: '${stats.promptCount} 次'),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          settings: controller.settings,
          onChanged: onSettingsChanged,
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '最佳专注时间',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: HourDistributionChart(hourSeconds: stats.hourSeconds),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '年度热力图',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(height: 160, child: YearHeatmap(sessions: sessions)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _RecentSessions(sessions: sessions),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.settings, required this.onChanged});

  final FocusSettings settings;
  final Future<void> Function(FocusSettings settings) onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设置',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          _NumberSlider(
            label: '专注时间',
            value: settings.focusDurationMinutes,
            min: 15,
            max: 180,
            unit: '分钟',
            onChanged: (value) =>
                onChanged(settings.copyWith(focusDurationMinutes: value)),
          ),
          _NumberSlider(
            label: '休息时间',
            value: settings.restDurationMinutes,
            min: 1,
            max: 45,
            unit: '分钟',
            onChanged: (value) =>
                onChanged(settings.copyWith(restDurationMinutes: value)),
          ),
          _NumberSlider(
            label: '最小间隔',
            value: settings.minPromptIntervalMinutes,
            min: 1,
            max: settings.maxPromptIntervalMinutes,
            unit: '分钟',
            onChanged: (value) =>
                onChanged(settings.copyWith(minPromptIntervalMinutes: value)),
          ),
          _NumberSlider(
            label: '最大间隔',
            value: settings.maxPromptIntervalMinutes,
            min: settings.minPromptIntervalMinutes,
            max: 30,
            unit: '分钟',
            onChanged: (value) =>
                onChanged(settings.copyWith(maxPromptIntervalMinutes: value)),
          ),
          _NumberSlider(
            label: '微休息',
            value: settings.microBreakSeconds,
            min: 3,
            max: 30,
            unit: '秒',
            onChanged: (value) =>
                onChanged(settings.copyWith(microBreakSeconds: value)),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.desktopNotifications,
            onChanged: (value) =>
                onChanged(settings.copyWith(desktopNotifications: value)),
            title: const Text(
              '桌面通知',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            activeThumbColor: appBlue,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.foregroundPromptSoundEnabled,
            onChanged: (value) => onChanged(
              settings.copyWith(foregroundPromptSoundEnabled: value),
            ),
            title: const Text(
              '前台提示音',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            activeThumbColor: appBlue,
          ),
        ],
      ),
    );
  }
}

class _NumberSlider extends StatelessWidget {
  const _NumberSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$value $unit',
              style: const TextStyle(
                color: appMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: appBlue,
          inactiveColor: const Color(0xFF31343B),
          onChanged: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}

class _RecentSessions extends StatelessWidget {
  const _RecentSessions({required this.sessions});

  final List<FocusSession> sessions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近记录',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (sessions.isEmpty)
            const Text(
              '开始第一轮专注后，这里会显示记录。',
              style: TextStyle(color: appMuted, fontSize: 14),
            )
          else
            ...sessions.reversed.take(5).map(
                  (session) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${session.startedAt.month.toString().padLeft(2, '0')}-${session.startedAt.day.toString().padLeft(2, '0')}  ${session.startedAt.hour.toString().padLeft(2, '0')}:${session.startedAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          formatDurationCompact(session.focusSeconds),
                          style: const TextStyle(
                            color: appBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
