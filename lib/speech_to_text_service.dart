import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SpeechToTextService {
  final Record _recorder = Record();

  Future<String?> recordAndTranscribe() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/audio.mp3';
        await _recorder.start(
          path: filePath,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );

        await Future.delayed(Duration(seconds: 5));

        final path = await _recorder.stop();

        if (path != null) {
          String? apiKey = dotenv.env['OPEN_AI_API_KEY'];
          if (apiKey == null) {
            throw Exception('API key not found in .env file');
          }

          var request = http.MultipartRequest('POST', Uri.parse('https://api.openai.com/v1/audio/transcriptions'));
          request.headers['Authorization'] = 'Bearer $apiKey';
          request.fields['model'] = 'whisper-1';
          request.files.add(await http.MultipartFile.fromPath('file', path, filename: 'audio.mp3'));

          var response = await request.send();
          if (response.statusCode == 200) {
            final respStr = await response.stream.bytesToString();
            final jsonResponse = json.decode(respStr);
            return jsonResponse['text'];
          } else {
            print('Failed to transcribe: ${response.statusCode}');
            return null;
          }
        }
      }
    } catch (e) {
      print('Error in speech to text: $e');
    }
    return null;
  }
}