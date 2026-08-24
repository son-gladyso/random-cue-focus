import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';

class AppTrayController {
  AppTrayController({
    required this.onStartOrPause,
    required this.onStop,
    required this.onExit,
  });

  final VoidCallback onStartOrPause;
  final VoidCallback onStop;
  final VoidCallback onExit;

  static const _channel = MethodChannel('random_cue_focus/windows');

  Future<void> initialize() async {
    try {
      _channel.setMethodCallHandler(_handleNativeCall);
      await _channel.invokeMethod<void>('initializeTray');
      await updatePhase(SessionPhase.idle);
    } catch (error) {
      debugPrint('Tray init failed: $error');
    }
  }

  Future<void> updatePhase(SessionPhase phase) async {
    final isRunning =
        phase == SessionPhase.focusing || phase == SessionPhase.microBreak;
    try {
      await _channel.invokeMethod<void>('setTrayState', {
        'running': isRunning,
      });
    } catch (error) {
      debugPrint('Tray update failed: $error');
    }
  }

  Future<void> showWindow() async {
    try {
      await _channel.invokeMethod<void>('showWindow');
    } catch (error) {
      debugPrint('Show window failed: $error');
    }
  }

  Future<void> hideWindow() async {
    try {
      await _channel.invokeMethod<void>('hideWindow');
    } catch (error) {
      debugPrint('Hide window failed: $error');
    }
  }

  Future<void> closeWindow() async {
    try {
      await _channel.invokeMethod<void>('closeWindow');
    } catch (error) {
      debugPrint('Close window failed: $error');
    }
  }

  Future<void> exitApp() async {
    try {
      await _channel.invokeMethod<void>('exitApp');
    } catch (error) {
      debugPrint('Exit app failed: $error');
    }
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'show':
        await showWindow();
        return null;
      case 'startPause':
        onStartOrPause();
        return null;
      case 'stop':
        onStop();
        return null;
      case 'exit':
        onExit();
        return null;
      default:
        return null;
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}
