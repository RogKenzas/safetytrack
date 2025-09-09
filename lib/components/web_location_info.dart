import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import '../utils/web_location_helper.dart';

/// Widget d'information pour les restrictions de géolocalisation web
class WebLocationInfo extends StatelessWidget {
  final VoidCallback? onDismiss;
  final bool showAlways;

  const WebLocationInfo({super.key, this.onDismiss, this.showAlways = false});

  @override
  Widget build(BuildContext context) {
    // Ne s'afficher que sur le web
    if (!kIsWeb) return const SizedBox.shrink();

    // Vérifier si HTTPS est requis
    final needsHttps = WebLocationHelper.isHttpsRequired;
    final isSupported = WebLocationHelper.isGeolocationSupported;

    // Ne s'afficher que si nécessaire
    if (!showAlways && !needsHttps && isSupported) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            needsHttps
                ? Colors.orange.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              needsHttps
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                needsHttps ? Icons.warning : Icons.info,
                color: needsHttps ? Colors.orange[700] : Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                needsHttps ? 'Géolocalisation limitée' : 'Mode web',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: needsHttps ? Colors.orange[700] : Colors.blue[700],
                ),
              ),
              const Spacer(),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            needsHttps
                ? 'La géolocalisation nécessite HTTPS en production. Utilisez une position par défaut.'
                : 'Certaines fonctionnalités de géolocalisation peuvent être limitées sur le web.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          if (needsHttps) ...[
            const SizedBox(height: 8),
            Text(
              'Pour une expérience complète, utilisez l\'application mobile.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
