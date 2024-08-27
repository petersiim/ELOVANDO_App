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
  String? _audioPath;
  bool _isRecording = false;
  TextEditingController? currentController;

  bool get isRecording => _isRecording;

  Future<void> startRecording(TextEditingController controller) async {
    if (await _recorder.hasPermission()) {
      final directory = await getTemporaryDirectory();
      _audioPath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        path: _audioPath!,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
      );
      _isRecording = true;
      currentController = controller;
    } else {
      throw Exception('Microphone permission not granted');
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    await _recorder.stop();
    _isRecording = false;
  }

  Future<String?> transcribeAudio() async {
    if (_audioPath == null) return null;
    try {
      final file = File(_audioPath!);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist');
      }

      OpenAIAudioModel transcription = await OpenAI.instance.audio.createTranscription(
        file: file,
        model: "whisper-1",
        responseFormat: OpenAIAudioResponseFormat.json,
      );

      // Clean up the audio file
      await file.delete();
      _audioPath = null;

      return transcription.text;
    } catch (e) {
      print('Error transcribing audio: $e');
      return null;
    } finally {
      currentController = null;
    }
  }
}