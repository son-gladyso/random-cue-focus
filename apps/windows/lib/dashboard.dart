import 'dart:math';

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
              '最近一轮 ${formatDurationCompact(latest.focusSeconds)}，计时进度 ${(latest.completionRate * 100).round()}%',
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
    final studyAssignment = controller.activeStudyAssignment;
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
      child: controller.phase == SessionPhase.completed
          ? _SessionOutcomeFeedback(controller: controller)
          : microBreak
          ? Row(
              children: [
                const Icon(Icons.visibility_rounded, color: appBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.settings.sessionGoal.isEmpty
                        ? '目标检查 ${controller.microBreakRemaining} 秒：还在做刚才决定的事吗？'
                        : '目标检查：${controller.settings.sessionGoal}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.recordOnTask,
                  child: const Text('仍在目标'),
                ),
                TextButton(
                  onPressed: controller.recordOffTask,
                  child: const Text('刚刚走神'),
                ),
                TextButton(
                  onPressed: controller.delayPrompt,
                  child: const Text('稍后再问'),
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
                        ? studyAssignment?.condition == StudyCondition.noChecks
                              ? '本地实验对照轮次：本轮不显示目标检查。'
                              : '本轮暂无更多检查；时长不等于学习效果。'
                        : '下次稀疏检查约 ${formatSeconds(nextPrompt!)} 后出现。',
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

class _SessionOutcomeFeedback extends StatelessWidget {
  const _SessionOutcomeFeedback({required this.controller});

  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    final outcome = controller.outcomeReport;
    return Semantics(
      container: true,
      label: '可选会话复盘，仅保存在本机',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '可选复盘 · 仅本机。计时完成不等于有效。',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('有意义的进展：', style: TextStyle(color: appMuted)),
              _choice(
                '有',
                outcome?.meaningfulProgress == MeaningfulProgressResponse.yes,
                () => controller.recordMeaningfulProgress(
                  MeaningfulProgressResponse.yes,
                ),
              ),
              _choice(
                '没有',
                outcome?.meaningfulProgress == MeaningfulProgressResponse.no,
                () => controller.recordMeaningfulProgress(
                  MeaningfulProgressResponse.no,
                ),
              ),
              _choice(
                '不确定',
                outcome?.meaningfulProgress ==
                    MeaningfulProgressResponse.unsure,
                () => controller.recordMeaningfulProgress(
                  MeaningfulProgressResponse.unsure,
                ),
              ),
              const SizedBox(width: 8),
              const Text('本轮流程打扰：', style: TextStyle(color: appMuted)),
              _choice(
                '0 无',
                outcome?.interruptionBurden == 0,
                () => controller.recordInterruptionBurden(0),
              ),
              _choice(
                '2 一般',
                outcome?.interruptionBurden == 2,
                () => controller.recordInterruptionBurden(2),
              ),
              _choice(
                '4 明显',
                outcome?.interruptionBurden == 4,
                () => controller.recordInterruptionBurden(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onPressed) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? appBlue.withValues(alpha: 0.22) : null,
          side: BorderSide(color: selected ? appBlue : appMuted),
        ),
        child: Text(label),
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
    final outcomes = summarizeLocalOutcomes(sessions);
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
              label: '今日计时',
              value: formatDurationCompact(stats.todaySeconds),
            ),
            MetricTile(label: '计时完成率', value: '${stats.completionPercent}%'),
            MetricTile(
              label: '累计计时',
              value: formatDurationCompact(stats.totalSeconds),
            ),
            MetricTile(label: '检查显示', value: '${stats.promptCount} 次'),
            MetricTile(
              label: '自报有进展',
              value: outcomes.userValuedSessionRate == null
                  ? '暂无回答'
                  : '${(outcomes.userValuedSessionRate! * 100).round()}%',
            ),
            MetricTile(
              label: '高打扰反馈',
              value: outcomes.highBurdenRate == null
                  ? '暂无回答'
                  : '${(outcomes.highBurdenRate! * 100).round()}%',
            ),
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
                '计时分布',
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
          const Text('本轮小目标', style: TextStyle(color: appMuted, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey(settings.sessionGoal),
            initialValue: settings.sessionGoal,
            maxLength: 160,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (value) =>
                onChanged(settings.copyWith(sessionGoal: value)),
            decoration: const InputDecoration(
              hintText: '例如：写完方法部分第一稿',
              helperText: '按 Enter 保存；检查时只重现这个目标。',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey(settings.distractionTrigger),
            initialValue: settings.distractionTrigger,
            maxLength: 160,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) =>
                onChanged(settings.copyWith(distractionTrigger: value)),
            decoration: const InputDecoration(
              labelText: '如果……（分心触发）',
              hintText: '例如：我发现自己打开了无关页面',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey(settings.recoveryAction),
            initialValue: settings.recoveryAction,
            maxLength: 160,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (value) =>
                onChanged(settings.copyWith(recoveryAction: value)),
            decoration: const InputDecoration(
              labelText: '那么……（下一步动作）',
              hintText: '例如：关闭页面并写完下一句话',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            settings.ifThenPlan,
            style: const TextStyle(color: appMuted, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.goalChecksEnabled,
            onChanged: (value) =>
                onChanged(settings.copyWith(goalChecksEnabled: value)),
            title: const Text(
              '目标检查（可整段关闭）',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: const Text(
              '关闭后本轮不会出现非必要检查。',
              style: TextStyle(color: appMuted, fontSize: 12),
            ),
            activeThumbColor: appBlue,
          ),
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
            min: 5,
            max: settings.maxPromptIntervalMinutes,
            unit: '分钟',
            onChanged: (value) =>
                onChanged(settings.copyWith(minPromptIntervalMinutes: value)),
          ),
          _NumberSlider(
            label: '最大间隔',
            value: settings.maxPromptIntervalMinutes,
            min: settings.minPromptIntervalMinutes,
            max: 45,
            unit: '分钟',
            onChanged: (value) =>
                onChanged(settings.copyWith(maxPromptIntervalMinutes: value)),
          ),
          _NumberSlider(
            label: '检查窗口',
            value: settings.microBreakSeconds,
            min: 5,
            max: 60,
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
              '桌面通知（默认关闭）',
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
              '前台提示音（默认关闭）',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            activeThumbColor: appBlue,
          ),
          const Divider(color: Color(0xFF31343B)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.studyEnrollment?.isActive == true,
            onChanged: (value) => _setStudyEnabled(context, value),
            title: const Text(
              '本地交叉实验（自愿）',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Text(
              settings.studyEnrollment?.isActive == true
                  ? '已加入；第 ${settings.studyEnrollment!.nextSessionIndex + 1} 轮将在开始前分配。'
                  : '默认关闭；数据不上传，可随时退出。',
              style: const TextStyle(color: appMuted, fontSize: 12),
            ),
            activeThumbColor: appBlue,
          ),
        ],
      ),
    );
  }

  Future<void> _setStudyEnabled(BuildContext context, bool enabled) async {
    final current = settings.studyEnrollment;
    if (!enabled) {
      if (current != null && current.isActive) {
        await onChanged(
          settings.copyWith(studyEnrollment: current.withdraw(DateTime.now())),
        );
      }
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('自愿加入本地交叉实验？'),
        content: const Text(
          '部分会话不会显示目标检查，部分会话使用当前稀疏检查。分配会在会话开始前保存在本机；会后反馈可跳过；不会自动上传。你可以随时退出，退出不会删除既有本地记录。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('我了解并自愿加入'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;

    final random = Random.secure();
    final enrollment = createLocalFeasibilityEnrollment(
      participantCode: localParticipantCode(
        random.nextInt(1 << 31),
        random.nextInt(1 << 31),
      ),
      consentedAt: DateTime.now(),
      sequence: random.nextBool() ? StudySequence.ab : StudySequence.ba,
    );
    await onChanged(settings.copyWith(studyEnrollment: enrollment));
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
            ...sessions.reversed
                .take(5)
                .map(
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
