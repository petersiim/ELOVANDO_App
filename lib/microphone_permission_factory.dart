import 'microphone_permission.dart';
import 'microphone_permission_web.dart';
import 'microphone_permission_native.dart';
import 'package:flutter/foundation.dart';

MicrophonePermission createMicrophonePermission() {
  /*if (kIsWeb) {
    return MicrophonePermissionWeb();
  } else {
    */
    return MicrophonePermissionNative();
  }
