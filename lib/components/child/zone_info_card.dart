import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ZoneInfoCard extends StatelessWidget {
  final Map<String, dynamic> zone;
  final VoidCallback onTap;

  const ZoneInfoCard({
    super.key,
    required this.zone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color zoneColor = zone['color'] ?? Colors.red;
    final String zoneName = zone['name'] ?? 'Zone inconnue';
    final String zoneAddress = zone['address'] ?? 'Adresse non spécifiée';
    final String zoneType = zone['type'] ?? 'unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône de la zone
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: zoneColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getZoneIcon(zoneType),
                    color: zoneColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informations de la zone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zoneName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        zoneAddress,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: zoneColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getZoneTypeLabel(zoneType),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: zoneColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bouton de navigation
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: zoneColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.navigation,
                    color: zoneColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getZoneIcon(String type) {
    switch (type) {
      case 'school':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'park':
        return Icons.park;
      case 'hospital':
        return Icons.local_hospital;
      case 'shopping':
        return Icons.shopping_cart;
      default:
        return Icons.location_on;
    }
  }

  String _getZoneTypeLabel(String type) {
    switch (type) {
      case 'school':
        return 'École';
      case 'home':
        return 'Maison';
      case 'work':
        return 'Travail';
      case 'park':
        return 'Parc';
      case 'hospital':
        return 'Hôpital';
      case 'shopping':
        return 'Commerce';
      default:
        return 'Zone';
    }
  }
}
