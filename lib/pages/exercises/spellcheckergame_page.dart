import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../../db/datenmodell.dart';
import '../../servicesAndWidgets/customfloatingactionbutton.dart';
import '../../servicesAndWidgets/image_widget.dart';

class SpellCheckerGamePage extends StatefulWidget {
  const SpellCheckerGamePage({super.key});

  @override
  _SpellCheckerGamePageState createState() => _SpellCheckerGamePageState();
}

class _SpellCheckerGamePageState extends State<SpellCheckerGamePage> {
  String? imageUrl = ''; 
  Uint8List? imageBytes;
  String word = '';
  List<String> shuffledLetters = [];
  List<String> selectedLetters = [];
  String userGuess = '';
  int correctStreak = 0;
  String level = 'easy';
  int wrongAttempts = 0;
  List<String> categories = ['Alle'];
  String selectedCategory = 'Alle';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    loadRandomWord();
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

  void loadRandomWord() async {
    var box = Hive.box<MeinDatenmodell>('master_db');
    List<MeinDatenmodell> allWords = box.values.toList();

    if (selectedCategory != 'Alle') {
      allWords =
          allWords.where((doc) => doc.kategorie == selectedCategory).toList();
    }

    List<MeinDatenmodell> filteredWords;
    if (level == 'easy') {
      filteredWords =
          allWords.where((word) => word.buchstabenlaenge <= 5).toList();
    } else if (level == 'medium') {
      filteredWords = allWords
          .where(
              (word) => word.buchstabenlaenge > 5 && word.buchstabenlaenge <= 8)
          .toList();
    } else {
      // 'hard'
      filteredWords =
          allWords.where((word) => word.buchstabenlaenge > 8).toList();
    }

    if (filteredWords.isNotEmpty) {
      filteredWords.shuffle();
      MeinDatenmodell randomWord = filteredWords.first;

      setState(() {
        if (randomWord.fileTyp == 'asset') {
          imageUrl =
              randomWord.bildUrl!; 
          imageBytes =
              null; 
        } else if (randomWord.fileTyp == 'file') {
          imageBytes = randomWord
              .bildBytes; 
          imageUrl =
              null; 
        }
        // Konvertiere das Wort für die Anzeige zu Umlauten, bevor es aufgeteilt wird
        word = convertToDisplayForm(randomWord.wort).toUpperCase();
        shuffledLetters = word.split('')..shuffle();
        selectedLetters = List<String>.filled(word.length, '', growable: false);
        userGuess = '';
      });
    }
  }

  String convertToDisplayForm(String wort) {
    // Konvertiert die Ersatzformen zurück zu Umlauten für die Anzeige
    return wort
        .replaceAll('ae', 'ä')
        .replaceAll('oe', 'ö')
        .replaceAll('ue', 'ü')
        .replaceAll('Ae', 'Ä')
        .replaceAll('Oe', 'Ö')
        .replaceAll('Ue', 'Ü');
  }

  void onLetterClick(String letter) {
    setState(() {
      if (shuffledLetters.contains(letter)) {
       
        int emptyIndex = selectedLetters.indexOf('');
        if (emptyIndex != -1) {
          selectedLetters[emptyIndex] =
              letter; 
        }
        userGuess = selectedLetters.join('');
        shuffledLetters.remove(letter);
      }
    });
  }

  void removeSelectedLetter(int index) {
    setState(() {
      String letter = selectedLetters[index];
      if (letter != '') {
        selectedLetters[index] = ''; 
        userGuess = selectedLetters.join('');
        shuffledLetters
            .add(letter); // Buchstabe zur verfügbaren Liste hinzufügen
        shuffledLetters.sort(); // Sortieren, um die Reihenfolge beizubehalten
      }
    });
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
    // Füge die falsch ausgewählten Buchstaben wieder zu den mischbaren Buchstaben hinzu
    setState(() {
      List<String> correctWordLetters = word.split('');
      List<String> wrongSelectedLetters = [];

      for (int i = 0; i < selectedLetters.length; i++) {
        if (selectedLetters[i] != '' &&
            selectedLetters[i] != correctWordLetters[i]) {
          wrongSelectedLetters.add(selectedLetters[i]);
          selectedLetters[i] = '';
        }
      }

      shuffledLetters.addAll(wrongSelectedLetters);
      shuffledLetters.shuffle();
      userGuess = selectedLetters.join('');
    });

    wrongAttempts++;

    // Ab dem dritten Fehlversuch wird alles zurückgesetzt und ein neues Bild geladen
    if (wrongAttempts >= 5) {
      resetGame();
    }
  }

  void resetGame() {
    setState(() {
      correctStreak = 0;
      wrongAttempts = 0;
      loadRandomWord();
      // Lade ein neues Wort und Bild
    });
  }

  void checkAnswer() {
    if (userGuess == word) {
      loadRandomWord();
      handleRightAnswer();
    } else {
      handleWrongAnswer(); // Logik für falsche Antworten
    }
  }

  @override
  Widget build(BuildContext context) {
    double boxSize = 85.0;
    var boxHeight = 140.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wort Wirbel'),
        actions: <Widget>[
          DropdownButton<String>(
            value: selectedCategory,
            icon: const Icon(Icons.arrow_downward),
            elevation: 5,
            onChanged: (String? newValue) {
              setState(() {
                selectedCategory = newValue!;
                loadRandomWord(); // Aktualisieren Sie die Dokumente, wenn sich die Kategorie ändert
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
      floatingActionButton: selectedLetters.every((letter) => letter.isNotEmpty)
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: boxHeight,
                      child: Wrap(
                        children: selectedLetters
                            .asMap()
                            .map((index, letter) => MapEntry(
                                  index,
                                  InkWell(
                                    onTap: letter.isNotEmpty
                                        ? () => removeSelectedLetter(index)
                                        : null,
                                    child: SizedBox(
                                      width: boxSize, // Feste Breite
                                      height: boxSize, // Feste Höhe
                                      child: Card(
                                        margin: const EdgeInsets.all(10),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            letter.isEmpty ? ' ' : letter,
                                            style:
                                                const TextStyle(fontSize: 24),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ))
                            .values
                            .toList(),
                      ),
                    ),
                    SizedBox(
                      height: boxHeight, 
                      child: Wrap(
                        children: shuffledLetters
                            .map((letter) => SizedBox(
                                  width: boxSize, // Feste Breite
                                  height: boxSize, // Feste Höhe
                                  child: Card(
                                    margin: const EdgeInsets.all(10),
                                    child: InkWell(
                                      onTap: () => onLetterClick(letter),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          letter,
                                          style: const TextStyle(fontSize: 24),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
