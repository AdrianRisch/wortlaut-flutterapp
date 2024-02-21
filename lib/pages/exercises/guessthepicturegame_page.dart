import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:math';
import '../../db/datenmodell.dart';
import '../../servicesAndWidgets/image_widget.dart';

class GuessThePictureGamePage extends StatefulWidget {
  const GuessThePictureGamePage({super.key});

  @override
  State<GuessThePictureGamePage> createState() =>
      _GuessThePictureGamePageState();
}

class _GuessThePictureGamePageState extends State<GuessThePictureGamePage> {
  List<MeinDatenmodell> randomDocs = [];
  String? randomText;
  int correctIndex = -1;

  List<String> categories = ['Alle']; // Startwert für die Kategorienliste
  String selectedCategory = 'Alle'; // Startwert für die ausgewählte Kategorie

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRandomDocs();
  }

  Future<void> _loadCategories() async {
    final box = Hive.box<Categories>('categories_db');
    Categories? categoriesData = box.getAt(0);

    if (categoriesData != null) {
      setState(() {
        // Fügt alle geladenen Kategorien der Dropdown-Liste hinzu
        categories.addAll(categoriesData.categories);
      });
    }
  }

  Future<void> _loadRandomDocs() async {
    var box = Hive.box<MeinDatenmodell>('master_db');
    List<MeinDatenmodell> allDocs = box.values.toList();

    // Filtern basierend auf der ausgewählten Kategorie, wenn nicht 'Alle' ausgewählt ist
    if (selectedCategory != 'Alle') {
      allDocs =
          allDocs.where((doc) => doc.kategorie == selectedCategory).toList();
    }

    if (allDocs.length >= 4) {
      allDocs.shuffle(); // Mischen der Dokumente
      randomDocs = allDocs.sublist(
          0, 4); // Die ersten vier einzigartigen Dokumente auswählen

      correctIndex = Random().nextInt(randomDocs.length);
      randomText = randomDocs[correctIndex].wort;
    } else {
      randomText = 'Nicht genügend Dokumente für die Auswahl verfügbar.';
    }
    setState(() {
      // Aktualisiere den State mit den neuen Werten
      randomDocs = allDocs.sublist(0, 4);
      correctIndex = Random().nextInt(randomDocs.length);
      randomText = randomDocs[correctIndex].wort;
    });
  }

  String anzeigeNameAnpassen(String name) {
    return name
        .replaceAll('ae', 'ä')
        .replaceAll('oe', 'ö')
        .replaceAll('ue', 'ü')
        .replaceAll('Ae', 'Ä')
        .replaceAll('Oe', 'Ö')
        .replaceAll('Ue', 'Ü');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotoquiz'),
        actions: <Widget>[
          DropdownButton<String>(
            value: selectedCategory,
            icon: const Icon(Icons.arrow_downward),
            elevation: 5,
            onChanged: (String? newValue) {
              setState(() {
                selectedCategory = newValue!;
                _loadRandomDocs(); 
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildGameGrid(),
        ),
      ),
    );
  }

  Widget _buildGameGrid() {
    int crossAxisCount = MediaQuery.of(context).size.width > 820 ? 4 : 2;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            Card(
              elevation: 5,
              child: SizedBox(
                height: 140,
                width: 400,
                child: Center(
                  child: Semantics(
                    label: randomText ?? 'Warten auf Daten...',
                    child: Text(
                      anzeigeNameAnpassen(randomText ??
                          'Warten auf Daten...'), // Fallback, falls null
                      softWrap: true,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.0,
              ),
              itemCount: randomDocs.length,
              itemBuilder: (context, index) {
                return InkWell(
                    onTap: () {
                      // Logik, wenn auf ein Bild getippt wird
                      if (index == correctIndex) {
                        _loadRandomDocs();
                        handleRightAnswer();
                      } else {
                        handleWrongAnswer();
                      }
                    },
                    hoverColor: Colors.white,
                    focusColor: Colors.white,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ImageWidget(
                            imagePath:
                                randomDocs[index].bildUrl, // Für Asset-Bilder
                            imageBytes: randomDocs[index]
                                .bildBytes, // Für Bilder als Byte-Daten
                          ),
                        ]));
              },
            ),
          ],
        ),
      ),
    ]);
  }

  void handleWrongAnswer() {
    const snackBar = SnackBar(
      content: Text('Versuchs nochmal!'),
      duration: Duration(seconds: 5),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void handleRightAnswer() {
    const snackBar = SnackBar(
      content: Text('Gut gemacht!'),
      duration: Duration(seconds: 5),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
