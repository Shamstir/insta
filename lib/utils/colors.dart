import 'package:flutter/material.dart';

// Dark theme colors (default)
const mobileBackgroundColor = Color.fromRGBO(0, 0, 0, 1);
const webBackgroundColor = Color.fromRGBO(0, 0, 0, 1);
const mobileSearchColor = Color.fromRGBO(38, 38, 38, 1);
const blueColor = Color.fromRGBO(0, 149, 246, 1);
const primaryColor = Colors.white;
const secondaryColor = Colors.grey;

// Light theme colors
const lightMobileBackgroundColor = Colors.white;
const lightWebBackgroundColor = Colors.white;
const lightMobileSearchColor = Color.fromRGBO(250, 250, 250, 1);
const lightPrimaryColor = Colors.black;
const lightSecondaryColor = Colors.grey;

// Theme-aware color getters
Color getBackgroundColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? mobileBackgroundColor
      : lightMobileBackgroundColor;
}

Color getPrimaryColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? primaryColor
      : lightPrimaryColor;
}

Color getSecondaryColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? secondaryColor
      : lightSecondaryColor;
}

Color getSearchColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? mobileSearchColor
      : lightMobileSearchColor;
}
