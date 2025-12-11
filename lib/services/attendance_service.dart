import 'package:hive/hive.dart';
import '../models/attendance/attendance.dart';

class AttendanceService {
  final Box<Attendance> _attendanceBox;

  AttendanceService(this._attendanceBox);

  // Ouverture de la Box Hive 
  Future<Box<Attendance>> _openAttendanceBox() async {
    return _attendanceBox;
  }

  /// 1️⃣ Ajouter une présence/absence lors de la prise d’appel
  Future<int> ajouterAttendancePourSession(
    int sessionId,
    int studentId,
    bool present,
    int heuresManquees,
    String? remarque,
  ) async {
    final box = await _openAttendanceBox();

    final attendance = Attendance(
      sessionId: sessionId,
      studentId: studentId,
      present: present,
      heuresManquees: heuresManquees,
      remarque: remarque,
      justifie: false,
    );

    final key = await box.add(attendance);  // Ajoute l'attendance

    print('Présence ajoutée avec ID : $key');

    return key;  // Retourner l'ID de l'attendance
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

  // Total des heures manquées pour un étudiant
  int getTotalHeuresManquees(int studentId) {
    final attendances = getAttendanceByStudent(studentId);
    return attendances.fold(0, (sum, attendance) => sum + attendance.heuresManquees);
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
