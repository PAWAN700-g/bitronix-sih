import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Clean Water Cyber Palette
  static const Color primary = Color(0xFF0077AE); // Vibrant Cyan / Deep Water Blue
  static const Color primaryLight = Color(0xFF33A4DC);
  static const Color primaryDark = Color(0xFF004E75);
  static const Color secondary = Color(0xFF00B4D8);
  static const Color accent = Color(0xFF90E0EF);

  // Status & Health Colors
  static const Color excellent = Color(0xFF10B981); // Green
  static const Color good = Color(0xFF0EA5E9);      // Light Blue
  static const Color moderate = Color(0xFFF59E0B);  // Amber/Yellow
  static const Color poor = Color(0xFFEF4444);      // Red
  static const Color critical = Color(0xFFDC2626);  // Deep Red

  // Severity Colors
  static const Color severityCritical = Color(0xFFEF4444);
  static const Color severityWarning = Color(0xFFF59E0B);
  static const Color severityInfo = Color(0xFF3B82F6);

  // Light Theme Neutral Colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark Theme Neutral Colors
  static const Color darkBackground = Color(0xFF0B132B);
  static const Color darkSurface = Color(0xFF1C2541);
  static const Color darkSurfaceVariant = Color(0xFF2E3A59);
  static const Color darkBorder = Color(0xFF3A4B6E);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Sensor Accent Colors
  static const Color phColor = Color(0xFF8B5CF6);        // Purple
  static const Color tdsColor = Color(0xFF3B82F6);       // Blue
  static const Color turbidityColor = Color(0xFF14B8A6); // Teal
  static const Color tempColor = Color(0xFFF97316);      // Orange
}
