import 'package:hive/hive.dart';
import '../models/attendance/attendance.dart';

class AttendanceService {
  final Box<Attendance> _attendanceBox;

  AttendanceService(this._attendanceBox);

  /// 1️⃣ Ajouter une présence/absence lors de la prise d’appel
  Future<void> ajouterAttendancePourSession(
    int sessionId,
    int studentId,
    bool present, [
    int heuresManquees = 0,
    String? remarque,
  ]) async {
    final effectiveHeuresManquees = present ? 0 : heuresManquees;

    final attendance = Attendance(
      sessionId: sessionId,
      studentId: studentId,
      present: present,
      heuresManquees: effectiveHeuresManquees,
      remarque: remarque,
      justifie: false,
    );

    // Utiliser box.add() pour que Hive génère un ID valide automatiquement
    await _attendanceBox.add(attendance);  // Ajout de la présence dans la box sans spécifier d'ID
  }

  // 2️⃣ Modifier une ligne de présence/absence
  Future<void> modifierAttendance(
    int attendanceId,
    bool present,
    int heuresManquees,
    String? remarque,
    bool justifie,
  ) async {
    final attendance = _attendanceBox.get(attendanceId);
    if (attendance == null) return;

    attendance.present = present;
    attendance.heuresManquees = present ? 0 : heuresManquees;
    attendance.remarque = remarque;
    attendance.justifie = justifie;

    await attendance.save();
  }

  // 3️⃣ Récupérer la liste des présences/absences d’une séance
  List<Attendance> getAttendanceBySession(int sessionId) {
    return _attendanceBox.values
        .where((a) => a.sessionId == sessionId)
        .toList();
  }

  // 4️⃣ Récupérer l’historique des présences/absences d’un étudiant
  List<Attendance> getAttendanceByStudent(int studentId) {
    return _attendanceBox.values
        .where((a) => a.studentId == studentId)
        .toList();
  }

  // 5️⃣ Récupérer UNE ligne pour un étudiant dans une séance
  Attendance? getAttendanceBySessionAndStudent(int sessionId, int studentId) {
    try {
      return _attendanceBox.values.firstWhere(
        (a) => a.sessionId == sessionId && a.studentId == studentId,
      );
    } catch (_) {
      return null;
    }
  }
}
