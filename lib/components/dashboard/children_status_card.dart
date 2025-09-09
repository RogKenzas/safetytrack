import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/parent_child_sync_service.dart';

class ChildrenStatusCard extends StatefulWidget {
  final String parentUid;
  
  const ChildrenStatusCard({
    super.key,
    required this.parentUid,
  });

  @override
  State<ChildrenStatusCard> createState() => _ChildrenStatusCardState();
}

class _ChildrenStatusCardState extends State<ChildrenStatusCard> {
  final ParentChildSyncService _syncService = ParentChildSyncService();
  List<Map<String, dynamic>> _childrenStatus = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildrenStatus();
  }

  Future<void> _loadChildrenStatus() async {
    try {
      final status = await _syncService.getChildrenOnlineStatus(widget.parentUid);
      if (mounted) {
        setState(() {
          _childrenStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du statut des enfants: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
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
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF179D5B)),
          ),
        ),
      );
    }

    if (_childrenStatus.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          children: [
            Icon(
              Icons.child_care_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun enfant ajouté',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des comptes enfants pour commencer le suivi',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.family_restroom,
                color: const Color(0xFF179D5B),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Statut des enfants',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_childrenStatus.where((child) => child['isOnline']).length}/${_childrenStatus.length} en ligne',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ..._childrenStatus.map((child) => _buildChildStatusItem(child)),
          
          const SizedBox(height: 12),
          
          // Bouton de rafraîchissement
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _loadChildrenStatus,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Actualiser',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF179D5B),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildStatusItem(Map<String, dynamic> child) {
    final bool isOnline = child['isOnline'] ?? false;
    final String name = child['name'] ?? 'Enfant';
    final String email = child['email'] ?? '';
    final String lastSeen = child['lastSeen'] ?? 'Inconnu';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOnline ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Indicateur de statut
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          
          // Informations de l'enfant
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  lastSeen,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isOnline ? Colors.green : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Colors.grey[600],
            ),
            onSelected: (value) {
              switch (value) {
                case 'location':
                  // Naviguer vers la carte de l'enfant
                  break;
                case 'history':
                  // Afficher l'historique de l'enfant
                  break;
                case 'settings':
                  // Paramètres de l'enfant
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'location',
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 18),
                    SizedBox(width: 8),
                    Text('Voir la position'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 18),
                    SizedBox(width: 8),
                    Text('Historique'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 18),
                    SizedBox(width: 8),
                    Text('Paramètres'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
