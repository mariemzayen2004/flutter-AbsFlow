import 'package:hive/hive.dart';

import '../models/student/student.dart';
import 'attendance_service.dart';

class StudentService {
  final Box<Student> _studentBox;
  late AttendanceService _attendanceService;

  StudentService(this._studentBox, AttendanceService attendanceService) {
    _attendanceService = attendanceService;
  }
  
  // Getter pour _studentBox
  Box<Student> get studentBox => _studentBox;
  
  // Getter pour AttendanceService
  AttendanceService get attendanceService => _attendanceService;

  // Setter pour AttendanceService
  set attendanceService(AttendanceService service) {
    _attendanceService = service;
  }

  // À appeler au démarrage de l'appli
  Future<void> initStudentsIfEmpty() async {
    if (_studentBox.isNotEmpty) {
      return; // il y a déjà des données, on ne touche à rien
    }

    for (final student in Student.initialStudents) {
      await _studentBox.add(student);
    }
  }

  // getStudents()
  List<Student> getStudents() {
    return _studentBox.values.toList();
  }

  // getStudentById(studentId)
  Student? getStudentById(int studentId) {
    try {
      return _studentBox.values.firstWhere((s) => s.id == studentId);
    } catch (_) {
      return null;
    }
  }

  // getStudentsByGroup(groupId)
  List<Student> getStudentsByGroup(int groupId) {
    return _studentBox.values
        .where((s) => s.groupId == groupId)
        .toList();
  }

  // filterStudents(...)
  List<Student> filterStudents({
    String? nom,
    String? matricule,
    int? groupId,
    bool? onlyActive,
  }) {
    Iterable<Student> results = _studentBox.values;

    if (nom != null && nom.trim().isNotEmpty) {
      final lowerNom = nom.toLowerCase();
      results = results.where(
        (s) =>
            s.nom.toLowerCase().contains(lowerNom) ||
            s.prenom.toLowerCase().contains(lowerNom),
      );
    }

    if (matricule != null && matricule.trim().isNotEmpty) {
      final lowerMat = matricule.toLowerCase();
      results = results.where(
        (s) => s.matricule.toLowerCase().contains(lowerMat),
      );
    }

    if (groupId != null) {
      results = results.where((s) => s.groupId == groupId);
    }

    if (onlyActive != null) {
      results = results.where((s) => s.isActive == onlyActive);
    }

    return results.toList();
  }

  // Mettre à jour le total des heures manquées d'un étudiant
  Future<void> updateTotalHeuresAbsence(int studentId) async {
    final student = getStudentById(studentId);
    if (student != null) {
      final totalHeuresAbsence = _attendanceService.getTotalHeuresManquees(studentId);
      student.totalHeuresAbsence = totalHeuresAbsence;
      await student.save(); // Enregistrer les modifications dans Hive
    }
  }
  
}
