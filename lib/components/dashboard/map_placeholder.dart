import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MapPlaceholder extends StatelessWidget {
  final VoidCallback? onTap;
  const MapPlaceholder({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              // height: double.infinity,
              // width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                // color: const Color(0xFFE8F5EF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'assets/img/map_placeholder.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            height: 250,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              // color: const Color(0xFFE8F5EF),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 30.0, left: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  '23°C 🌥️',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF179D5B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
