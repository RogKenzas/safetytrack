import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/dashboard/dashboard_header.dart';
import '../../components/forms/custom_search_bar.dart';
import '../../components/dashboard/map_placeholder.dart';
import '../../components/dashboard/info_card.dart';
import '../../components/dashboard/custom_bottom_navbar.dart';
import '../route_tracking_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final List<String> _titles = ['Accueil', 'Planning', 'Historique', 'Urgence'];
  late ValueNotifier<DateTime> _now;
  @override
  void initState() {
    super.initState();
    _now = ValueNotifier(DateTime.now());
    // Mettre à jour l'heure chaque seconde
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      _now.value = DateTime.now();
      return mounted;
    });
  }

  @override
  void dispose() {
    _now.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Column(
        children: [
          const DashboardHeader(),
          if (_selectedIndex == 0)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  // vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MapPlaceholder(
                      onTap: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (context) => Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF179D5B),
                                ),
                              ),
                        );
                        await Future.delayed(Duration(seconds: 5));
                        if (context.mounted) {
                          Navigator.of(context).pop(); // Ferme le loader
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RouteTrackingScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox.shrink(),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16),
                            SizedBox(width: 7),
                            ValueListenableBuilder<DateTime>(
                              valueListenable: _now,
                              builder: (context, now, _) {
                                final formatted =
                                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} AM';
                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    formatted,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Color(0xFF1A1B1A),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.15,
                      children: const [
                        InfoCard(
                          title: 'Arrivé',
                          subtitle: 'Statut : À l’heure',
                          icon: Icons.check_circle,
                          status: 'Heure d’arrivée : 9:17',
                        ),
                        InfoCard(
                          title: 'Départ',
                          subtitle: 'Départ : 3:05',
                          icon: Icons.directions_bus,
                          status: 'Clôture : 15:00',
                        ),
                        InfoCard(
                          title: 'Pause déjeuner',
                          subtitle: 'Début : 12:00',
                          icon: Icons.timer,
                          value: '06:44:35',
                          child: LinearProgressIndicator(
                            value: 0.5,
                            backgroundColor: Color(0xFFE8F5EF),
                            color: Color(0xFF179D5B),
                          ),
                        ),
                        InfoCard(
                          title: 'Événement',
                          subtitle: 'Exposition scientifique',
                          icon: Icons.event,
                          status: 'Aujourd’hui, 13h',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  'Section à venir...',
                  style: GoogleFonts.poppins(fontSize: 18),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}
