// lib/main.dart
import 'package:abs_flow/services/alert_services.dart';
import 'package:abs_flow/services/group_services.dart';
import 'package:abs_flow/services/session_service.dart';
import 'package:abs_flow/services/setting_service.dart';
import 'package:abs_flow/services/subjectService.dart';
import 'package:flutter/material.dart';
import 'screens/home.dart';
import 'services/hive_service.dart';
import 'services/student_service.dart';
import 'services/attendance_service.dart';

late final StudentService studentService;
late final AttendanceService attendanceService;
late final AlertService alertService;
late final GroupesService groupesService;
late final SessionService sessionService;
late final SubjectService subjectService;
late final SettingsService settingsService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation de Hive via HiveService
  await HiveService.init();

  // 2. Récupération des box ouvertes
  final hive = HiveService.instance;

  // 3. Création des services
  studentService = StudentService(hive.studentsBox);
  attendanceService = AttendanceService(hive.attendancesBox);
  alertService = AlertService(hive.alertsBox,studentService);
  groupesService = GroupesService(hive.groupsBox);
  sessionService = SessionService(hive.sessionsBox);

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
      home: HomePage(),

    );
  }
}


