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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 720;
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 24,
                    compact ? 10 : 16,
                    compact ? 16 : 24,
                    compact ? 16 : 28,
                  ),
                  child: Column(
                    children: [
                      _TopBar(
                        compact: compact,
                        onStats: () => Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) =>
                                StatsScreen(sessionStore: sessionStore),
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
                      SizedBox(height: compact ? 14 : 42),
                      Text(
                        'Focus',
                        style: TextStyle(
                          color: appBlue,
                          fontSize: compact ? 36 : 44,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 18),
                      Text(
                        engine.phaseLabel,
                        style: TextStyle(
                          color: appMuted,
                          fontSize: compact ? 18 : 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: CircleTimer(
                            progress: engine.progress,
                            remainingSeconds: engine.remainingSeconds,
                            phase: engine.phase,
                            maxSize: compact ? 220 : 420,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 16),
                      if (engine.activeStudyAssignment case final assignment?)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            assignment.condition == StudyCondition.noChecks
                                ? '本地实验对照轮次：本轮不显示目标检查'
                                : '本地实验稀疏检查轮次',
                            style: const TextStyle(
                              color: appMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      if (engine.phase == SessionPhase.microBreak)
                        GoalCheckCard(
                          goal: engine.settings.sessionGoal,
                          onTask: engine.recordOnTask,
                          offTask: engine.recordOffTask,
                          onSkip: engine.skipPrompt,
                        )
                      else if (engine.phase == SessionPhase.completed)
                        _SessionFeedbackCard(engine: engine)
                      else
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
                );
              },
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
        message: const Text('声音和锁屏通知均为可选项；默认静音，避免额外打断。'),
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

class _SessionFeedbackCard extends StatelessWidget {
  const _SessionFeedbackCard({required this.engine});

  final FocusEngine engine;

  @override
  Widget build(BuildContext context) {
    final outcome = engine.outcomeReport;
    return Semantics(
      container: true,
      label: '可选会话复盘，仅保存在本机',
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '可选复盘 · 仅本机',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text('这轮是否取得了有意义的进展？', style: TextStyle(color: appMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _feedbackButton(
                  '有进展',
                  outcome?.meaningfulProgress == MeaningfulProgressResponse.yes,
                  () => engine.recordMeaningfulProgress(
                    MeaningfulProgressResponse.yes,
                  ),
                ),
                _feedbackButton(
                  '没有',
                  outcome?.meaningfulProgress == MeaningfulProgressResponse.no,
                  () => engine.recordMeaningfulProgress(
                    MeaningfulProgressResponse.no,
                  ),
                ),
                _feedbackButton(
                  '不确定',
                  outcome?.meaningfulProgress ==
                      MeaningfulProgressResponse.unsure,
                  () => engine.recordMeaningfulProgress(
                    MeaningfulProgressResponse.unsure,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text('本轮计时流程的打扰程度？', style: TextStyle(color: appMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _feedbackButton(
                  '0 无打扰',
                  outcome?.interruptionBurden == 0,
                  () => engine.recordInterruptionBurden(0),
                ),
                _feedbackButton(
                  '2 一般',
                  outcome?.interruptionBurden == 2,
                  () => engine.recordInterruptionBurden(2),
                ),
                _feedbackButton(
                  '4 明显',
                  outcome?.interruptionBurden == 4,
                  () => engine.recordInterruptionBurden(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedbackButton(String label, bool selected, VoidCallback onPressed) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44, minWidth: 88),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: selected ? appBlue : const Color(0xFF2C2C2E),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onStats,
    required this.onSettings,
    required this.compact,
  });

  final VoidCallback onStats;
  final VoidCallback onSettings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RoundIconButton(
          icon: CupertinoIcons.chart_pie_fill,
          size: compact ? 50 : 58,
          iconColor: appBlue,
          onPressed: onStats,
        ),
        const Spacer(),
        Container(
          constraints: BoxConstraints(maxWidth: compact ? 150 : 230),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 7 : 9,
          ),
          decoration: BoxDecoration(
            color: appCardSoft,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(
            '稀疏检查 · 本地',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 13 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        RoundIconButton(
          icon: CupertinoIcons.gear_alt_fill,
          size: compact ? 50 : 58,
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
  late final TextEditingController _goalController;
  late final TextEditingController _triggerController;
  late final TextEditingController _recoveryController;

  @override
  void initState() {
    super.initState();
    settings = widget.settings;
    _goalController = TextEditingController(text: settings.sessionGoal);
    _triggerController = TextEditingController(
      text: settings.distractionTrigger,
    );
    _recoveryController = TextEditingController(text: settings.recoveryAction);
  }

  @override
  void dispose() {
    _goalController.dispose();
    _triggerController.dispose();
    _recoveryController.dispose();
    super.dispose();
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
            const SectionLabel('本轮意图'),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '当前要推进的具体小目标',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _goalController,
                    maxLength: 160,
                    placeholder: '例如：写完方法部分第一稿',
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) =>
                        _save(settings.copyWith(sessionGoal: value)),
                    style: const TextStyle(color: Colors.white, fontSize: 17),
                    placeholderStyle: const TextStyle(
                      color: appMuted,
                      fontSize: 17,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '如果……（分心触发）',
                    style: TextStyle(color: appMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: _triggerController,
                    maxLength: 160,
                    placeholder: '例如：我发现自己打开了无关页面',
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '那么……（下一步动作）',
                    style: TextStyle(color: appMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: _recoveryController,
                    maxLength: 160,
                    placeholder: '例如：关闭页面并写完下一句话',
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveIntent(),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    settings.ifThenPlan,
                    style: const TextStyle(
                      color: appMuted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CupertinoButton(
                      onPressed: _saveIntent,
                      child: const Text('保存目标与恢复计划'),
                    ),
                  ),
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
            const SectionLabel('稀疏目标检查'),
            GlassCard(
              child: Column(
                children: [
                  SettingsRow(
                    title: '启用目标检查',
                    trailing: CupertinoSwitch(
                      value: settings.goalChecksEnabled,
                      onChanged: (value) =>
                          _save(settings.copyWith(goalChecksEnabled: value)),
                    ),
                  ),
                  const Divider(color: Color(0xFF3A3A3C)),
                  SettingsRow(
                    title: '最小间隔',
                    value: '${settings.minPromptIntervalMinutes} 分钟',
                    onTap: () => _pickNumber(
                      title: '最小间隔',
                      min: 5,
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
                      max: 45,
                      value: settings.maxPromptIntervalMinutes,
                      unit: '分钟',
                      onSelected: (value) => _save(
                        settings.copyWith(maxPromptIntervalMinutes: value),
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFF3A3A3C)),
                  SettingsRow(
                    title: '检查窗口',
                    value: '${settings.microBreakSeconds} 秒',
                    onTap: () => _pickNumber(
                      title: '检查窗口',
                      min: 5,
                      max: 60,
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
              settings.goalChecksEnabled
                  ? '每隔 ${settings.minPromptIntervalMinutes}-${settings.maxPromptIntervalMinutes} 分钟出现一次可跳过的目标检查，并在 ${settings.microBreakSeconds} 秒后自动关闭。间隔是透明、可调的启发式，不是医学处方。'
                  : '本轮不会出现非必要目标检查；计时结束提示仍由通知设置独立控制。',
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
                    title: '前台提示音（默认关闭）',
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
                    title: '检查提示',
                    value: settings.soundPreset.label,
                    onTap: () => _pickSound(),
                  ),
                  const Divider(color: Color(0xFF3A3A3C)),
                  SettingsRow(
                    title: '锁屏通知（默认关闭）',
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
            const SectionLabel('个性化'),
            GlassCard(
              child: SettingsRow(
                title: '自适应降低打扰',
                trailing: CupertinoSwitch(
                  value: settings.adaptiveCadence,
                  onChanged: (value) =>
                      _save(settings.copyWith(adaptiveCadence: value)),
                  activeTrackColor: const Color(0xFF30D158),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '只有累积足够本地响应后才调整频率；跳过较多时会降低提示负担。该规则尚未经过产品级随机对照验证。',
              style: TextStyle(color: appMuted, fontSize: 15, height: 1.4),
            ),
            const SectionLabel('本地研究（实验性）'),
            GlassCard(
              child: SettingsRow(
                title: '自愿交叉可行性实验',
                value: settings.studyEnrollment?.isActive == true
                    ? '已加入 · 第 ${settings.studyEnrollment!.nextSessionIndex + 1} 轮'
                    : '默认关闭',
                trailing: CupertinoSwitch(
                  value: settings.studyEnrollment?.isActive == true,
                  onChanged: _setStudyEnabled,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '加入后，每轮开始前会持久化分配“无检查”或“稀疏检查”；会后回答仍可跳过，数据不上传，可随时退出。该模式只支持探索性评估，不代表产品已被验证。',
              style: TextStyle(color: appMuted, fontSize: 15, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setStudyEnabled(bool enabled) async {
    final current = settings.studyEnrollment;
    if (!enabled) {
      if (current != null && current.isActive) {
        await _save(
          settings.copyWith(studyEnrollment: current.withdraw(DateTime.now())),
        );
      }
      return;
    }

    final accepted = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('自愿加入本地交叉实验？'),
        content: const Text(
          '部分会话不会显示目标检查，部分会话使用当前稀疏检查。分配会在会话开始前保存在本机；会后反馈可跳过；不会自动上传。你可以随时退出，退出不会删除既有本地记录。',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('我了解并自愿加入'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;

    final random = Random.secure();
    final enrollment = createLocalFeasibilityEnrollment(
      participantCode: localParticipantCode(
        random.nextInt(1 << 31),
        random.nextInt(1 << 31),
      ),
      consentedAt: DateTime.now(),
      sequence: random.nextBool() ? StudySequence.ab : StudySequence.ba,
    );
    await _save(settings.copyWith(studyEnrollment: enrollment));
  }

  Future<void> _saveIntent() {
    return _save(
      settings.copyWith(
        sessionGoal: _goalController.text,
        distractionTrigger: _triggerController.text,
        recoveryAction: _recoveryController.text,
      ),
    );
  }

  void _pickSound() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('检查提示'),
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
            final outcomes = summarizeLocalOutcomes(sessions);
            final userValuedRate = outcomes.userValuedSessionRate;
            final highBurdenRate = outcomes.highBurdenRate;

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
                      title: '今日计时',
                      value: formatDurationCompact(todaySeconds),
                    ),
                    _MetricCard(title: '今日周期', value: '${today.length} 个'),
                    _MetricCard(
                      title: '累计计时',
                      value: formatDurationCompact(totalSeconds),
                    ),
                    _MetricCard(title: '计时完成率', value: '$completionRate%'),
                    _MetricCard(
                      title: '自报有进展',
                      value: userValuedRate == null
                          ? '暂无回答'
                          : '${(userValuedRate * 100).round()}%',
                    ),
                    _MetricCard(
                      title: '高打扰反馈',
                      value: highBurdenRate == null
                          ? '暂无回答'
                          : '${(highBurdenRate * 100).round()}%',
                    ),
                  ],
                ),
                const SectionLabel('计时记录'),
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
                const SectionLabel('计时分布'),
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
