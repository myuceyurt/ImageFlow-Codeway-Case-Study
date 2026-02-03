import 'dart:io';

import 'package:flutter/services.dart';

class BackgroundTaskService {
  static const MethodChannel _channel = MethodChannel('batch_background');

  Future<void> begin() async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod<void>('beginBackgroundTask');
  }

  Future<void> end() async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod<void>('endBackgroundTask');
  }
}
