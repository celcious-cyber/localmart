import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AppAlert {
  /// Success Alert - Green Glassmorphism
  static void success(String title, String message) {
    HapticFeedback.lightImpact();
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      colorText: Colors.black87,
      borderRadius: 16,
      margin: const EdgeInsets.all(15),
      borderWidth: 1,
      borderColor: Colors.white.withValues(alpha: 0.3),
      barBlur: 10,
      forwardAnimationCurve: Curves.easeOutBack,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
      titleText: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
      messageText: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.black54,
        ),
      ),
    );
  }

  /// Error Alert - Red Glassmorphism
  static void error(String title, String message) {
    HapticFeedback.mediumImpact();
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      colorText: Colors.black87,
      borderRadius: 16,
      margin: const EdgeInsets.all(15),
      borderWidth: 1,
      borderColor: Colors.red.withValues(alpha: 0.2), // Slight red tint for border
      barBlur: 10,
      forwardAnimationCurve: Curves.easeOutBack,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
      boxShadows: [
        BoxShadow(
          color: Colors.red.withValues(alpha: 0.05),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
      titleText: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.red[800],
        ),
      ),
      messageText: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.black54,
        ),
      ),
    );
  }

  /// Info/Warning Alert - Orange Glassmorphism
  static void info(String title, String message) {
    HapticFeedback.selectionClick();
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      colorText: Colors.black87,
      borderRadius: 16,
      margin: const EdgeInsets.all(15),
      borderWidth: 1,
      borderColor: Colors.orange.withValues(alpha: 0.2),
      barBlur: 10,
      forwardAnimationCurve: Curves.easeOutBack,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 28),
      boxShadows: [
        BoxShadow(
          color: Colors.orange.withValues(alpha: 0.05),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
      titleText: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.orange[800],
        ),
      ),
      messageText: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.black54,
        ),
      ),
    );
  }

  /// Confirmation Dialog
  static void confirm(BuildContext context, String title, String message, {required VoidCallback onConfirm, String confirmText = 'Konfirmasi'}) {
    Get.defaultDialog(
      title: title,
      middleText: message,
      titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
      middleTextStyle: GoogleFonts.poppins(fontSize: 14),
      backgroundColor: Colors.white,
      radius: 16,
      textConfirm: confirmText,
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.orange,
      onConfirm: () {
        Get.back();
        onConfirm();
      },
    );
  }
}
