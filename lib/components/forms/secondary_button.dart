import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? iconColor;
  final String? imageAsset;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.iconColor,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFF179D5B), width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageAsset != null) ...[
            Image.asset(imageAsset!, width: 24, height: 24),
            const SizedBox(width: 8),
          ] else if (icon != null) ...[
            Icon(icon, color: iconColor ?? const Color(0xFF179D5B), size: 22),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
