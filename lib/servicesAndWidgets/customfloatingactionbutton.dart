// custom_floating_action_button.dart
import 'package:flutter/material.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttonText;

  const CustomFloatingActionButton({
    super.key,
    required this.onPressed,
    this.buttonText = "Überprüfen",
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 60),
          textStyle: Theme.of(context).textTheme.displaySmall,
        ),
        child: Text(buttonText),
      ),
    );
  }
}
