import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Vérifie si un parent a complété l'onboarding
  Future<bool> hasCompletedOnboarding(String parentUid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(parentUid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      if (userData == null) return false;

      // Vérifier si le parent a des enfants liés
      final children = userData['children'] as List<dynamic>?;
      final hasChildren = children != null && children.isNotEmpty;

      // Vérifier si le parent a des zones d'alerte
      final riskZones = userData['riskZones'] as List<dynamic>?;
      final hasRiskZones = riskZones != null && riskZones.isNotEmpty;

      // Vérifier si le parent a des adresses
      final addresses = userData['addresses'] as List<dynamic>?;
      final hasAddresses = addresses != null && addresses.isNotEmpty;

      // L'onboarding est complet si le parent a au moins un enfant et une zone d'alerte
      return hasChildren && hasRiskZones;
    } catch (e) {
      print('Erreur lors de la vérification de l\'onboarding: $e');
      return false;
    }
  }

  /// Marque l'onboarding comme terminé
  Future<void> markOnboardingComplete(String parentUid) async {
    try {
      await _firestore.collection('users').doc(parentUid).update({
        'onboardingCompleted': true,
        'onboardingCompletedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erreur lors de la finalisation de l\'onboarding: $e');
    }
  }

  /// Obtient le statut de progression de l'onboarding
  Future<OnboardingProgress> getOnboardingProgress(String parentUid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(parentUid).get();
      if (!userDoc.exists) {
        return OnboardingProgress(
          hasChildren: false,
          hasRiskZones: false,
          hasAddresses: false,
          totalSteps: 3,
          completedSteps: 0,
        );
      }

      final userData = userDoc.data();
      if (userData == null) {
        return OnboardingProgress(
          hasChildren: false,
          hasRiskZones: false,
          hasAddresses: false,
          totalSteps: 3,
          completedSteps: 0,
        );
      }

      final children = userData['children'] as List<dynamic>?;
      final hasChildren = children != null && children.isNotEmpty;

      final riskZones = userData['riskZones'] as List<dynamic>?;
      final hasRiskZones = riskZones != null && riskZones.isNotEmpty;

      final addresses = userData['addresses'] as List<dynamic>?;
      final hasAddresses = addresses != null && addresses.isNotEmpty;

      int completedSteps = 0;
      if (hasChildren) completedSteps++;
      if (hasRiskZones) completedSteps++;
      if (hasAddresses) completedSteps++;

      return OnboardingProgress(
        hasChildren: hasChildren,
        hasRiskZones: hasRiskZones,
        hasAddresses: hasAddresses,
        totalSteps: 3,
        completedSteps: completedSteps,
      );
    } catch (e) {
      print('Erreur lors de la récupération du progrès: $e');
      return OnboardingProgress(
        hasChildren: false,
        hasRiskZones: false,
        hasAddresses: false,
        totalSteps: 3,
        completedSteps: 0,
      );
    }
  }

  /// Vérifie si un parent peut accéder au dashboard
  Future<bool> canAccessDashboard(String parentUid) async {
    final progress = await getOnboardingProgress(parentUid);
    return progress.completedSteps >= 2; // Au moins 2 étapes sur 3
  }
}

class OnboardingProgress {
  final bool hasChildren;
  final bool hasRiskZones;
  final bool hasAddresses;
  final int totalSteps;
  final int completedSteps;

  OnboardingProgress({
    required this.hasChildren,
    required this.hasRiskZones,
    required this.hasAddresses,
    required this.totalSteps,
    required this.completedSteps,
  });

  double get percentage => completedSteps / totalSteps;

  bool get isComplete => completedSteps >= totalSteps;

  String get status {
    if (isComplete) return 'Complété';
    if (completedSteps >= 2) return 'Presque terminé';
    if (completedSteps >= 1) return 'En cours';
    return 'Non commencé';
  }
}
