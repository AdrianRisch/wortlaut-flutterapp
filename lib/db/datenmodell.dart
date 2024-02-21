import 'dart:convert';

import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'package:hive/hive.dart';

part 'datenmodell.g.dart';

@HiveType(typeId: 0)
class MeinDatenmodell extends HiveObject {
  @HiveField(0)
  String wort;
  @HiveField(1)
  String satz;
  @HiveField(2)
  int satzlaenge;
  @HiveField(3)
  int buchstabenlaenge;
  @HiveField(4)
  String kategorie;
  @HiveField(5)
  final String? bildUrl; // Bildpfad
  @HiveField(6)
  final String fileTyp; // Neues Feld für den Dateityp
  @HiveField(7)
  final Uint8List? bildBytes;

  MeinDatenmodell({
    required this.wort,
    required this.satz,
    required this.satzlaenge,
    required this.buchstabenlaenge,
    required this.kategorie,
    this.bildUrl,
    this.fileTyp = "asset",
    this.bildBytes,
  });
}

Future<void> addBildZuDatenbank({
  required String wort,
  required String satz,
  required String kategorie,
  required Uint8List bildBytes,
}) async {
  var box = await Hive.openBox<MeinDatenmodell>('master_db');
  final neuesDatenObjekt = MeinDatenmodell(
    wort: wort,
    satz: satz,
    satzlaenge: satz.length,
    buchstabenlaenge: wort.replaceAll(' ', '').length,
    kategorie: kategorie,
    bildBytes: bildBytes, 
    fileTyp: "file",
  );

  await box.add(neuesDatenObjekt);

  // Box für Kategorien öffnen
  var categoriesBox = await Hive.openBox<Categories>('categories_db');

  // Überprüfen, ob es ein Categories-Objekt gibt
  Categories? categoriesObjekt =
      categoriesBox.isEmpty ? null : categoriesBox.getAt(0);

  if (categoriesObjekt != null) {
    // Überprüfen, ob die neue Kategorie bereits existiert
    if (!categoriesObjekt.categories.contains(kategorie)) {
      // Füge die neue Kategorie zur Liste hinzu, wenn sie neu ist
      categoriesObjekt.categories.add(kategorie);
      categoriesObjekt.save();
    }
  } else {
    // Wenn es noch kein Categories-Objekt gibt, erstelle ein neues mit der neuen Kategorie
    final neueCategories = Categories(categories: [kategorie]);
    categoriesBox.add(neueCategories);
  }
}

Future<void> loadData() async {
  var jsonText =
      await rootBundle.loadString('assets/json/geaenderte_daten.json');
  final data = json.decode(jsonText) as List;

  var box = await Hive.openBox<MeinDatenmodell>('master_db');
  var categoriesBox = await Hive.openBox<Categories>('categories_db');

  var categoriesSet = <String>{};

  for (var item in data) {
    final datenObjekt = MeinDatenmodell(
      wort: item['Wort'],
      satz: item['Satz'],
      satzlaenge: item['Satz'].length,
      buchstabenlaenge: item['Wort'].replaceAll(' ', '').length,
      kategorie: item['Kategorie'],
      bildUrl:
          'assets/pictures/${item['Wort']}.webp', // Generieren der bildUrl basierend auf dem Wort
    );
    await box.add(datenObjekt);

    categoriesSet.add(item['Kategorie']);
  }

  // Logik zum Aktualisieren der Kategorien in der categoriesBox
  if (categoriesSet.isNotEmpty) {
    Categories? existingCategories =
        categoriesBox.isEmpty ? null : categoriesBox.getAt(0);
    if (existingCategories != null) {
      Set<String> newCategoriesSet = existingCategories.categories.toSet();
      newCategoriesSet.addAll(categoriesSet);
      if (newCategoriesSet.length != existingCategories.categories.length) {
        await categoriesBox.putAt(
            0, Categories(categories: newCategoriesSet.toList()));
      }
    } else {
      await categoriesBox.add(Categories(categories: categoriesSet.toList()));
    }
  }
}

@HiveType(typeId: 1) // typeId ist eindeutig in Ihrer Datenbank
class Categories extends HiveObject {
  @HiveField(0)
  List<String> categories;

  Categories({required this.categories});
}
