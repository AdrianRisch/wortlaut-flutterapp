import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servicesAndWidgets/customfloatingactionbutton.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  FeedbackPageState createState() => FeedbackPageState();
}

class FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  final TextEditingController _themaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restoreTextContent();
    _feedbackController.addListener(_saveTextContent);
    _contactInfoController.addListener(_saveTextContent);
    _themaController.addListener(_saveTextContent);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _contactInfoController.dispose();
    _themaController.dispose();
    super.dispose();
  }

  void _saveTextContent() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('feedbackText', _feedbackController.text);
    await prefs.setString('contactInfoText', _contactInfoController.text);
    await prefs.setString('themaText', _themaController.text);
  }

  void _restoreTextContent() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _feedbackController.text = prefs.getString('feedbackText') ?? '';
    _contactInfoController.text = prefs.getString('contactInfoText') ?? '';
    _themaController.text = prefs.getString('themaText') ?? '';
  }

  void _submitFeedback() {
    if (_feedbackController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Bitte fülle das Pflichtfeld aus"),
        duration: Duration(seconds: 5),
      ));
      return;
    }
    ;
    FirebaseFirestore.instance.collection('feedbacks').add({
      'subject': _themaController.text,
      'feedback': _feedbackController.text,
      'createdAt': Timestamp.now(),
      'kontakt': _contactInfoController.text,
    }).then((docRef) {
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Feedback erfolgreich gesendet"),
        duration: Duration(seconds: 5),
      ));
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Fehler beim Senden: $error"),
        duration: const Duration(seconds: 5),
      ));
    });
  }

  void _resetForm() {
    _feedbackController.clear();
    _themaController.clear();
  }

  Widget _buildTextInputField(
      {required String label, required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        keyboardType: TextInputType.multiline,
        maxLines: null,
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double maxWidth = MediaQuery.of(context).size.width > 820 ? 800 : 400;
    return Scaffold(
        appBar: AppBar(title: const Text('Deine Meinung')),
        floatingActionButton:
            CustomFloatingActionButton(onPressed: _submitFeedback),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment
                      .center, // Zentriert die Widgets innerhalb der Spalte
                  children: [
                    Text(
                      "Deine Meinung ist uns wichtig.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 40),
                    Semantics(
                      label: "optional: Kontaktdaten",
                      child: _buildTextInputField(
                          label: "Kontaktdaten",
                          controller: _contactInfoController),
                    ),
                    Semantics(
                      label: "optional: Anliegen",
                      child: _buildTextInputField(
                          label: "Anliegen", controller: _themaController),
                    ),
                    Semantics(
                      label: "Pflicht: Deine Meinung hier:*",
                      child: _buildTextInputField(
                          label: "Deine Meinung hier:*",
                          controller: _feedbackController),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
