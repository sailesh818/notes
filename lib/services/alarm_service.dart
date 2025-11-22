import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

class AlarmService {
  static final player = AudioPlayer();
  static final Map<int, Timer> _autoStopTimers = {}; // Track auto-stop timers

  /// Initialize alarm system (call in main)
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Alarm.init();
  }

  /// Schedule an alarm
  static Future<void> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    String assetPath = 'assets/alarm.mp3',
    bool loopAudio = true,
    bool vibrate = true,
    double volume = 1.0,
    String notificationTitle = "Alarm",
    String notificationBody = "Alarm is ringing",
    Duration? autoStopDuration, // optional auto-stop
  }) async {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: assetPath,
      loopAudio: loopAudio,
      vibrate: vibrate,
      volumeSettings: VolumeSettings.fade(
        volume: volume,
        fadeDuration: const Duration(seconds: 3),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: notificationTitle,
        body: notificationBody,
        stopButton: "Stop",
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);

    // Setup auto-stop timer if duration is provided
    if (autoStopDuration != null) {
      _autoStopTimers[id]?.cancel();
      _autoStopTimers[id] = Timer(autoStopDuration, () async {
        await stopAlarm(id);
        _autoStopTimers.remove(id);
      });
    }
  }

  /// Stop a scheduled or currently playing alarm
  static Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
    await player.stop();

    // Cancel any pending auto-stop timer
    _autoStopTimers[id]?.cancel();
    _autoStopTimers.remove(id);
  }

  /// Play a custom alarm manually
  static Future<void> playCustomAlarm(String assetPath, {Duration? autoStopDuration}) async {
    await player.setAsset(assetPath);
    player.setLoopMode(LoopMode.one);
    await player.play();

    if (autoStopDuration != null) {
      Timer(autoStopDuration, () async {
        await player.stop();
      });
    }
  }
}
