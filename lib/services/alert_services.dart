import 'package:hive_flutter/hive_flutter.dart';
import '../models/alert/alert.dart';
import '../models/student/student.dart';
import 'student_service.dart';

class AlertService {
  final Box<AlertModel> _alertBox;
  final StudentService _studentService;

  // Constructeur avec le Box pour AlertModel et StudentService
  AlertService(this._alertBox, this._studentService);

  Future<Box<AlertModel>> _openAlertBox() async {
    return _alertBox;
  }

  Future<Box<Student>> _openStudentBox() async {
    return _studentService.studentBox;
  }

  /// ----------------------------------------------------------
  /// 1️⃣ Créer une alerte (avertissement / élimination)
  /// ----------------------------------------------------------
  Future<AlertModel> creerAlerte({
    required int studentId,
    required int totalHeuresAbsence,
    required AlertLevel niveau,
  }) async {
    final box = await _openAlertBox();

    int newId = box.length + 1;

    final alerte = AlertModel(
      id: newId,
      studentId: studentId,
      totalHeuresAbsence: totalHeuresAbsence,
      niveau: niveau,
      date: DateTime.now(),
    );

    await box.put(newId, alerte);
    return alerte;
  }

  /// ----------------------------------------------------------
  /// 2️⃣ Envoyer l'alerte par email (mock)
  /// ----------------------------------------------------------
  Future<bool> envoyerAlerteEmail(int alertId) async {
    final alertBox = await _openAlertBox();
    final studentBox = await _openStudentBox();

    final alerte = alertBox.get(alertId);
    if (alerte == null) return false;

    final etudiant = studentBox.get(alerte.studentId);
    if (etudiant == null) return false;

    // Simulation d'envoi réel (à remplacer par un vrai service email)
    print("================================================");
    print("📨 EMAIL ENVOYÉ");
    print("Étudiant : ${etudiant.prenom} ${etudiant.nom}");
    print("Matricule : ${etudiant.matricule}");
    print("Type d’alerte : ${alerte.niveau}");
    print("Heures d’absence : ${alerte.totalHeuresAbsence}");
    print("Envoyé le : ${alerte.date}");
    print("================================================");

    return true;
  }
}
