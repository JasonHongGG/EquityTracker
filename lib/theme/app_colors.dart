import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color backgroundDark = Color(0xFF0F111A); // Deep Void Blue
  static const Color backgroundLight = Color(0xFFF5F7FA); // Soft Grey-White

  static const Color surfaceDark = Color(0xFF1E2130);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // Accents
  static const Color primary = Color(0xFF7B61FF); // Royal Purple
  static const Color secondary = Color(0xFF00C6FB); // Electric Blue

  static const Color income = Color(0xFF00F2A9); // Neon Mint
  static const Color expense = Color(0xFFFF4769); // Electric Coral

  // Gradients
  static const LinearGradient backgroundGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F111A), Color(0xFF161925)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7B61FF), Color(0xFF00C6FB)],
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF00F2A9), Color(0xFF00D28E)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF4769), Color(0xFFE03152)],
  );

  // Text
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFAAB2C8);

  static const Color textPrimaryLight = Color(0xFF1A1D2B);
  static const Color textSecondaryLight = Color(0xFF6E768C);
}
