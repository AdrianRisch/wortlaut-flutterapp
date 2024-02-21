import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:wortlautapp/db/datenmodell.dart';
import '../servicesAndWidgets/customfloatingactionbutton.dart';

class ImageAddForm extends StatefulWidget {
  const ImageAddForm({super.key});

  @override
  _ImageAddFormState createState() => _ImageAddFormState();
}

class _ImageAddFormState extends State<ImageAddForm>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _wortController = TextEditingController();
  final TextEditingController _satzController = TextEditingController();
  final TextEditingController _kategorieController = TextEditingController();
  Uint8List? _imageBytes;
  List<String> categories = ['Alle']; // Startwert für die Kategorienliste
  String selectedCategory = 'Alle'; // Startwert für die ausgewählte Kategorie
  List<MeinDatenmodell> filteredData =
      []; // Gefilterte Daten basierend auf der ausgewählten Kategorie
  late TabController _tabController;
  String _searchQuery = '';
  List<String> _filteredCategories = [];
  final _logger = Logger('ImageAddForm');

  void _searchInAllCategories(String query) async {
    final box = await Hive.openBox<MeinDatenmodell>('master_db');
    final allData = box.values.toList();

    if (query.isEmpty) {
      setState(() {
        filteredData = allData;
      });
    } else {
      setState(() {
        filteredData = allData
            .where(
                (item) => item.wort.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxHeight: 400,
        maxWidth: 400);
    if (pickedFile != null) {
      final Uint8List imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = imageBytes;
      });
    }
  }

  Future<void> _saveData() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte wählen Sie ein Bild aus.')));
      return;
    }

    // Konvertiert _imageBytes in einen Base64-String, um ihn in Hive zu speichern
    try {
      await addBildZuDatenbank(
        wort: _wortController.text,
        satz: _satzController.text,
        kategorie: _kategorieController.text,
        bildBytes: _imageBytes!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daten erfolgreich gespeichert!')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern der Daten: $e')));
    }
  }

  Future<void> _loadCategories() async {
    final box = Hive.box<Categories>('categories_db');
    Categories? categoriesData = box.getAt(0);

    if (categoriesData != null) {
      setState(() {
        categories = ['Alle']; // Setzt 'Alle' als Standardwert
        categories.addAll(categoriesData.categories);

        if (!categories.contains(selectedCategory)) {
          selectedCategory =
              'Alle'; // Setzt zurück auf 'Alle', falls die aktuelle Kategorie nicht mehr existiert
        }
      });
    }
  }

  Future<void> deleteDatenObjekt(int objektKey) async {
    var box = Hive.box<MeinDatenmodell>('master_db');
    MeinDatenmodell? datenObjekt = box.get(objektKey);

    String? kategorie = datenObjekt?.kategorie;

    await box
        .delete(objektKey); // Löscht das Objekt mit dem angegebenen Schlüssel

    // Überprüfen, ob es das letzte Bild in der Kategorie war
    var allData =
        box.values.where((item) => item.kategorie == kategorie).toList();
    if (allData.isEmpty && kategorie != null) {
      await deleteCategory(kategorie);
    }

    _updateFilteredData();
  }

  Future<void> deleteCategory(String kategorie) async {
    var categoriesBox = Hive.box<Categories>('categories_db');
    Categories? categoriesData = categoriesBox.getAt(0);

    if (categoriesData != null) {
      categoriesData.categories.remove(kategorie);
      await categoriesBox.putAt(0, categoriesData);
    }

    _loadCategories();
  }

  // Diese Methode aktualisiert die gefilterten Daten basierend auf der ausgewählten Kategorie
  Future<void> _updateFilteredData() async {
    final box = await Hive.openBox<MeinDatenmodell>('master_db');
    final allData = box.values.toList();

    setState(() {
      if (selectedCategory == 'Alle') {
        filteredData = allData;
      } else {
        filteredData = allData
            .where((item) => item.kategorie == selectedCategory)
            .toList();
      }
    });
  }

  @override
  void initState() {
    _loadCategories();
    _updateFilteredData(); // Initialen Daten laden
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _wortController.dispose();
    _satzController.dispose();
    _kategorieController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> editDatenObjekt(int objektKey,
      {String? neuesWort, String? neuerSatz}) async {
    var box = Hive.box<MeinDatenmodell>('master_db');

    // Das zu bearbeitende Objekt anhand des Schlüssels finden
    MeinDatenmodell? datenObjekt = box.get(objektKey);

    if (datenObjekt != null) {
      // Überprüfen, ob neue Werte bereitgestellt wurden und diese entsprechend aktualisieren
      if (neuesWort != null) {
        datenObjekt.wort = neuesWort;
      }
      if (neuerSatz != null) {
        datenObjekt.satz = neuerSatz;
        // Aktualisieren der Satzlänge, da sich der Satz geändert hat
        datenObjekt.satzlaenge = neuerSatz.length;
      }

      // Das aktualisierte Objekt in der Box speichern
      await box.put(objektKey, datenObjekt);
    } else {
      _logger.severe("Kein Objekt gefunden");
      // Hinweis anzeigen, dass kein Aufnahmepfad verfügbar ist
      const snackBar = SnackBar(
        content: Text('Objekt nicht gefunden'),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> showEditDialog(BuildContext context, int objektKey) async {
    var box = Hive.box<MeinDatenmodell>('master_db');
    MeinDatenmodell? datenObjekt = box.get(objektKey);

    TextEditingController wortController =
        TextEditingController(text: datenObjekt?.wort ?? '');
    TextEditingController satzController =
        TextEditingController(text: datenObjekt?.satz ?? '');

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editieren'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                // Überprüfen, ob Memory-Bilder vorhanden sind, sonst Asset-Bilder verwenden
                if (datenObjekt?.bildBytes != null)
                  Image.memory(datenObjekt!.bildBytes!, fit: BoxFit.cover)
                else if (datenObjekt?.bildUrl != null)
                  Image.asset(datenObjekt!.bildUrl!,
                      fit: BoxFit
                          .cover) // Sicherstellen, dass bildUrl nicht null ist
                else
                  const SizedBox(), // Fallback für den Fall, dass kein Bild vorhanden ist
                TextField(
                  controller: wortController,
                  decoration:
                      const InputDecoration(hintText: 'Neues Wort eingeben'),
                ),
                TextField(
                  controller: satzController,
                  decoration:
                      const InputDecoration(hintText: 'Neuen Satz eingeben'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Speichern'),
              onPressed: () async {
                String neuesWort = wortController.text.isEmpty
                    ? datenObjekt!.wort
                    : wortController.text;
                String? neuerSatz = satzController.text.isEmpty
                    ? datenObjekt?.satz
                    : satzController.text;

                await editDatenObjekt(objektKey,
                    neuesWort: neuesWort, neuerSatz: neuerSatz);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void updateDatenObjekt() async {
    int objektKey = 0; // Der eindeutige Schlüssel des zu bearbeitenden Objekts
    String neuesWort = 'NeuesWort';
    String neuerSatz = 'Das ist ein neuer Satz.';

    await editDatenObjekt(objektKey,
        neuesWort: neuesWort, neuerSatz: neuerSatz);
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredCategories.isEmpty && categories.isNotEmpty) {
      _filteredCategories = categories;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bild und Daten hinzufügen'),
        actions: _tabController.index == 1
            ? [
                DropdownButton<String>(
                  value: selectedCategory,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                    });
                    _updateFilteredData(); // Aktualisiert die Daten, wenn eine neue Kategorie ausgewählt wird
                  },
                  items:
                      categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ]
            : [],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Hinzufügen'),
            Tab(icon: Icon(Icons.image), text: 'Anzeigen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Bildupload und Datenformular
          _buildAddForm(),
          // Tab 2: Anzeigen der Bilder
          _buildImageDisplay(),
        ],
      ),
    );
  }

  Widget _buildAddForm() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          SizedBox(
            width: 400,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    controller: _wortController,
                    decoration: const InputDecoration(labelText: 'Wort'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte ein Wort eingeben';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _satzController,
                    decoration: const InputDecoration(labelText: 'Satz'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte einen Satz eingeben';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _kategorieController,
                    decoration: const InputDecoration(labelText: 'Kategorie'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte eine Kategorie eingeben oder auswählen';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _imageBytes == null
              ? const Text("Kein Bild ausgewählt")
              : Image.memory(_imageBytes!,
                  height: 200), // Vorschau des ausgewählten Bildes,
          CustomFloatingActionButton(
            onPressed: _pickImage,
            buttonText: 'Bild auswählen',
          ),

          const SizedBox(height: 20),
          CustomFloatingActionButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _saveData();
              }
            },
            buttonText: 'Speichern',
          ),
        ]));
  }

  Widget _buildImageDisplay() {
    return Column(
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.center, // Zentriert die Elemente in der Row
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _searchInAllCategories(_searchQuery);
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Suche nach Wort',
                  suffixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: filteredData.length,
            itemBuilder: (context, index) {
              final item = filteredData[index];
              final objektKey = item.key;
              return Center(
                child: SizedBox(
                  width: 400,
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // Bildbereich
                          SizedBox(
                            width: 150, // Maximale Breite des Bildbereichs
                            height: 100, // Maximale Höhe des Bildbereichs
                            child: item.bildBytes != null
                                ? Image.memory(item.bildBytes!,
                                    fit: BoxFit.cover)
                                : (item.bildUrl != null
                                    ? Image.asset(item.bildUrl!,
                                        fit: BoxFit.cover)
                                    : const SizedBox()), // Leeres Feld, falls kein Bild vorhanden
                          ),
                          // Text- und Aktionsbereich
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    item.wort,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item.satz,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          showEditDialog(context,
                                              objektKey); // `objektKey` ist der Schlüssel des zu bearbeitenden Objekts
                                        },
                                      ),
                                      IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () {
                                            // Löschen-Funktion aufrufen
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Löschen bestätigen'),
                                                  content: const Text(
                                                      'Sind Sie sicher, dass Sie diesen Eintrag löschen möchten?'),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(),
                                                      child: const Text(
                                                          'Abbrechen'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        await deleteDatenObjekt(
                                                            objektKey);
                                                        Navigator.of(context)
                                                            .pop(); // Schließt das Dialogfenster
                                                      },
                                                      child:
                                                          const Text('Löschen'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class DatenKarte extends StatelessWidget {
  final MeinDatenmodell item;

  const DatenKarte({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = item.bildBytes != null
        ? Image.memory(item.bildBytes!,
            fit: BoxFit.cover, width: double.infinity, height: 200)
        : (item.bildUrl != null
            ? Image.asset(item.bildUrl!,
                fit: BoxFit.cover, width: double.infinity, height: 200)
            : const SizedBox(height: 200));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Bild als Hintergrund
          Positioned.fill(
            child: imageWidget,
          ),
          // Wort-Text oben mit Hintergrund
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.white
                  .withOpacity(0.8), // Leicht durchsichtiger Hintergrund
              child:
                  Text(item.wort, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
          // Satz-Text unten mit Hintergrund
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                  left: 8.0, right: 8.0, top: 8.0, bottom: 8.0),
              color: Colors.white
                  .withOpacity(0.8), // Leicht durchsichtiger Hintergrund
              child:
                  Text(item.satz, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}
