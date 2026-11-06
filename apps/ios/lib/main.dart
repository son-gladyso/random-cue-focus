import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'focus_engine.dart';
import 'models.dart';
import 'notification_service.dart';
import 'screens.dart';
import 'stores.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsStore = SettingsStore();
  final sessionStore = SessionStore();
  final notificationService = NotificationService();
  await notificationService.initialize();
  final settings = await settingsStore.load();

  runApp(
    RandomCueFocusApp(
      settingsStore: settingsStore,
      sessionStore: sessionStore,
      notificationService: notificationService,
      initialSettings: settings,
    ),
  );
}

class RandomCueFocusApp extends StatefulWidget {
  const RandomCueFocusApp({
    super.key,
    required this.settingsStore,
    required this.sessionStore,
    required this.notificationService,
    required this.initialSettings,
  });

  final SettingsStore settingsStore;
  final SessionStore sessionStore;
  final NotificationService notificationService;
  final FocusSettings initialSettings;

  @override
  State<RandomCueFocusApp> createState() => _RandomCueFocusAppState();
}

class _RandomCueFocusAppState extends State<RandomCueFocusApp>
    with WidgetsBindingObserver {
  late final FocusEngine engine;

  @override
  void initState() {
    super.initState();
    engine = FocusEngine(
      settings: widget.initialSettings,
      settingsStore: widget.settingsStore,
      sessionStore: widget.sessionStore,
      notificationService: widget.notificationService,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final inForeground = foregroundForLifecycle(state);
    if (inForeground != null) engine.setAppInForeground(inForeground);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    engine.dispose();
    super.dispose();
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
        scaffoldBackgroundColor: Colors.black,
        cupertinoOverrideTheme: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: appBlue,
        ),
      ),
      home: FocusScreen(
        engine: engine,
        settingsStore: widget.settingsStore,
        sessionStore: widget.sessionStore,
      ),
    );
  }
}

/// Maps a lifecycle state to whether the goal-check card can be seen.
///
/// `inactive` is transient on iOS (app switcher, Control Center, incoming
/// call banner) and is left unchanged: a real move to the background always
/// passes through `hidden`/`paused`, and the engine's tick-gap guard covers a
/// suspension that skips the callback.
@visibleForTesting
bool? foregroundForLifecycle(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.resumed:
      return true;
    case AppLifecycleState.hidden:
    case AppLifecycleState.paused:
    case AppLifecycleState.detached:
      return false;
    case AppLifecycleState.inactive:
      return null;
  }
}
