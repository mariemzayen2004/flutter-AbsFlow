// lib/main.dart
import 'package:flutter/material.dart';
import 'services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Hive via HiveService
  await HiveService.init();

  runApp(const AbsFlowApp());
}

class AbsFlowApp extends StatelessWidget {
  const AbsFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AbsFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemple : accès au service (si tu en as besoin ici)
    final hive = HiveService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AbsFlow - Accueil'),
      ),
      body: const Center(
        child: Text(
          'Bienvenue dans AbsFlow 👋\nHive est initialisé et prêt.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
