import 'package:flutter/material.dart';
import 'my_text_theme_light.dart';

ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.highContrastLight(),
    textTheme: myTextThemeLight,
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 1500),
    ));
