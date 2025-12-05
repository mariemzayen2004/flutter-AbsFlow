// lib/main.dart
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'screens/add_cours.dart';
import 'screens/students_list.dart';
=======
import 'screens/prise_appel.dart';
>>>>>>> mariem006
import 'services/hive_service.dart';
import 'services/student_service.dart';
import 'services/attendance_service.dart';

late final StudentService studentService;
late final AttendanceService attendanceService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation de Hive via HiveService
  await HiveService.init();

  // 2. Récupération des box ouvertes
  final hive = HiveService.instance;

  // 3. Création des services
  studentService = StudentService(hive.studentsBox);
  attendanceService = AttendanceService(hive.attendancesBox);

  // 4. Pré-remplir les étudiants si la box est vide
  await studentService.initStudentsIfEmpty();

  // 5. Lancer l'app
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
<<<<<<< HEAD
      home: const AddCoursPage () ,
=======
      home: const PriseAppelPage(),
>>>>>>> mariem006
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  

  @override
  Widget build(BuildContext context) {
    // Exemple d'utilisation des services globaux :
    final students = studentService.getStudents();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AbsFlow - Accueil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenue dans AbsFlow 👋\nHive est initialisé et prêt.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text('Nombre d\'étudiants : ${students.length}'),
          ],
        ),
      ),
    );
  }
  
}
class DebugTestPage extends StatelessWidget {
  const DebugTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Ça marche ✅\n(main + Hive + MaterialApp OK)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

