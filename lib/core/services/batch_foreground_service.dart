import 'dart:io';

import 'package:flutter/services.dart';

class BatchForegroundService {
  static const MethodChannel _channel = MethodChannel('batch_background');

  Future<void> start({
    required int total,
    required int completed,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('startForeground', {
      'total': total,
      'completed': completed,
    });
  }

  Future<void> update({
    required int total,
    required int completed,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('updateForeground', {
      'total': total,
      'completed': completed,
    });
  }

  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('stopForeground');
  }
}
