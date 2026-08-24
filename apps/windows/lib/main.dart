import 'dart:async';

import 'package:flutter/material.dart';

import 'dashboard.dart';
import 'focus_controller.dart';
import 'models.dart';
import 'notification_adapter.dart';
import 'repositories.dart';
import 'tray_controller.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = SessionRepository();
  final notificationAdapter = NotificationAdapter();
  await notificationAdapter.initialize();
  final settings = await repository.loadSettings();

  runApp(
    RandomCueFocusWindowsApp(
      repository: repository,
      notificationAdapter: notificationAdapter,
      initialSettings: settings,
    ),
  );
}

class RandomCueFocusWindowsApp extends StatefulWidget {
  const RandomCueFocusWindowsApp({
    super.key,
    required this.repository,
    required this.notificationAdapter,
    required this.initialSettings,
  });

  final SessionRepository repository;
  final NotificationAdapter notificationAdapter;
  final FocusSettings initialSettings;

  @override
  State<RandomCueFocusWindowsApp> createState() =>
      _RandomCueFocusWindowsAppState();
}

class _RandomCueFocusWindowsAppState extends State<RandomCueFocusWindowsApp>
    with WidgetsBindingObserver {
  late final FocusController controller;
  AppTrayController? trayController;

  @override
  void initState() {
    super.initState();
    controller = FocusController(
      settings: widget.initialSettings,
      repository: widget.repository,
      notificationAdapter: widget.notificationAdapter,
    );
    controller.addListener(_syncTray);
    WidgetsBinding.instance.addObserver(this);
    trayController = AppTrayController(
      onStartOrPause: () => unawaited(controller.startOrResume()),
      onStop: () => unawaited(controller.stop()),
      onExit: _exitApp,
    );
    unawaited(trayController!.initialize());
  }

  @override
  void dispose() {
    controller.removeListener(_syncTray);
    trayController?.dispose();
    controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncTray() {
    unawaited(trayController?.updatePhase(controller.phase));
  }

  Future<void> _exitApp() async {
    await controller.stop();
    await trayController?.exitApp();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Random Cue Focus',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appBlue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: appBackground,
        sliderTheme: const SliderThemeData(
          trackHeight: 4,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
        ),
      ),
      home: DashboardScreen(
        controller: controller,
        repository: widget.repository,
      ),
    );
  }
}
