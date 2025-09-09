import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../child/add_child_screen.dart';
import '../add_alert_zone.dart';
import '../../services/auth_state_service.dart';
import '../../services/onboarding_service.dart';
import '../../components/forms/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Bienvenue sur SafetyTrack !',
      description:
          'Votre application de sécurité familiale pour suivre vos enfants et marquer des zones d\'alerte.',
      icon: Icons.family_restroom,
      color: Color(0xFF179D5B),
    ),
    OnboardingStep(
      title: 'Liez votre compte à un enfant',
      description:
          'Ajoutez le compte de votre enfant pour commencer le suivi en temps réel.',
      icon: Icons.child_care,
      color: Color(0xFF2196F3),
    ),
    OnboardingStep(
      title: 'Marquez des zones d\'alerte',
      description:
          'Définissez des zones importantes comme l\'école, la maison, ou des zones à risque.',
      icon: Icons.warning,
      color: Color(0xFFFF9800),
    ),
    OnboardingStep(
      title: 'Accédez à votre dashboard',
      description:
          'Votre interface principale pour surveiller vos enfants et gérer vos zones d\'alerte.',
      icon: Icons.dashboard,
      color: Color(0xFF4CAF50),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkOnboardingProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkOnboardingProgress() async {
    final authState = context.read<AuthStateService>();
    final userUid = authState.currentUser?.uid;

    if (userUid != null) {
      final progress = await OnboardingService().getOnboardingProgress(userUid);

      if (mounted) {
        setState(() {
          // Mettre à jour l'étape actuelle selon le progrès
          if (progress.hasChildren && progress.hasRiskZones) {
            _currentPage = 3; // Dernière étape
          } else if (progress.hasChildren) {
            _currentPage = 2; // Étape des zones d'alerte
          } else if (progress.hasAddresses) {
            _currentPage = 1; // Étape des enfants
          }
        });

        // Animer vers la page appropriée si nécessaire
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  void _goToAddChild() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddChildScreen()),
    );
    // Rafraîchir le progrès après le retour de l'écran d'ajout d'enfant
    _checkOnboardingProgress();
  }

  void _goToAddAlertZone() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAlertZone()),
    );
    // Rafraîchir le progrès après le retour de l'écran d'ajout de zone d'alerte
    _checkOnboardingProgress();
  }

  void _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthStateService>();
      final userUid = authState.currentUser?.uid;

      if (userUid != null) {
        // Marquer l'onboarding comme terminé
        await OnboardingService().markOnboardingComplete(userUid);

        // Attendre un peu pour l'effet visuel
        await Future.delayed(Duration(seconds: 2));

        if (mounted) {
          setState(() => _isLoading = false);
          // Rediriger vers le dashboard
          authState.refreshUserData();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la finalisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStateService>(
      builder: (context, authState, child) {
        final userName = authState.userData?['name'] as String? ?? 'Parent';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          body: SafeArea(
            child: Column(
              children: [
                // Header avec progression
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: const Color(0xFF179D5B),
                            child: Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : 'P',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bonjour, $userName !',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Configuration de votre compte',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => authState.signOut(),
                            icon: const Icon(
                              Icons.logout,
                              color: Color(0xFF179D5B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Barre de progression
                      Row(
                        children:
                            _steps.asMap().entries.map((entry) {
                              final index = entry.key;
                              final isActive = index <= _currentPage;
                              final isCompleted = index < _currentPage;

                              return Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    right: index < _steps.length - 1 ? 8 : 0,
                                  ),
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color:
                                        isCompleted
                                            ? const Color(0xFF179D5B)
                                            : isActive
                                            ? const Color(
                                              0xFF179D5B,
                                            ).withOpacity(0.3)
                                            : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),

                // Contenu principal
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged:
                        (index) => setState(() => _currentPage = index),
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return _buildStepContent(step, index);
                    },
                  ),
                ),

                // Boutons de navigation
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFF179D5B)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Précédent',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF179D5B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      if (_currentPage > 0) const SizedBox(width: 16),

                      Expanded(
                        flex: _currentPage > 0 ? 1 : 1,
                        child:
                            _currentPage == _steps.length - 1
                                ? PrimaryButton(
                                  label:
                                      _isLoading
                                          ? 'Configuration...'
                                          : 'Terminer',
                                  loading: _isLoading,
                                  onPressed:
                                      _isLoading ? null : _completeOnboarding,
                                )
                                : PrimaryButton(
                                  label: 'Suivant',
                                  onPressed: _nextPage,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(OnboardingStep step, int index) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 60, color: step.color),
          ),

          const SizedBox(height: 40),

          // Titre
          Text(
            step.title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Actions spécifiques selon l'étape
          if (index == 1) ...[
            Consumer<AuthStateService>(
              builder: (context, authState, child) {
                return FutureBuilder(
                  future:
                      authState.currentUser != null
                          ? OnboardingService().getOnboardingProgress(
                            authState.currentUser!.uid,
                          )
                          : Future.value(
                            OnboardingProgress(
                              hasChildren: false,
                              hasRiskZones: false,
                              hasAddresses: false,
                              totalSteps: 3,
                              completedSteps: 0,
                            ),
                          ),
                  builder: (context, snapshot) {
                    final progress = snapshot.data;
                    final hasChildren = progress?.hasChildren ?? false;

                    if (hasChildren) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF179D5B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF179D5B).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: const Color(0xFF179D5B),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Enfant ajouté avec succès !',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF179D5B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vous pouvez continuer à l\'étape suivante',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Column(
                        children: [
                          PrimaryButton(
                            label: 'Ajouter un enfant',
                            onPressed: _goToAddChild,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Vous pourrez ajouter plusieurs enfants',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }
                  },
                );
              },
            ),
          ] else if (index == 2) ...[
            Consumer<AuthStateService>(
              builder: (context, authState, child) {
                return FutureBuilder(
                  future:
                      authState.currentUser != null
                          ? OnboardingService().getOnboardingProgress(
                            authState.currentUser!.uid,
                          )
                          : Future.value(
                            OnboardingProgress(
                              hasChildren: false,
                              hasRiskZones: false,
                              hasAddresses: false,
                              totalSteps: 3,
                              completedSteps: 0,
                            ),
                          ),
                  builder: (context, snapshot) {
                    final progress = snapshot.data;
                    final hasRiskZones = progress?.hasRiskZones ?? false;

                    if (hasRiskZones) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF179D5B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF179D5B).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: const Color(0xFF179D5B),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Zone d\'alerte ajoutée avec succès !',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF179D5B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vous pouvez continuer à l\'étape suivante',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Column(
                        children: [
                          PrimaryButton(
                            label: 'Marquer une zone',
                            onPressed: _goToAddAlertZone,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Définissez des zones importantes pour la sécurité',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }
                  },
                );
              },
            ),
          ] else if (index == 3) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF179D5B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF179D5B).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFF179D5B),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Votre compte est maintenant configuré !',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF179D5B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
