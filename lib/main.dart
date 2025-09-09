import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/profile/profile_screen.dart';
import 'services/auth_state_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthStateService(),
      child: MaterialApp(
        title: 'SafetyTrack',
        theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme(),
          primaryColor: const Color(0xFF179D5B),
          scaffoldBackgroundColor: const Color(0xFFF8FAF9),
        ),
        home: const _FirebaseGate(),
        routes: {'/profile': (context) => const ProfileScreen()},
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class _FirebaseGate extends StatelessWidget {
  const _FirebaseGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const AuthWrapper();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur Firebase :\n ${snapshot.error}'));
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
