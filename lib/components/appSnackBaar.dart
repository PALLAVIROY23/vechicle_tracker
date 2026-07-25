import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  static void show({
    required String title,
    required String message,
    required SnackbarType type,
  }) {
    Color borderColor;
    Color iconColor;
    IconData icon;
    Color messageColor;

    switch (type) {
      case SnackbarType.success:
        borderColor = Colors.green;
        iconColor = Colors.green;
        icon = Icons.check_circle;
        messageColor = Colors.black87;
        break;

      case SnackbarType.error:
        borderColor = Colors.red;
        iconColor = Colors.red;
        icon = Icons.close;
        messageColor = Colors.red;
        break;

      case SnackbarType.info:
        borderColor = Colors.orange;
        iconColor = Colors.orange;
        icon = Icons.info;
        messageColor = Colors.black87;
        break;
    }

    Get.snackbar(
      "",
      "",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.zero,
      duration: const Duration(seconds: 3),
      titleText: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: borderColor, width: 5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Title
                    Text(
                      title,
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // 🔹 Message
                    Text(message, style: TextStyle(color: messageColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void success(String message) {
    show(title: "Success", message: message, type: SnackbarType.success);
  }

  static void error(String message) {
    show(title: "Failed", message: message, type: SnackbarType.error);
  }

  static void info(String message) {
    show(title: "Info", message: message, type: SnackbarType.info);
  }
}

enum SnackbarType { success, error, info }
