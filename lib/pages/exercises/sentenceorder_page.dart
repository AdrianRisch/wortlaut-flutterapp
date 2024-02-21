import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../db/datenmodell.dart';
import '../../servicesAndWidgets/customfloatingactionbutton.dart';
import '../../servicesAndWidgets/image_widget.dart';

class SentenceOrderPage extends StatefulWidget {
  const SentenceOrderPage({super.key});

  @override
  _SentenceOrderPageState createState() => _SentenceOrderPageState();
}

class _SentenceOrderPageState extends State<SentenceOrderPage> {
  String? imageUrl = ''; 
  Uint8List? imageBytes; // Hinzufügen der Definition für imageBytes
  String sentence = '';
  String userGuess = '';

  List<String> shuffledWords = [];
  List<String> selectedWords = []; // List for selected words
  int wrongAttempts = 0; // Zählt, wie oft der Nutzer falsch geraten hat
  List<String> categories = ['Alle'];
  String selectedCategory = 'Alle';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    loadRandomSentence();
  }

  Future<void> _loadCategories() async {
    final box = Hive.box<Categories>('categories_db');
    // Annahme: Kategorien sind am Index 0 gespeichert
    Categories? categoriesData = box.getAt(0);

    if (categoriesData != null) {
      setState(() {
        // Fügt alle geladenen Kategorien der Dropdown-Liste hinzu
        categories.addAll(categoriesData.categories);
      });
    }
  }

  void loadRandomSentence() async {
    var box = Hive.box<MeinDatenmodell>('master_db');
    List<MeinDatenmodell> allSentences = box.values.toList();

    if (selectedCategory != 'Alle') {
      allSentences = allSentences
          .where((doc) => doc.kategorie == selectedCategory)
          .toList();
    }

    if (allSentences.isNotEmpty) {
      allSentences.shuffle();
      MeinDatenmodell randomSentence = allSentences.first;

      setState(() {
        if (randomSentence.fileTyp == 'asset') {
          imageUrl = 'assets/pictures/${randomSentence.wort}.webp';
          imageBytes = null;
        } else if (randomSentence.fileTyp == 'file') {
          imageBytes = randomSentence
              .bildBytes; 
          imageUrl = null;
        }

        sentence = randomSentence.satz;

        shuffledWords = sentence.split(' ')..shuffle();
        selectedWords =
            List<String>.filled(sentence.split(' ').length, '', growable: true);
      });
    }
  }

  void onWordClick(String word) {
    if (word.isEmpty) {
      return;
    }

    int selectedIndex = selectedWords.indexOf(word);
    if (selectedIndex == -1) {
      setState(() {
        int emptyIndex = selectedWords.indexOf('');
        if (emptyIndex != -1) {
          selectedWords[emptyIndex] = word;
          shuffledWords.remove(word);
        }
      });
    } else {
      setState(() {
        selectedWords[selectedIndex] = '';
        shuffledWords.add(word);
        shuffledWords.shuffle();
      });
    }
  }

  void handleRightAnswer() {
    const snackBar = SnackBar(
      content: Text('Gut gemacht!'),
      duration: Duration(seconds: 5),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void handleWrongAnswer() {
    const snackBar = SnackBar(
      content: Text('Versuchs nochmal!'),
      duration: Duration(seconds: 5),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    // Füge die falsch ausgewählten Sätze wieder zu den mischbaren Buchstaben hinzu
    setState(() {
      List<String> correctWords = sentence.split(' ');
      List<String> wrongSelectedWords = [];

      for (int i = 0; i < selectedWords.length; i++) {
        if (selectedWords[i] != '' && selectedWords[i] != correctWords[i]) {
          wrongSelectedWords.add(selectedWords[i]);
          selectedWords[i] = '';
        }
      }

      shuffledWords.addAll(wrongSelectedWords);
      shuffledWords.shuffle();
      userGuess = selectedWords.join('');
    });

    wrongAttempts++;

    // Ab dem fünften Fehlversuch wird alles zurückgesetzt und ein neues Bild geladen
    if (wrongAttempts >= 5) {
      resetGame();
    }
  }

  void resetGame() {
    setState(() {
      wrongAttempts = 0;
      loadRandomSentence(); // Lade ein neues Wort und Bild
    });
  }

  @override
  Widget build(BuildContext context) {
    void checkAnswer() {
      userGuess = selectedWords.join(' ');
      if (userGuess.trim() == sentence) {
        loadRandomSentence();
        handleRightAnswer();
      } else {
        handleWrongAnswer(); // Logik für falsche Antworten
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Satz Baumeister'),
        actions: <Widget>[
          DropdownButton<String>(
            value: selectedCategory,
            icon: const Icon(Icons.arrow_downward),
            elevation: 5,
            onChanged: (String? newValue) {
              setState(() {
                selectedCategory = newValue!;
                loadRandomSentence(); 
              });
            },
            items: categories.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      floatingActionButton: selectedWords.every((word) => word.isNotEmpty)
          ? CustomFloatingActionButton(onPressed: checkAnswer)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Stack(
                alignment: Alignment.center,
                children: [
                  ImageWidget(
                    imagePath: imageUrl, // Für Asset-Bilder
                    imageBytes: imageBytes, // Für Bilder als Byte-Daten
                  ),
                  if (wrongAttempts >= 3)
                    Positioned(
                      bottom: 10,
                      child: ElevatedButton(
                        onPressed: resetGame,
                        child: const Text("Weiter"), // Oder ein Pfeil-Icon
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 400,
                  height: 140, // Feste Höhe für ausgewählte Wörter
                  child: SingleChildScrollView(
                    child: Wrap(
                      children: selectedWords
                          .map((word) => Card(
                                margin: const EdgeInsets.all(5),
                                child: InkWell(
                                  onTap: () => onWordClick(word),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                        word.isNotEmpty ? word : '       ',
                                        style: const TextStyle(fontSize: 24)),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: 400,

                  height: 140, // Feste Höhe für gemischte Wörter
                  child: SingleChildScrollView(
                    child: Wrap(
                      children: shuffledWords
                          .map((word) => Card(
                                margin: const EdgeInsets.all(5),
                                child: InkWell(
                                  onTap: () => onWordClick(word),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(word,
                                        style: const TextStyle(fontSize: 24)),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
