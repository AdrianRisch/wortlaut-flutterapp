import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'db/datenmodell.dart';
import 'pages/home_page.dart';
import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';
import 'package:flutter/semantics.dart';

void main() async {
  //debugPaintSizeEnabled = true;
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(MeinDatenmodellAdapter());
  Hive.registerAdapter(CategoriesAdapter());
  var masterDbBox = await Hive.openBox<MeinDatenmodell>('master_db');
  var categoriesDbBox = await Hive.openBox<Categories>('categories_db');

  if (masterDbBox.isEmpty || categoriesDbBox.isEmpty) {
    await loadData(); // Daten laden, wenn eine der Boxen leer ist
  }

  runApp(const MyApp());
  SemanticsBinding.instance.ensureSemantics();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      title: 'Wortlaut',
      home:
          const HomePage(), // Direkter Start der HomePage ohne Authentifizierung
    );
  }
}
