import 'package:flutter/material.dart';
import 'edit_page.dart';
import 'exercises/sentenceorder_page.dart';
import 'exercises/speech_page.dart';
import 'exercises/spellcheckergame_page.dart';
import 'feedback_page.dart';
import 'exercises/randomexercisis_page.dart';
import 'exercises/guessthepicturegame_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> allPages = [
    {'page': const SpeechPage(), 'label': "Sprache"},
    {'page': const RandomExercisesPage(), 'label': 'Zufällige Wörter'},
    {'page': const GuessThePictureGamePage(), 'label': "Fotoquiz"},
    {'page': const SpellCheckerGamePage(), 'label': "Wort Wirbel"},
    {'page': const SentenceOrderPage(), 'label': "Satz Baumeister"},
    {'page': const FeedbackPage(), 'label': 'Feedback'},
    {'page': const ImageAddForm(), 'label': 'Daten hinzufügen'},
  ];

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = MediaQuery.of(context).size.width > 820 ? 4 : 2;

    return Scaffold(
      appBar: AppBar(
          title: Text(
        'Home',
        style: Theme.of(context).textTheme.headlineLarge,
      )),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 1.1, // Creates square tiles
          ),
          itemCount: allPages.length,
          itemBuilder: (context, index) {
            return Tooltip(
              enableFeedback: true,
              triggerMode: TooltipTriggerMode.longPress,
              message: allPages[index]['label'],
              child: Card(
                borderOnForeground: true,
                elevation: 5, // Adds the shadow effect
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), // Rounded corners
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => allPages[index]['page']),
                    );
                  },
                  child: Center(
                    child: Text(
                      allPages[index]['label'],
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
