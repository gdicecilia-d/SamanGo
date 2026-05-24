// Modelo que representa cada bloque de compromiso (Misión, Visión, Objetivo)
import 'package:flutter/material.dart';

class CommitmentModel {
  final String title;
  final String description;
  final Color backgroundColor;
  final Color titleColor;

  const CommitmentModel({
    required this.title,
    required this.description,
    this.backgroundColor = const Color(0xFFFDDBB3),
    this.titleColor = const Color(0xFFFC6707),
  });
}