import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlaceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String? address;
  final String? distanceText;
  final double progressValue;
  final String ctaText;
  final bool loading;
  final VoidCallback onCta;
  final VoidCallback? onDetails;

  const PlaceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.address,
    required this.distanceText,
    required this.progressValue,
    required this.ctaText,
    required this.loading,
    required this.onCta,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 700,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (onDetails != null)
                IconButton(
                  onPressed: onDetails,
                  icon: const Icon(Icons.info_outline, color: Colors.grey),
                  tooltip: 'Détails',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            address ?? 'Aucune adresse enregistrée',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressValue.clamp(0.0, 1.0),
                    backgroundColor: color.withOpacity(0.12),
                    color: color,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                distanceText ?? '-',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
