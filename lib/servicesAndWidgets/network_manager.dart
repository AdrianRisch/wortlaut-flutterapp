import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class NetworkManager {
  final String baseUrl = 'http://127.0.0.1:5050';
  final _logger = Logger('NetworkManager');

  Future<void> pingServer(BuildContext context) async {
    try {
      final stopwatch = Stopwatch()..start();

      var response =
          await http.get(Uri.parse("http://192.168.2.126:5050/ping"));

      stopwatch.stop();

      if (response.statusCode == 200) {
      } else {}
    } catch (e) {
      // Verwende Logger anstelle von print
      _logger.severe("Fehler beim pingen: $e");
      const catching = SnackBar(
        content: Text(
            'Fehler beim pingen. Bitte versuchen Sie es erneut und stellen Sie sicher, dass der Server gestartet ist.'),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(catching);
    }
  }

  Future<Map<String, dynamic>> uploadFile(String filePath, String? expectedText,
      String analysisType, String fileFormat, String modelSize) async {
    try {
      var audioBlobUrl = filePath;
      var audioBlobResponse = await http.get(Uri.parse(audioBlobUrl));
      var audioBlob = html.Blob([audioBlobResponse.bodyBytes]);
      final reader = html.FileReader();
      reader.readAsArrayBuffer(audioBlob);
      await reader.onLoad.first;
      List<int> fileBytes = reader.result as List<int>;

      var fileName = 'recording$fileFormat';

      var uri = Uri.parse('$baseUrl/transcribe');
      var request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes('file', fileBytes,
            filename: fileName));

      if (expectedText != null && expectedText.isNotEmpty) {
        request.fields['expected_text'] = expectedText;
      }
      request.fields['analysis_type'] = analysisType;

      // Fügt den Modellgrößen-Parameter hinzu
      request.fields['model_size'] = modelSize;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'error': 'Server responded with status code ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'error': 'Ein Fehler ist aufgetreten: $e'};
    }
  }
}
