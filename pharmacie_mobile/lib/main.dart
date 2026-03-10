import 'package:flutter/material.dart';
import 'package:pharmacie_mobile/auth/login.dart';
import 'package:pharmacie_mobile/auth/register.dart';
import 'package:pharmacie_mobile/screens/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacie Manager',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const InitialPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/create-pharmacie': (context) => const RegisterPage(),
      },
    );
  }
}

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  @override
  void initState() {
    super.initState();
    _checkInitialPage();
  }

  Future<void> _checkInitialPage() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    final pharmacieCreated = prefs.getString('pharmacie_created') ?? '';

    if (!mounted) return;

    if (!onboardingCompleted) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else if (pharmacieCreated.isEmpty) {
      Navigator.of(context).pushReplacementNamed('/create-pharmacie');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
