import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dart_openai/dart_openai.dart';

class SpeechToTextService {
  static final SpeechToTextService _instance = SpeechToTextService._internal();
  factory SpeechToTextService() => _instance;
  SpeechToTextService._internal();

  final Record _recorder = Record();
  String? _path;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<void> startRecording() async {
    if (await _recorder.hasPermission()) {
      final directory = await getTemporaryDirectory();
      _path = '${directory.path}/audio.mp3';
      await _recorder.start(
        path: _path!,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
      );
      _isRecording = true;
    } else {
      print('Microphone permission not granted');
    }
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
    _isRecording = false;
  }

  Future<String?> transcribeAudio() async {
    if (_path == null) return null;
    try {
      OpenAIAudioModel transcription = await OpenAI.instance.audio.createTranscription(
        file: File(_path!),
        model: "whisper-1",
        responseFormat: OpenAIAudioResponseFormat.json,
      );
      return transcription.text;
    } catch (e) {
      print('Error transcribing audio: $e');
      return null;
    }
  }
}