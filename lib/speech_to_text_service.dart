import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dart_openai/dart_openai.dart';
import 'package:just_audio/just_audio.dart';

class SpeechToTextService {
  static final SpeechToTextService _instance = SpeechToTextService._internal();
  factory SpeechToTextService() => _instance;
  SpeechToTextService._internal();
  TextEditingController? currentController;

  final Record _recorder = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _path;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<void> startRecording(TextEditingController controller) async {
    try {
      if (await _recorder.hasPermission()) {
        print("Microphone permission granted");
        final directory = await getTemporaryDirectory();
        _path = '${directory.path}/audio.wav';
        print("Recording to path: $_path");
        await _recorder.start(
          path: _path!,
          encoder: AudioEncoder.wav,
          bitRate: 16000,
          samplingRate: 16000,
        );
        _isRecording = true;
        currentController = controller;
        print("Recording started successfully");
      } else {
        print('Microphone permission not granted');
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      await _recorder.stop();
      _isRecording = false;
      currentController = null;
      print("Recording stopped successfully");
      
      File audioFile = File(_path!);
      if (await audioFile.exists()) {
        int fileSize = await audioFile.length();
        print("Audio file size: $fileSize bytes");
      } else {
        print("Audio file does not exist at path: $_path");
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> playRecordedAudio() async {
    if (_path != null) {
      try {
        print('Playing audio from: $_path');
        await _audioPlayer.setFilePath(_path!);
        await _audioPlayer.play();
      } catch (e) {
        print('Error playing audio: $e');
      }
    } else {
      print('No audio file to play');
    }
  }

  Future<String?> transcribeAudio() async {
    if (_path == null) {
      print('No audio file path available');
      return null;
    }
    try {
      print('Transcribing audio from path: $_path');
      File audioFile = File(_path!);
      if (!(await audioFile.exists())) {
        print('Audio file does not exist at path: $_path');
        return null;
      }
      
      int fileSize = await audioFile.length();
      print('Audio file size: $fileSize bytes');

      OpenAIAudioModel transcription = await OpenAI.instance.audio.createTranscription(
        file: audioFile,
        model: "whisper-1",
        responseFormat: OpenAIAudioResponseFormat.json,
        language: "de",
      );
      print('Transcription successful: ${transcription.text}');
      return transcription.text;
    } catch (e) {
      print('Error transcribing audio: $e');
      return null;
    }
  }
}