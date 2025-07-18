import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? value;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final Color? statusColor;
  final String? status;
  final Widget? child;

  const InfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.icon,
    this.iconColor,
    this.trailing,
    this.statusColor,
    this.status,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: iconColor ?? const Color(0xFF179D5B),
                  size: 22,
                ),
              if (icon != null) const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          if (value != null) ...[
            const SizedBox(height: 8),
            Text(
              value!,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
          if (child != null) ...[const SizedBox(height: 8), child!],
          SizedBox(height: 35),
          if (status != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: statusColor ?? const Color(0xFF179D5B),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  status!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: statusColor ?? const Color(0xFF179D5B),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
