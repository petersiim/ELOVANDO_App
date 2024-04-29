/* use when running on web for permissions
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'microphone_permission.dart';

class MicrophonePermissionWeb implements MicrophonePermission {
  @override
Future<bool> requestMicrophonePermission() async {
  try {
    final constraints = {'audio': true, 'video': false};
    await html.window.navigator.mediaDevices?.getUserMedia(constraints);
    return true;
  } catch (e) {
    print('Error requesting microphone permission: $e');
    return false;
  }
}
}
***/