import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safetytrack/screens/add_alert_zone.dart';
import '../../components/dashboard/dashboard_header.dart';
import '../../components/dashboard/enhanced_map_widget.dart';
// import '../../components/dashboard/children_status_card.dart';
import 'package:provider/provider.dart';
// import '../../components/dashboard/info_card.dart';
import '../../components/dashboard/custom_bottom_navbar.dart';
import '../route_tracking_screen.dart';
import '../panic_alert_screen.dart';
import '../../services/map_service.dart';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../../services/auth_service.dart';
import '../../services/auth_state_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart' as location_package;
// import '../../components/forms/custom_search_bar.dart';
// import '../../components/forms/custom_text_field.dart';
// import '../address/add_address_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  // final List<String> _titles = ['Accueil', 'Adresse', 'Historique', 'Urgence'];
  late ValueNotifier<DateTime> _now;
  final MapService _mapService = MapService();
  final AuthService _authService = AuthService();
  Timer? _proximityTimer;
  bool _isMonitoring = false;
  Map<String, dynamic>? _homeAddress;
  Map<String, dynamic>? _schoolAddress;
  // Etat pour l'onglet Adresse (inspiré de add_address_screen)
  LatLng? _addrCurrentPosition;
  bool _addrLoadingLocation = true;
  String _addrSelectedType = 'Maison';
  final List<String> _addrTypes = ['Maison', 'École', 'Autre'];
  String _addrAddress = 'Position en cours...';
  String _addrName = 'Maison';
  LatLng _addrMapCenter = LatLng(3.848033, 11.502075);
  // final TextEditingController _addrSearchController = TextEditingController();
  final MapController _addrMapController = MapController();
  List<Map<String, dynamic>> _addrUserAddresses = [];
  List<Map<String, dynamic>> _addrRiskZones = [];
  // List<Map<String, dynamic>> _addrChildrenAddresses = [];
  List<Map<String, dynamic>> _addrChildrenLocations = [];
  @override
  void initState() {
    super.initState();
    _now = ValueNotifier(DateTime.now());
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      _now.value = DateTime.now();
      return mounted;
    });
    _startProximityMonitoring();
    _initPlaces();
    _addrGetCurrentLocation();
    _addrLoadMapData();
    _addrStopSpinnerFallback();
  }

  Widget _buildChildrenConnectivityCard(String parentUid) {
    final firestore = FirebaseFirestore.instance;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('users').doc(parentUid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data();
        final children =
            (data?['children'] as List<dynamic>? ?? [])
                .whereType<Map<String, dynamic>>()
                .toList();

        // Un enfant est considéré "Opérationnel" si son document contient
        // currentLocation.lastUpdate < 2 minutes
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF179D5B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.wifi_tethering,
                      color: Color(0xFF179D5B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Statut des appareils',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (children.isEmpty)
                Text(
                  'Aucun enfant lié pour le moment.',
                  style: GoogleFonts.poppins(color: Colors.grey.shade700),
                )
              else
                ...children.map((child) {
                  final childUid = child['uid'] as String?;
                  final childName = (child['name'] as String?) ?? 'Enfant';
                  if (childUid == null) {
                    return const SizedBox.shrink();
                  }
                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream:
                        firestore.collection('users').doc(childUid).snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData || !snap.data!.exists) {
                        return _childStatusTile(
                          name: childName,
                          status: 'Hors ligne',
                          color: Colors.grey,
                          icon: Icons.portable_wifi_off,
                          subtitle: 'Aucune donnée',
                        );
                      }
                      final cdata = snap.data!.data();
                      final currentLocation =
                          (cdata?['currentLocation']
                              as Map<String, dynamic>?) ??
                          {};
                      DateTime? lastUpdate;
                      try {
                        final raw = currentLocation['lastUpdate'] as String?;
                        if (raw != null) lastUpdate = DateTime.parse(raw);
                      } catch (_) {}
                      final now = DateTime.now();
                      final isOnline =
                          lastUpdate != null &&
                          now.difference(lastUpdate).inMinutes < 2;
                      final status = isOnline ? 'Opérationnel' : 'Hors ligne';
                      final color =
                          isOnline ? const Color(0xFF179D5B) : Colors.grey;
                      final icon =
                          isOnline
                              ? Icons.check_circle
                              : Icons.portable_wifi_off;
                      final subtitle =
                          lastUpdate != null
                              ? 'Dernier signal: ${lastUpdate.toLocal()}'
                              : 'Aucune donnée';

                      final double? lat =
                          (currentLocation['latitude'] as num?)?.toDouble();
                      final double? lon =
                          (currentLocation['longitude'] as num?)?.toDouble();

                      return GestureDetector(
                        onLongPress: () async {
                          HapticFeedback.heavyImpact();
                          await _openChildDetailsModal(
                            childName: childName,
                            lastUpdate: lastUpdate,
                            latitude: lat,
                            longitude: lon,
                            isOnline: isOnline,
                          );
                        },
                        child: _childStatusTile(
                          name: childName,
                          status: status,
                          color: color,
                          icon: icon,
                          subtitle: subtitle,
                        ),
                      );
                    },
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _childStatusTile({
    required String name,
    required String status,
    required Color color,
    required IconData icon,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChildDetailsModal({
    required String childName,
    required DateTime? lastUpdate,
    required double? latitude,
    required double? longitude,
    required bool isOnline,
  }) async {
    String address = 'Adresse indisponible';
    if (latitude != null && longitude != null) {
      try {
        address = await _mapService.getAddressFromLatLng(
          LatLng(latitude, longitude),
        );
      } catch (_) {}
    }

    final statusColor = isOnline ? const Color(0xFF179D5B) : Colors.grey;
    final statusText = isOnline ? 'Opérationnel' : 'Hors ligne';
    final whenText = lastUpdate != null ? '${lastUpdate.toLocal()}' : 'Jamais';

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header with child info
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(0.8),
                            Colors.purple.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            childName,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusText,
                                  style: GoogleFonts.poppins(
                                    color: statusColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Connection info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dernière connexion',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              whenText,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Location info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.place,
                          color: Colors.purple.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dernière position',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (latitude != null && longitude != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ).copyWith(fontFamily: 'monospace'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            latitude != null && longitude != null
                                ? () {
                                  _addrMapController.move(
                                    LatLng(latitude, longitude),
                                    16,
                                  );
                                  Navigator.of(context).pop();
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF179D5B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.center_focus_strong, size: 20),
                        label: Text(
                          'Centrer sur la carte',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement call functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Fonctionnalité d\'appel à venir'),
                              backgroundColor: const Color(0xFF179D5B),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF179D5B),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(
                          Icons.phone,
                          size: 20,
                          color: Color(0xFF179D5B),
                        ),
                        label: Text(
                          'Appeler',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF179D5B),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Message button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement message functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Fonctionnalité de message à venir'),
                          backgroundColor: const Color(0xFF179D5B),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: Icon(
                      Icons.message,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    label: Text(
                      'Envoyer un message',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackingCard({
    required String title,
    required IconData icon,
    required Color color,
    required String? address,
    required String type,
  }) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Adresse
            if (address != null) ...[
              Text(
                address,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],

            // Graphique de traçabilité
            Expanded(child: _buildTrackingChart(type, color)),

            const SizedBox(height: 8),

            // Statistiques
            _buildTrackingStats(type, color),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingChart(String type, Color color) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: List.generate(7, (index) {
            final day = DateTime.now().subtract(Duration(days: 6 - index));
            final isToday = day.day == DateTime.now().day;
            final isWeekend =
                day.weekday == DateTime.saturday ||
                day.weekday == DateTime.sunday;

            // TODO: Remplacer par de vraies données de traçabilité depuis Firestore
            // Simulation de données de présence (à remplacer par de vraies données)
            final presenceHours =
                isWeekend ? 0.0 : (isToday ? 0.3 : 0.7 + (index * 0.1));

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: (presenceHours * 40).clamp(4.0, 40.0),
                      decoration: BoxDecoration(
                        color:
                            presenceHours > 0
                                ? color.withOpacity(0.8)
                                : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getDayAbbreviation(day.weekday),
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTrackingStats(String type, Color color) {
    // TODO: Remplacer par de vraies données de traçabilité depuis Firestore
    // Simulation de statistiques (à remplacer par de vraies données)
    final totalHours = type == 'home' ? '8h 30min' : '6h 15min';
    final lastVisit = type == 'home' ? 'Il y a 2h' : 'Il y a 4h';
    final visitsToday = type == 'home' ? '2 visites' : '1 visite';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temps total',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                totalHours,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dernière visite',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                lastVisit,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aujourd\'hui',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                visitsToday,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'L';
      case DateTime.tuesday:
        return 'M';
      case DateTime.wednesday:
        return 'M';
      case DateTime.thursday:
        return 'J';
      case DateTime.friday:
        return 'V';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'D';
      default:
        return '';
    }
  }

  Widget _buildHistorySection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF179D5B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history, color: Color(0xFF179D5B)),
              ),
              const SizedBox(width: 12),
              Text(
                'Historique des déplacements',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filtres
          _buildHistoryFilters(),
          const SizedBox(height: 16),

          // Liste d'historique
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildHistoryFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildFilterChip('Aujourd\'hui', true)),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterChip('Cette semaine', false)),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterChip('Ce mois', false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // TODO: Implémenter la logique de filtrage
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF179D5B) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    // TODO: Remplacer par de vraies données depuis Firestore
    final List<Map<String, dynamic>> historyData = [
      {
        'userName': 'Vous',
        'location': 'École Primaire de Yaoundé',
        'time': '14:30',
        'date': 'Aujourd\'hui',
        'type': 'school',
        'isChild': false,
      },
      {
        'userName': 'Marie',
        'location': 'Maison',
        'time': '13:45',
        'date': 'Aujourd\'hui',
        'type': 'home',
        'isChild': true,
      },
      {
        'userName': 'Vous',
        'location': 'Centre Commercial',
        'time': '12:15',
        'date': 'Aujourd\'hui',
        'type': 'other',
        'isChild': false,
      },
      {
        'userName': 'Paul',
        'location': 'École Primaire de Yaoundé',
        'time': '11:20',
        'date': 'Aujourd\'hui',
        'type': 'school',
        'isChild': true,
      },
    ];

    return Column(
      children: historyData.map((entry) => _buildHistoryItem(entry)).toList(),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> entry) {
    final String userName = entry['userName'] as String;
    final String location = entry['location'] as String;
    final String time = entry['time'] as String;
    final String date = entry['date'] as String;
    final String type = entry['type'] as String;
    final bool isChild = entry['isChild'] as bool;

    final Color typeColor = _getHistoryTypeColor(type);
    final IconData typeIcon = _getHistoryTypeIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  isChild
                      ? Colors.purple.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isChild ? Icons.person : Icons.account_circle,
              color: isChild ? Colors.purple : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Contenu principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, size: 12, color: typeColor),
                          const SizedBox(width: 4),
                          Text(
                            _getHistoryTypeLabel(type),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$time • $date',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Indicateur de statut
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isChild ? Colors.purple : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Color _getHistoryTypeColor(String type) {
    switch (type) {
      case 'home':
        return const Color(0xFF2196F3); // Bleu
      case 'school':
        return const Color(0xFF179D5B); // Vert
      case 'work':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFFFFC107); // Jaune
    }
  }

  IconData _getHistoryTypeIcon(String type) {
    switch (type) {
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      default:
        return Icons.location_on;
    }
  }

  String _getHistoryTypeLabel(String type) {
    switch (type) {
      case 'home':
        return 'Maison';
      case 'school':
        return 'École';
      case 'work':
        return 'Travail';
      default:
        return 'Autre';
    }
  }

  @override
  void dispose() {
    _now.dispose();
    _proximityTimer?.cancel();
    super.dispose();
  }

  Future<void> _addrLoadMapData() async {
    try {
      final addresses = await _authService.getCurrentUserAddresses();
      final riskZones = await _authService.getCurrentUserRiskZones();
      final childrenLocations =
          await _authService.getCurrentUserChildrenLocations();
      if (!mounted) return;
      setState(() {
        _addrUserAddresses = addresses;
        _addrRiskZones = riskZones;
        // _addrChildrenAddresses = childrenAddresses;
        _addrChildrenLocations = childrenLocations;
      });
    } catch (_) {}
  }

  // Désactive le loader si la géolocalisation tarde (améliore l'UX)
  void _addrStopSpinnerFallback() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_addrLoadingLocation) {
        setState(() => _addrLoadingLocation = false);
      }
    });
  }

  List<Marker> _addrBuildMarkers() {
    final List<Marker> markers = [];

    if (_addrCurrentPosition != null) {
      markers.add(
        Marker(
          point: _addrCurrentPosition!,
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: GestureDetector(
            onLongPress: () {
              HapticFeedback.heavyImpact();
              _openMarkerDetails(
                position: _addrCurrentPosition!,
                title: 'Votre position',
                icon: Icons.gps_fixed,
                color: Colors.grey,
              );
            },
            child: _addrBuildUserMarker(),
          ),
        ),
      );
    }

    for (final address in _addrUserAddresses) {
      final lat = (address['latitude'] as num?)?.toDouble();
      final lng = (address['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final type = (address['type'] as String?) ?? 'Autre';
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: GestureDetector(
            onLongPress: () {
              HapticFeedback.heavyImpact();
              _openMarkerDetails(
                position: LatLng(lat, lng),
                title:
                    (address['name'] as String?) ??
                    (address['type'] as String?) ??
                    'Adresse',
                icon: _addrIconForAddressType(type),
                color: _addrColorForAddressType(type),
                savedAddress: address['address'] as String?,
                meta: {'type': type, 'createdAt': address['createdAt']},
              );
            },
            child: _addrBuildUserAddressMarker(type),
          ),
        ),
      );
    }

    for (final zone in _addrRiskZones) {
      final lat = (zone['latitude'] as num?)?.toDouble();
      final lng = (zone['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: GestureDetector(
            onLongPress: () {
              HapticFeedback.heavyImpact();
              _openMarkerDetails(
                position: LatLng(lat, lng),
                title: (zone['name'] as String?) ?? 'Zone à risque',
                icon: Icons.warning,
                color: Colors.red,
                savedAddress: zone['address'] as String?,
                meta: {
                  'type': (zone['type'] as String?) ?? 'risk',
                  'createdAt': zone['createdAt'],
                },
              );
            },
            child: _addrBuildRiskZoneMarker(),
          ),
        ),
      );
    }

    for (final child in _addrChildrenLocations) {
      final lat = (child['latitude'] as num?)?.toDouble();
      final lng = (child['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: GestureDetector(
            onLongPress: () {
              HapticFeedback.heavyImpact();
              _openMarkerDetails(
                position: LatLng(lat, lng),
                title: (child['name'] as String?) ?? 'Enfant',
                icon: Icons.person,
                color: Colors.purple,
                savedAddress: null,
                meta: {'lastUpdate': child['lastUpdate']},
              );
            },
            child: _addrBuildChildMarker('Autre'),
          ),
        ),
      );
    }

    return markers;
  }

  // Styles de marqueurs harmonisés avec AddAlertZone
  Widget _addrBuildUserMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          bottom: 18,
          child: Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.gps_fixed, size: 14, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _addrBuildChildMarker(String type) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          bottom: 18,
          child: Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.purple, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.person, size: 16, color: Colors.purple),
          ),
        ),
      ],
    );
  }

  Widget _addrBuildUserAddressMarker(String type) {
    final Color color = _addrColorForAddressType(type);
    final IconData icon = _addrIconForAddressType(type);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          bottom: 18,
          child: Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(child: Icon(icon, size: 16, color: color)),
        ),
      ],
    );
  }

  Widget _addrBuildRiskZoneMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          bottom: 18,
          child: Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.warning, size: 16, color: Colors.red),
          ),
        ),
      ],
    );
  }

  Color _addrColorForAddressType(String type) {
    switch (type) {
      case 'Maison':
      case 'home':
        return const Color(0xFF2196F3); // Bleu
      case 'École':
      case 'school':
        return const Color(0xFF179D5B); // Vert (thème app)
      default:
        return const Color(0xFFFFC107); // Jaune/Amber
    }
  }

  IconData _addrIconForAddressType(String type) {
    switch (type) {
      case 'Maison':
      case 'home':
        return Icons.home;
      case 'École':
      case 'school':
        return Icons.school;
      default:
        return Icons.location_on;
    }
  }

  Future<void> _openMarkerDetails({
    required LatLng position,
    required String title,
    required IconData icon,
    required Color color,
    String? savedAddress,
    Map<String, dynamic>? meta,
  }) async {
    String detailsAddress = savedAddress ?? 'Chargement...';
    if (savedAddress == null) {
      try {
        final addr = await _mapService.getAddressFromLatLng(position);
        detailsAddress = addr;
      } catch (_) {}
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Center(child: Icon(icon, color: color, size: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(detailsAddress, style: GoogleFonts.poppins(fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                'Coordonnées: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              if (meta != null &&
                  (meta['createdAt'] != null || meta['lastUpdate'] != null))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    meta['createdAt'] != null
                        ? 'Ajouté le: ${meta['createdAt']}'
                        : 'Dernière mise à jour: ${meta['lastUpdate']}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _addrMapController.move(position, 16);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF179D5B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(
                        Icons.center_focus_strong,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Centrer ici',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          // Si on a déjà un objet complet adresse/zones, on le partage tel quel
                          if (meta != null && meta.containsKey('type')) {
                            await _mapService.shareAddressWithChildren({
                              'name': title,
                              'address': detailsAddress,
                              'latitude': position.latitude,
                              'longitude': position.longitude,
                              'type': meta['type'],
                              'createdAt': DateTime.now().toIso8601String(),
                            });
                          } else {
                            // Partage en tant qu'adresse "other" par défaut
                            await _mapService.shareAddressWithChildren({
                              'name': title,
                              'address': detailsAddress,
                              'latitude': position.latitude,
                              'longitude': position.longitude,
                              'type': 'other',
                              'createdAt': DateTime.now().toIso8601String(),
                            });
                          }
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Adresse partagée avec vos enfants.',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Échec du partage: $e')),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF179D5B)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.share, color: Color(0xFF179D5B)),
                      label: Text(
                        'Partager',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF179D5B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showManageAddressesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Vos adresses (${_addrUserAddresses.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child:
                        _addrUserAddresses.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: 32,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucune adresse enregistrée',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: _addrUserAddresses.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final addr = _addrUserAddresses[i];
                                final double? lat =
                                    (addr['latitude'] as num?)?.toDouble();
                                final double? lng =
                                    (addr['longitude'] as num?)?.toDouble();
                                final String type =
                                    (addr['type'] as String?) ?? 'Autre';
                                final String title =
                                    addr['name'] ?? addr['type'] ?? 'Adresse';
                                final String subtitle = addr['address'] ?? '';
                                final color = _addrColorForAddressType(type);
                                final icon = _addrIconForAddressType(type);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: color,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          icon,
                                          color: color,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    subtitle: Text(
                                      subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Centrer sur la carte',
                                          icon: Icon(
                                            Icons.center_focus_strong,
                                            color: color,
                                          ),
                                          onPressed:
                                              (lat != null && lng != null)
                                                  ? () {
                                                    _addrMapController.move(
                                                      LatLng(lat, lng),
                                                      16,
                                                    );
                                                    Navigator.of(context).pop();
                                                  }
                                                  : null,
                                        ),
                                        IconButton(
                                          tooltip: 'Supprimer',
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            await _mapService
                                                .removeAddressForCurrentUser(
                                                  addr,
                                                );
                                            if (!mounted) return;
                                            Navigator.of(context).pop();
                                            await _addrLoadMapData();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Adresse supprimée.',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showManageZonesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Vos zones d\'alerte (${_addrRiskZones.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child:
                        _addrRiskZones.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    size: 32,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucune zone enregistrée',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: _addrRiskZones.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final zone = _addrRiskZones[i];
                                final double? lat =
                                    (zone['latitude'] as num?)?.toDouble();
                                final double? lng =
                                    (zone['longitude'] as num?)?.toDouble();
                                final String title =
                                    zone['name'] ?? zone['type'] ?? 'Zone';
                                final String subtitle = zone['address'] ?? '';
                                const color = Colors.red;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: color,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.warning,
                                          color: color,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    subtitle: Text(
                                      subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Centrer sur la carte',
                                          icon: const Icon(
                                            Icons.center_focus_strong,
                                            color: color,
                                          ),
                                          onPressed:
                                              (lat != null && lng != null)
                                                  ? () {
                                                    _addrMapController.move(
                                                      LatLng(lat, lng),
                                                      16,
                                                    );
                                                    Navigator.of(context).pop();
                                                  }
                                                  : null,
                                        ),
                                        IconButton(
                                          tooltip: 'Supprimer',
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            await _mapService
                                                .removeRiskZoneForCurrentUser(
                                                  zone,
                                                );
                                            if (!mounted) return;
                                            Navigator.of(context).pop();
                                            await _addrLoadMapData();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Zone supprimée.',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Modale de marquage (style similaire à AddAlertZone)
  void _showMarkAddressSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    "Enregistrer votre position exacte permet un suivi précis.",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        _addrTypes.map((type) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: ChoiceChip(
                              label: Row(
                                children: [
                                  if (type == 'Maison')
                                    const Icon(
                                      Icons.home,
                                      size: 18,
                                      color: Color(0xFF179D5B),
                                    ),
                                  if (type == 'École')
                                    const Icon(
                                      Icons.school,
                                      size: 18,
                                      color: Color(0xFF179D5B),
                                    ),
                                  if (type == 'Autre')
                                    const Icon(
                                      Icons.add,
                                      size: 18,
                                      color: Color(0xFF179D5B),
                                    ),
                                  const SizedBox(width: 4),
                                  Text(
                                    type,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              selected: _addrSelectedType == type,
                              selectedColor: const Color(0xFF179D5B),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color:
                                    _addrSelectedType == type
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color:
                                      _addrSelectedType == type
                                          ? const Color(0xFF179D5B)
                                          : Colors.grey.shade300,
                                ),
                              ),
                              onSelected: (val) {
                                if (type == 'Autre' && val) {
                                  setModalState(() => _addrSelectedType = type);
                                  _addrShowNameInputModal();
                                } else if (val) {
                                  setModalState(() {
                                    _addrSelectedType = type;
                                    _addrName = type;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Nom",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  Text(_addrName, style: GoogleFonts.poppins(fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(
                    "Adresse",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  Text(_addrAddress, style: GoogleFonts.poppins(fontSize: 15)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF179D5B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        try {
                          final type =
                              _addrSelectedType == 'Maison'
                                  ? 'home'
                                  : _addrSelectedType == 'École'
                                  ? 'school'
                                  : 'other';
                          await _mapService.saveAddressForCurrentUserAddress(
                            name: _addrName,
                            address: _addrAddress,
                            position: _addrMapCenter,
                            type: type,
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                          await _addrLoadMapData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Adresse enregistrée avec succès !',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Erreur lors de l'enregistrement : $e",
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        "Enregistrer l'adresse marquée",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _initPlaces() async {
    try {
      if (!mounted) return;

      final addresses = await _authService.getCurrentUserAddresses();
      Map<String, dynamic>? home;
      Map<String, dynamic>? school;
      for (final a in addresses) {
        final type = a['type'] as String?;
        if (type == 'home') home = a;
        if (type == 'school') school = a;
      }
      if (!mounted) return;
      setState(() {
        _homeAddress = home;
        _schoolAddress = school;
      });
    } catch (e) {
      // noop
    }
  }

  // ---------------- Onglet Adresse: helpers ----------------
  Future<void> _addrGetCurrentLocation() async {
    try {
      final location = location_package.Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() => _addrLoadingLocation = false);
          return;
        }
      }
      var permissionGranted = await location.hasPermission();
      if (permissionGranted == location_package.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != location_package.PermissionStatus.granted) {
          setState(() => _addrLoadingLocation = false);
          return;
        }
      }
      final locData = await location.getLocation().timeout(
        const Duration(seconds: 3),
      );
      final pos = LatLng(locData.latitude!, locData.longitude!);
      setState(() {
        _addrCurrentPosition = pos;
        _addrMapCenter = pos;
        _addrLoadingLocation = false;
      });
      final newAddress = await _mapService.getAddressFromLatLng(pos);
      if (!mounted) return;
      setState(() {
        _addrAddress = newAddress;
      });
    } on TimeoutException {
      // Timeout: on arrête le spinner et on garde la carte visible avec une position par défaut
      setState(() {
        _addrCurrentPosition ??= _mapService.initialPosition;
        _addrMapCenter = _addrCurrentPosition!;
        _addrLoadingLocation = false;
        _addrAddress =
            _addrAddress.isNotEmpty ? _addrAddress : 'Position par défaut';
      });
    } catch (e) {
      setState(() {
        _addrCurrentPosition = _mapService.initialPosition;
        _addrMapCenter = _mapService.initialPosition;
        _addrLoadingLocation = false;
        _addrAddress = 'Position par défaut';
      });
    }
  }

  Future<void> _addrUpdateAddressFromCenter(LatLng center) async {
    //   final newAddress = await _mapService.getAddressFromLatLng(center);
    //   setState(() {
    //     _addrAddress = newAddress;
    //     _addrCurrentPosition = center;
    //   });
    // }
    try {
      final newAddress = await _mapService.getAddressFromLatLng(center);
      if (!mounted) return;
      setState(() {
        _addrAddress = newAddress;
        _addrMapCenter = center;
      });
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'adresse: $e');
    }
  }

  void _addrShowNameInputModal() {
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nom du lieu',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Simple TextField pour éviter l'import CustomTextField
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Ex: Pharmacie, Bureau, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      setState(() {
                        _addrName = controller.text.trim();
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF179D5B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Valider',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _startProximityMonitoring() {
    _isMonitoring = true;
    _proximityTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isMonitoring) {
        _checkProximityToRiskZones();
      }
    });
  }

  Future<void> _checkProximityToRiskZones() async {
    try {
      // Récupérer la position actuelle
      final currentPosition = await _mapService.getCurrentUserPosition();
      if (currentPosition == null) return;

      // Récupérer les zones de risque
      final riskZones = await _authService.getCurrentUserRiskZones();

      // Vérifier si l'utilisateur est proche d'une zone de risque
      for (final zone in riskZones) {
        final lat = zone['latitude'] as double?;
        final lng = zone['longitude'] as double?;

        if (lat != null && lng != null) {
          final zonePosition = LatLng(lat, lng);
          final isNear = _mapService.isNearRiskZone(
            currentPosition,
            zonePosition,
          );

          if (isNear && mounted) {
            _showPanicAlert(
              'Vous',
              currentPosition,
              zone['name'] as String? ?? 'Zone de risque',
            );
            return;
          }
        }
      }

      final childrenAddresses =
          await _authService.getCurrentUserChildrenAddresses();
      for (final childAddress in childrenAddresses) {
        final lat = childAddress['latitude'] as double?;
        final lng = childAddress['longitude'] as double?;
        final childName = childAddress['childName'] as String? ?? 'Enfant';

        if (lat != null && lng != null) {
          final childPosition = LatLng(lat, lng);

          for (final zone in riskZones) {
            final zoneLat = zone['latitude'] as double?;
            final zoneLng = zone['longitude'] as double?;

            if (zoneLat != null && zoneLng != null) {
              final zonePosition = LatLng(zoneLat, zoneLng);
              final isNear = _mapService.isNearRiskZone(
                childPosition,
                zonePosition,
              );

              if ((isNear == true) && (mounted == true)) {
                _showPanicAlert(
                  childName,
                  childPosition,
                  zone['name'] as String? ?? 'Zone de risque',
                );
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification de proximité: $e');
    }
  }

  void _showPanicAlert(String personName, LatLng? location, String zoneName) {
    _isMonitoring = false;

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder:
                    (_) => PanicAlertScreen(
                      childName: personName,
                      childLocation: location,
                    ),
              ),
            )
            .then((_) {
              _isMonitoring = true;
            });
      }
    });
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
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EnhancedMapWidget(
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
                          Navigator.of(context).pop();
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
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _buildTrackingCard(
                            title: 'Traçabilité Maison',
                            icon: Icons.home,
                            color: const Color(0xFF4CAF50),
                            address: _homeAddress?['address'] as String?,
                            type: 'home',
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: _buildTrackingCard(
                            title: 'Traçabilité École',
                            icon: Icons.school,
                            color: const Color(0xFFFF9800),
                            address: _schoolAddress?['address'] as String?,
                            type: 'school',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Statut des enfants
                    Consumer<AuthStateService>(
                      builder: (context, authState, child) {
                        final userUid = authState.currentUser?.uid;
                        if (userUid != null) {
                          return _buildChildrenConnectivityCard(userUid);
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            )
          else if (_selectedIndex == 1)
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FlutterMap(
                      mapController: _addrMapController,
                      options: MapOptions(
                        initialCenter: _addrMapCenter,
                        initialZoom: 15,
                        onMapEvent: (event) {
                          if (event is MapEventMoveEnd) {
                            _addrUpdateAddressFromCenter(
                              _addrMapController.camera.center,
                            );
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                          subdomains: ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.example.safetytrack',
                          retinaMode: RetinaMode.isHighDensity(context),
                        ),
                        MarkerLayer(markers: _addrBuildMarkers()),
                      ],
                    ),
                  ),

                  if (_addrLoadingLocation)
                    const Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF179D5B),
                        ),
                      ),
                    ),

                  // Overlay d'adresse en haut
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF179D5B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _addrAddress,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Barre d'actions en bas
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: [
                        // Centrer sur moi
                        FloatingActionButton.small(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          heroTag: 'center_me',
                          onPressed:
                              _addrCurrentPosition != null
                                  ? () {
                                    _addrMapController.move(
                                      _addrCurrentPosition!,
                                      15,
                                    );
                                  }
                                  : null,
                          backgroundColor: const Color(0xFF179D5B),
                          foregroundColor: Colors.white,
                          child: const Icon(Icons.my_location, size: 20),
                        ),
                        const SizedBox(width: 10),

                        // Marquer l'adresse au centre
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF179D5B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _showMarkAddressSheet,
                            icon: const Icon(
                              Icons.add_location_alt,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Marquer',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Gérer zones
                        FloatingActionButton.small(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          heroTag: 'manage_zones',
                          onPressed: _showManageZonesSheet,
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          child: const Icon(Icons.warning, size: 20),
                        ),
                        const SizedBox(width: 10),

                        // Gérer adresses
                        FloatingActionButton.small(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          heroTag: 'manage_addresses',
                          onPressed: _showManageAddressesSheet,
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          child: const Icon(Icons.bookmarks, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (_selectedIndex == 2)
            Expanded(child: _buildHistorySection())
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // Section Alertes
                    Column(
                      children: [
                        // Cercle vert avec coche blanche
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF179D5B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune alerte détectée',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF179D5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SafeTrack est là pour vous protéger.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF179D5B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Section Conseils de sécurité
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête avec icône bouclier
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF179D5B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.shield,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Conseils de sécurité du jour',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF179D5B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Liste des conseils
                          _buildSafetyTip(
                            'Éduquez votre enfant sur les lieux où demander de l\'aide.',
                          ),
                          const SizedBox(height: 12),
                          _buildSafetyTip(
                            'Montrez-lui les chemins les plus sûrs pour aller et revenir de l\'école.',
                          ),
                          const SizedBox(height: 12),
                          _buildSafetyTip(
                            'Jouez des scénarios pour préparer aux situations réelles.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddAlertZone()),
                          ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF179D5B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_location_alt,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ajouter une zone d\'alerte',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          setState(() => _selectedIndex = i);
        },
      ),
    );
  }
}

Widget _buildSafetyTip(String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.favorite, color: Colors.grey.shade400, size: 16),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
        ),
      ),
    ],
  );
}
