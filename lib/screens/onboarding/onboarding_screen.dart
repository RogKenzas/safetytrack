import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/forms/primary_button.dart';
import '../child/add_child_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Suivi en temps réel',
      description:
          'Restez informé de la localisation de vos proches grâce au suivi en direct.',
      icon: Icons.location_on,
    ),
    _OnboardingPageData(
      title: 'Planning et événements',
      description:
          'Consultez les activités quotidiennes et les événements à venir de votre enfant.',
      icon: Icons.event_note,
    ),
    _OnboardingPageData(
      title: 'Alertes instantanées',
      description:
          'Recevez des notifications pour garantir la sécurité de votre enfant en toute situation.',
      icon: Icons.notification_important,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigation vers l'ajout de l'enfant après l'onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AddChildScreen()),
      );
    }
  }

  void _skip() {
    _controller.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 180,
                          width: 180,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5EF),
                            borderRadius: BorderRadius.circular(90),
                          ),
                          child: Icon(
                            page.icon,
                            size: 90,
                            color: const Color(0xFF179D5B),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          page.description,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        _currentPage == i
                            ? const Color(0xFF179D5B)
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  if (_currentPage < _pages.length - 1)
                    Expanded(
                      child: TextButton(
                        onPressed: _skip,
                        child: Text(
                          'Passer',
                          style: GoogleFonts.poppins(color: Colors.black54),
                        ),
                      ),
                    ),
                  Expanded(
                    child: PrimaryButton(
                      label:
                          _currentPage == _pages.length - 1
                              ? 'Continuer'
                              : 'Suivant',
                      onPressed: _nextPage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
  });
}
