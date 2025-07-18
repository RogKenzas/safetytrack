import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../forms/custom_search_bar.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 48,
            left: 24,
            right: 24,
            bottom: 14,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF179D5B),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Bonjour, Kenzas !',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF179D5B),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomSearchBar(hintText: 'Rechercher...'),
            ],
          ),
        ),
      ],
    );
  }
}
