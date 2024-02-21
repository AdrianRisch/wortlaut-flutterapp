import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'my_text_theme_dark.dart';

ThemeData darkTheme = ThemeData(
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    textTheme: myTextThemeDark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.highContrastDark(),
    hintColor: Colors.white,
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 1500),
    ));
