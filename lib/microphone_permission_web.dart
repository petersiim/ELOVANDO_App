import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'microphone_permission.dart';

class MicrophonePermissionWeb implements MicrophonePermission {
  @override
  Future<bool> requestMicrophonePermission() async {
    try {
      final constraints = js.JsObject.jsify({'audio': true, 'video': false});
      final promise = js_util.callMethod(js.context['navigator']['mediaDevices'], 'getUserMedia', [constraints]);
      await js_util.promiseToFuture(promise);
      return true;
    } catch (e) {
      return false;
    }
  }
}