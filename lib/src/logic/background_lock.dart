
import 'package:flutter/services.dart';

void lockDeviceTask() {
  const platform = MethodChannel('com.attendance/lock');
  platform.invokeMethod('lockScreen').catchError((e) {
    print('Error locking device: $e');
  });
}
