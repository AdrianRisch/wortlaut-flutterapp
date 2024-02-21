import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:record/record.dart';

import '../../servicesAndWidgets/customfloatingactionbutton.dart';
import '../../servicesAndWidgets/network_manager.dart';
import 'package:logging/logging.dart';

class SpeechPage extends StatefulWidget {
  const SpeechPage({super.key});

  @override
  _SpeechPageState createState() => _SpeechPageState();
}

class _SpeechPageState extends State<SpeechPage> {
  late AudioRecorder audioRecord;
  late AudioPlayer audioPlayer;
  final NetworkManager networkManager = NetworkManager();
  final TextEditingController _expectedTextController = TextEditingController();
  String resultText = '';
  List<dynamic> _wordDifferences = [];
  bool _isRecording = false;
  String audioPath = "";
  String _currentAudioFormat = '';
  bool _isSemanticAnalysis = true;
  bool _showResults = false;
  String _selectedModelSize = 'medium'; // Standardwert
  String _transcribedText = '';
  String _semanticSimilarityPercent = '';
  bool _isUploading = false;
  final _logger = Logger('SpeechPage');

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioRecord = AudioRecorder();
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  // Logik für das Ändern der Auswahl
  void _handleModelSizeChange(String? newSize) {
    if (newSize != null) {
      setState(() {
        _selectedModelSize = newSize;
      });
    }
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
      _logger.severe("Fehler beim Abspielen der Aufnahme: $e");
      const catching = SnackBar(
        content: Text(
            'Fehler beim Abspielen der Aufnahme. Bitte versuchen Sie es erneut.'),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(catching);
    }
  }

  Future<void> playRecording() async {
    if (audioPath.isNotEmpty) {
      try {
        Source urlSource = UrlSource(audioPath);
        await audioPlayer.play(urlSource);
      } catch (e) {
        // Verwende Logger anstelle von print
        _logger.severe("Fehler beim Abspielen der Aufnahme: $e");
        const snackBar = SnackBar(
          content: Text(
              'Fehler beim Abspielen der Aufnahme. Bitte versuchen Sie es erneut.'),
          duration: Duration(seconds: 5),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      // Hinweis anzeigen, dass kein Aufnahmepfad verfügbar ist
      const snackBar = SnackBar(
        content: Text('Keine Aufnahme gefunden. Starte zuerst eine Aufnahme.'),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _uploadFile(String audioFileKey) async {
    try {
      setState(() {
        _isUploading = true; // Start des Ladeprozesses
      });

      // Bestimmen des Modus basierend auf der Benutzerauswahl
      String mode = _isSemanticAnalysis ? "semantic" : "wordByWord";
      // Übergeben des ausgewählten Modellgrößenwerts
      var response = await networkManager.uploadFile(
        audioFileKey,
        _expectedTextController.text,
        mode, // Verwendung des gewählten Modus
        _currentAudioFormat, // Übergeben des aktuellen Audioformats
        _selectedModelSize, // Übergeben der ausgewählten Modellgröße
      );
      if (response.containsKey('word_diff')) {
        setState(() {
          _wordDifferences = response['word_diff'];
        });
      }
      setState(() {
        _transcribedText = response['transcribed_text'] ?? 'Kein Text erkannt.';
        _semanticSimilarityPercent = response.containsKey('semantic_similarity')
            ? response['semantic_similarity']
            : 'Kein Vergleich';
        _showResults = true; // Zeigt den Ergebnisbereich an
      });
    } catch (e) {
      // Verwende Logger anstelle von print
      _logger.severe("Fehler beim upload der Daten: $e");
      const catching = SnackBar(
        content: Text(
            'Fehler beim upload der Daten. Bitte versuchen Sie es erneut.'),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(catching);
    } finally {
      setState(() {
        _isUploading = false; // Beenden des Ladeprozesses
      });
    }
  }

  Widget buildComparisonResult() {
    // Semantische Analyse: Zeige semantische Ähnlichkeit und den transkribierten Text an
    if (_isSemanticAnalysis) {
      return Text(
        'Zu $_semanticSimilarityPercent stimmt es überein. \n $_transcribedText',
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    // Wort-für-Wort-Analyse ohne erwarteten Text: Zeige nur den transkribierten Text an
    if (_expectedTextController.text.isEmpty) {
      return Text(
        ' $_transcribedText',
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    // Wort-für-Wort-Analyse mit erwartetem Text: Führe die Detailanalyse durch
    List<TextSpan> spans = [];
    for (var item in _wordDifferences) {
      TextStyle textStyle =
          const TextStyle(color: Colors.green, fontSize: 24); // Standardstil

      if (item['type'] == 'mismatch') {
        textStyle = const TextStyle(
            color: Colors.red,
            decoration: TextDecoration.underline,
            decorationColor: Colors.red,
            fontSize: 24);
      } else if (item['type'] == 'missing') {
        textStyle = const TextStyle(
            color: Colors.red,
            decoration: TextDecoration.underline,
            decorationColor: Colors.red,
            fontSize: 24);
      } else if (item['type'] == 'extra') {
        textStyle = const TextStyle(
            color: Colors.red,
            decoration: TextDecoration.underline,
            decorationColor: Colors.red,
            fontSize: 24);
      }
      // Beachte, dass "text" entsprechend der item['type'] angepasst wird
      String text = item['type'] == 'correct'
          ? item['word'] + " "
          : item['type'] == 'mismatch'
              ? item['transcribed'] + " "
              : item['type'] == 'missing'
                  ? item['word'] + " "
                  : item['word'] + " "; // Für 'extra'

      spans.add(TextSpan(text: text, style: textStyle));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double resultContainerHeight = 180.0;
    var bHeight = 180.0;
    var bWidth = 180.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sprachübung'),
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
            mainAxisSize:
                MainAxisSize.min, // Verwendet nur den notwendigen Platz
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              MergeSemantics(
                child: SizedBox(
                  width: double.infinity,
                  child: SwitchListTile(
                    title: Text(_isSemanticAnalysis
                        ? "Semantische Analyse"
                        : "Wort für Wort Analyse"),
                    subtitle: Text(_isSemanticAnalysis
                        ? "Der Text wird auf inhaltliche Übereinstimmung geprüft."
                        : "Der Text wird auf korrekte Übereinstimmung geprüft."),
                    secondary: const Icon(Icons.hearing),
                    value: _isSemanticAnalysis,
                    onChanged: (bool value) {
                      setState(() {
                        _isSemanticAnalysis = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 360,
                height: 100,
                child: TextField(
                  minLines: 1,
                  maxLines: null,
                  controller: _expectedTextController,
                  decoration: const InputDecoration(
                    labelText: 'Dein Wort oder Satz!',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height:
                    resultContainerHeight, // Feste Höhe für den Ergebnis-Container
                width: 360,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: _showResults
                      ? buildComparisonResult()
                      : Text('Ergebnisse werden hier angezeigt',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                                    style:
                                        Theme.of(context).textTheme.bodyMedium
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
                                  style: TextStyle(
                                      fontSize: 20), // Größere Schrift
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
