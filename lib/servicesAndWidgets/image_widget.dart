import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageWidget extends StatelessWidget {
  final String? imagePath;
  final Uint8List? imageBytes;

  const ImageWidget({
    Key? key,
    this.imagePath,
    this.imageBytes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageBytes != null) {
      imageWidget = Image.memory(imageBytes!, fit: BoxFit.cover);
    } else if (imagePath != null && imagePath!.isNotEmpty) {
      imageWidget = Image.asset(imagePath!, fit: BoxFit.cover);
    } else {
      imageWidget = Container(
        color: Colors.grey,
        child: const Icon(Icons.image, color: Colors.white),
      );
    }

    // Anpassung für die maximale Größe
    return ConstrainedBox(
      constraints: const BoxConstraints(
        // Setzt die maximale Größe
        maxWidth: 400,
        maxHeight: 400,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(20), // Abgerundete Ecken für das Bild
            child: FittedBox(
              fit: BoxFit.cover, // Bild füllt den Container aus
              child: imageWidget, // Das Bild-Widget
            ),
          ),
        ),
      ),
    );
  }
}
