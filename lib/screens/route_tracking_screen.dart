import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RouteTrackingScreen extends StatelessWidget {
  const RouteTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          // Fond carte (image)
          Positioned.fill(
            child: Image.asset(
              'assets/img/map_placeholder.png',
              fit: BoxFit.cover,
            ),
          ),
          // Header retour overlay
          Positioned(
            top: 44,
            left: 16,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF179D5B),
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 120,
            left: 20,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
              ],
            ),
          ),
          Positioned(
            bottom: 120,
            right: 20,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(width: 1.0, color: Colors.black),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.map, color: Color(0xFF179D5B)),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF179D5B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.10,
            minChildSize: 0.10,
            maxChildSize: 0.35,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barre de drag
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 10),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: AssetImage(
                                'assets/img/google.png',
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Position Actuelle',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '3.730 Rue Ngoa Ekelle, Yaounde',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Color(0xFF7A7A7A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.battery_full,
                                  color: Color(0xFF179D5B),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '72 %',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Affichage étendu
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 18,
                          left: 18,
                          right: 18,
                        ),
                        child: Row(
                          children: [
                            // Home
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.home,
                                  color: Color(0xFF179D5B),
                                ),
                                label: Text(
                                  'Maison',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE8F5EF),
                                  foregroundColor: const Color(0xFF179D5B),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // School
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.location_city,
                                  color: Color(0xFFBDBDBD),
                                ),
                                label: Text(
                                  'Ecole',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFBDBDBD),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Color(0xFFE8E8E8)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Peter's home
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.person_pin_circle,
                                  color: Color(0xFFBDBDBD),
                                ),
                                label: Text(
                                  "Maison Ken..",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFBDBDBD),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Color(0xFFE8E8E8)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Divider(color: Color(0xFFE8E8E8), thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lieu',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Color(0xFFBDBDBD),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Maison',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Addressw',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Color(0xFFBDBDBD),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '3.730 Rue Ngoa Ekelle, Yaounde',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
