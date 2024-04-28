import 'package:permission_handler/permission_handler.dart';
import 'microphone_permission.dart';

class MicrophonePermissionNative implements MicrophonePermission {
  @override
  Future<bool> requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();
    return status.isGranted;
  }
}