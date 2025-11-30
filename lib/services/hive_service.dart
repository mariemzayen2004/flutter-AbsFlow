// lib/services/hive_service.dart
import 'package:hive_flutter/hive_flutter.dart';

import '../models/alert/alert.dart';
import '../models/attendance/attendance.dart';
import '../models/group/group.dart';
import '../models/session/session.dart';
import '../models/settings/settings.dart';
import '../models/student/student.dart';
import '../models/subject/subject.dart';


class HiveService {
  HiveService._(); // constructeur privé
  static final HiveService instance = HiveService._();

  // 🔹 Boxes accessibles dans toute l'application
  late Box<Student> studentsBox;
  late Box<Group> groupsBox;
  late Box<Subject> subjectsBox;
  late Box<Session> sessionsBox;
  late Box<Attendance> attendancesBox;
  late Box<AlertModel> alertsBox;
  late Box<SettingsModel> settingsBox;

  /// À appeler UNE SEULE FOIS dans main()
  static Future<void> init() async {
    // 1) Initialiser Hive pour Flutter
    await Hive.initFlutter();

    // 2) Enregistrer les adapters générés par *.g.dart
    Hive.registerAdapter(StudentAdapter());
    Hive.registerAdapter(GroupAdapter());
    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(SessionAdapter());
    Hive.registerAdapter(AttendanceAdapter());
    Hive.registerAdapter(AlertModelAdapter());
    Hive.registerAdapter(SettingsModelAdapter());

    // 3) Ouvrir les box
    final s = HiveService.instance;

    s.studentsBox     = await Hive.openBox<Student>('students');
    s.groupsBox       = await Hive.openBox<Group>('groups');
    s.subjectsBox     = await Hive.openBox<Subject>('subjects');
    s.sessionsBox     = await Hive.openBox<Session>('sessions');
    s.attendancesBox  = await Hive.openBox<Attendance>('attendances');
    s.alertsBox       = await Hive.openBox<AlertModel>('alerts');
    s.settingsBox     = await Hive.openBox<SettingsModel>('settings');
  }
}
