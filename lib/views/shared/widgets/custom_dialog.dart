// Diálogo de confirmación reutilizable
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomConfirmDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    IconData icon = Icons.warning_amber_rounded,
    Color? confirmColor,
  }) {
    final color = confirmColor ?? const Color(0xFFFC6707);

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 45,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 300,
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 110,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                      foregroundColor: const Color(0xFF666666),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: BorderSide.none,
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}