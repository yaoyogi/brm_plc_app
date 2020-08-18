import 'package:flutter/material.dart';

final appTheme = ThemeData(
  brightness: Brightness.dark,

  primaryColor: Colors.lightBlue[800],
  accentColor: Colors.cyan[600],
  primarySwatch: Colors.orange,

  fontFamily: 'Georgia',

  textTheme: TextTheme(
    display4: TextStyle(
      fontFamily: 'Corben',
      fontWeight: FontWeight.w700,
      fontSize: 24,
      color: Colors.black,
    ),
  ),
);
