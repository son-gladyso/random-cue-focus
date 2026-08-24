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

class _RandomCueFocusAppState extends State<RandomCueFocusApp> {
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
  }

  @override
  void dispose() {
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
