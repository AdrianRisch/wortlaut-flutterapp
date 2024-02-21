// ignore_for_file: unused_field
// irgnores

import 'package:flutter/material.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'dart:convert';
import '../../servicesAndWidgets/customfloatingactionbutton.dart';
import '../../servicesAndWidgets/network_manager.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class RandomExercisesPage extends StatefulWidget {
  const RandomExercisesPage({super.key});

  @override
  _RandomExercisesPageState createState() => _RandomExercisesPageState();
}

class _RandomExercisesPageState extends State<RandomExercisesPage> {
  late AudioRecorder audioRecord;
  late AudioPlayer audioPlayer;

  final NetworkManager networkManager = NetworkManager();

  String _randomWord = '';
  bool _isRecording = false;
  String audioPath = "";
  String _transcribedText = '';
  String _semanticSimilarityPercent = '';
  List<dynamic> _wordDifferences = [];
  String _currentAudioFormat = '';
  String _selectedModelSize = 'medium'; // Standardwert
  bool _isUploading = false;
  final _logger = Logger('RandomExercisesPage');

  @override
  void initState() {
    audioPlayer = AudioPlayer();
    audioRecord = AudioRecorder();
    _fetchRandomWord();
    super.initState();
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        if (GetPlatform.isMobile) {
          await audioRecord.start(
              const RecordConfig(encoder: AudioEncoder.aacLc),
              path: audioPath);
          _currentAudioFormat =
              '.aac'; // Setzen des Formats auf AAC für mobile Plattformen
        } else {
          await audioRecord.start(
              const RecordConfig(encoder: AudioEncoder.opus),
              path: audioPath);
          _currentAudioFormat =
              '.opus'; // Setzen des Formats auf Opus für andere Plattformen
        }
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      // Verwende Logger anstelle von print
      _logger.severe("Fehler beim starten der Aufnahme: $e");
      const catching = SnackBar(
        content: Text(
            'Fehler beim starten der Aufnahme. Bitte versuchen Sie es erneut.'),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(catching);
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      setState(() {
        _isRecording = false;
        audioPath = path!;
      });
    } catch (e) {
      // Verwende Logger anstelle von print
      _logger.severe("Fehler beim stoppen der Aufnahme: $e");
      const catching = SnackBar(
        content: Text(
            'Fehler beim stoppen der Aufnahme. Bitte versuchen Sie es erneut.'),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(catching);
    }
  }

  Future<void> playRecording() async {
    try {
      Source urlSource = UrlSource(audioPath);
      await audioPlayer.play(urlSource);
    } catch (e) {
      // Verwende Logger anstelle von print
      _logger.severe("Fehler beim abspielen der Aufnahme: $e");
      const catching = SnackBar(
        content: Text(
            'Fehler beim abspielen der Aufnahme. Bitte versuchen Sie es erneut.'),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(catching);
    }
  }

  Future<void> _fetchRandomWord() async {
    try {
      final response = await http
          .get(Uri.parse('https://random-word-api.herokuapp.com/word?lang=de'));
      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        setState(() {
          _randomWord = json.decode(responseBody)[0];
        });
      } else {}
    } catch (e) {
      // Verwende Logger anstelle von print
      _logger.severe("Fehler beim laden der Daten: $e");
      const catching = SnackBar(
        content:
            Text('Fehler beim laden der Daten. Bitte versuchen Sie es erneut.'),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(catching);
    }
  }

  Future<void> _uploadFile(String audioFileKey) async {
    try {
      setState(() {
        _isUploading = true; // Start des Ladeprozesses
      });
      var response = await networkManager.uploadFile(
          audioFileKey,
          _randomWord,
          "wordByWord",
          _currentAudioFormat, // Übergeben des aktuellen Audioformats
          _selectedModelSize);
      if (response.containsKey('word_diff')) {
        setState(() {
          _wordDifferences = response['word_diff'];
        });
      }
      setState(() {
        _transcribedText = response['transcribed_text'] ?? 'Kein Text erkannt.';
        if (response.containsKey('expected_text')) {
          _transcribedText += " ${response['expected_text']}";
        }
      });
      // Überprüfen, ob die Antwort einen Fehler enthält
      if (response.containsKey('error')) {
      } else {}
    } catch (e) {
      e;
    } finally {
      setState(() {
        _isUploading = false; // Beenden des Ladeprozesses
      });
    }
  }

  // Logik für das Ändern der Auswahl
  void _handleModelSizeChange(String? newSize) {
    if (newSize != null) {
      setState(() {
        _selectedModelSize = newSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var bHeight = 180.0;
    var bWidth = 180.0;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Zufällige Wörter'),
          actions: <Widget>[
            DropdownButton<String>(
              value: _selectedModelSize,
              icon: const Icon(Icons.arrow_downward),
              elevation: 5,
              onChanged: _handleModelSizeChange,
              items: ['tiny', 'small', 'base', 'medium', 'large']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),
        floatingActionButton: _isUploading
            ? const CircularProgressIndicator() // Zeigt den Ladeindikator an, wenn _isUploading wahr ist
            : CustomFloatingActionButton(onPressed: () {
                _uploadFile(audioPath);
              }),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            InkWell(
              onTap: _fetchRandomWord,
              child: SizedBox(
                width: bHeight, // Feste Breite
                height: bWidth, // Feste Höhe
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.skip_next,
                          size: 48.0,
                        ),
                        Text(
                          "Neues Wort",
                          style: Theme.of(context).textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            const ExcludeSemantics(child: Text("Dein Wort lautet:")),
            Semantics(
              label: "Sage das Wort: $_randomWord",
              header: true,
              child: Container(
                width: 400,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).hintColor),
                  borderRadius: BorderRadius.circular(
                      5.0), // Leicht abgerundete Ecken (optional)
                ),
                child: ExcludeSemantics(
                  child: Text(
                    _randomWord,
                    textAlign: TextAlign
                        .center, // Zentriert den Text innerhalb des Containers
                    style: Theme.of(context).textTheme.bodyLarge,
                    textScaler: const TextScaler.linear(1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            const ExcludeSemantics(child: Text("Verstanden wurde:")),
            Semantics(
              label: "Verstanden wurde $_transcribedText",
              header: true,
              child: Container(
                width: 400,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).hintColor),
                  borderRadius: BorderRadius.circular(
                      5.0), // Leicht abgerundete Ecken (optional)
                ),
                child: ExcludeSemantics(
                  child: Text(
                    _transcribedText,
                    textAlign: TextAlign
                        .center, // Zentriert den Text innerhalb des Containers
                    style: Theme.of(context).textTheme.bodyLarge,
                    textScaler: const TextScaler.linear(1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Aufnahme starten/stoppen Card
                InkWell(
                  onTap: () =>
                      _isRecording ? stopRecording() : startRecording(),
                  child: SizedBox(
                    width: bHeight, // Feste Breite
                    height: bWidth, // Feste Höhe
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isRecording ? Icons.stop : Icons.play_arrow,
                              size: 48.0, // Größeres Icon für größere Card
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                  _isRecording
                                      ? 'Stoppe Aufnahme'
                                      : 'Starte Aufnahme',
                                  style: Theme.of(context).textTheme.bodyMedium
                                  // Größere Schrift
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20), // Abstand zwischen den Cards
                // Replay Card
                InkWell(
                  onTap: () => playRecording(),
                  child: SizedBox(
                    width: bHeight, // Feste Breite
                    height: bWidth, // Feste Höhe
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.replay,
                              size: 48.0, // Größeres Icon für größere Card
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Replay",
                                style:
                                    TextStyle(fontSize: 20), // Größere Schrift
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ))));
  }
}
