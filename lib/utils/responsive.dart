import 'package:flutter/material.dart';

class Responsive {
  // Ancho de referencia basado en mi pantalla 
  static const double designWidth = 1440;
  static const double designHeight = 900;

  static double scaleWidth(BuildContext context) {
    return MediaQuery.of(context).size.width / designWidth;
  }

  static double scaleHeight(BuildContext context) {
    return MediaQuery.of(context).size.height / designHeight;
  }

  static double fontSize(BuildContext context, double size) {
    return size * scaleWidth(context);
  }

  static double padding(BuildContext context, double size) {
    return size * scaleWidth(context);
  }

  static double margin(BuildContext context, double size) {
    return size * scaleWidth(context);
  }

  static double width(BuildContext context, double size) {
    return size * scaleWidth(context);
  }

  static double height(BuildContext context, double size) {
    return size * scaleHeight(context);
  }

  static double cardWidth(BuildContext context, double baseWidth) {
    final scale = scaleWidth(context);
    double result = baseWidth * scale;
    return result.clamp(180.0, 280.0);
  }

  static double cardHeight(BuildContext context, double baseHeight) {
    final scale = scaleWidth(context);
    double result = baseHeight * scale;
    return result.clamp(240.0, 340.0);
  }
}