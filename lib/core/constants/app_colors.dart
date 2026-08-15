import 'package:flutter/material.dart';

/// Design tokens for Antigravity AI Mobile Companion
class AppColors {
  // Backgrounds - Deep Obsidian & Void Dark
  static const Color background = Color(0xFF0D0F14);
  static const Color surface = Color(0xFF161922);
  static const Color surfaceElevated = Color(0xFF1E222E);
  static const Color surfaceCard = Color(0xFF222736);
  static const Color surfaceCardGlass = Color(0xCC1A1E29);
  static const Color surfaceBorder = Color(0xFF2B3242);
  static const Color surfaceBorderHighlight = Color(0xFF3E475E);

  // Brand Accents - Electric Cyan & Galactic Indigo
  static const Color primary = Color(0xFF00E5FF); // Electric Cyan
  static const Color primaryLight = Color(0xFF6EFAFF);
  static const Color primaryDark = Color(0xFF00A8BD);
  static const Color secondary = Color(0xFF7C4DFF); // Deep Purple
  static const Color accentIndigo = Color(0xFF6366F1);

  // Status Indicators
  static const Color statusWorking = Color(0xFF00E5FF); // Cyan
  static const Color statusIdle = Color(0xFF94A3B8); // Slate
  static const Color statusSuccess = Color(0xFF10B981); // Emerald Green
  static const Color statusWarning = Color(0xFFF59E0B); // Amber / Warning
  static const Color statusError = Color(0xFFEF4444); // Red / Danger
  static const Color statusApproval = Color(0xFFFF9100); // Glowing Orange
  static const Color statusPaused = Color(0xFF8B5CF6); // Violet

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textInverse = Color(0xFF0F172A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient approvalGradient = LinearGradient(
    colors: [Color(0xFFFF9100), Color(0xFFFF5252)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E222E), Color(0xFF161922)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
