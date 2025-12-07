import 'package:hive/hive.dart';
import '../models/session/session.dart';

class SessionService {
  final Box<Session> _sessionBox;

  SessionService(this._sessionBox);

  // -------------------------------------------------------------
  // Ouverture de la Box Hive (déjà ouverte dans le constructeur)
  // -------------------------------------------------------------
  Future<Box<Session>> _openSessionBox() async {
    return _sessionBox;
  }

  // -------------------------------------------------------------
  // 1️⃣ ajouterSession() : Créer une session et laisser Hive générer un ID
  // -------------------------------------------------------------
  Future<int> ajouterSession(
    int groupId,
    int subjectId,
    DateTime date,
    DateTime heureDebut,
    DateTime heureFin,
  ) async {
    final box = await _openSessionBox();

    final session = Session(
      groupId: groupId,
      subjectId: subjectId,
      date: date,
      heureDebut: heureDebut,
      heureFin: heureFin,
    );

    // Utiliser box.add() pour ajouter la session sans spécifier d'ID
    final key = await box.add(session);

    // Retourner l'ID généré par Hive
    return key;  // Hive génère un ID unique automatiquement
  }

  // -------------------------------------------------------------
  // 2️⃣ supprimerSession()
  // -------------------------------------------------------------
  Future<void> supprimerSession(int sessionId) async {
    final box = await _openSessionBox();

    if (box.containsKey(sessionId)) {
      await box.delete(sessionId);
    }
  }

  // -------------------------------------------------------------
  // 3️⃣ getSessionById()
  // -------------------------------------------------------------
  Future<Session?> getSessionById(int sessionId) async {
    final box = await _openSessionBox();
    return box.get(sessionId);
  }

  // -------------------------------------------------------------
  // 4️⃣ getSessions()
  // -------------------------------------------------------------
  Future<List<Session>> getSessions() async {
    final box = await _openSessionBox();
    return box.values.toList();
  }

  // -------------------------------------------------------------
  // 5️⃣ getSessionsByGroup()
  // -------------------------------------------------------------
  Future<List<Session>> getSessionsByGroup(int groupId) async {
    final box = await _openSessionBox();

    return box.values
        .where((s) => s.groupId == groupId)
        .toList();
  }

  // -------------------------------------------------------------
  // 6️⃣ getSessionsBySubject()
  // -------------------------------------------------------------
  Future<List<Session>> getSessionsBySubject(int subjectId) async {
    final box = await _openSessionBox();

    return box.values
        .where((s) => s.subjectId == subjectId)
        .toList();
  }

  // -------------------------------------------------------------
  // 7️⃣ filterSessions()
  // -------------------------------------------------------------
  Future<List<Session>> filterSessions({
    DateTime? dateDebut,
    DateTime? dateFin,
    int? groupId,
    int? subjectId,
  }) async {
    final box = await _openSessionBox();

    return box.values.where((s) {
      final okDateDebut =
          (dateDebut == null || s.date.isAfter(dateDebut) || s.date.isAtSameMomentAs(dateDebut));

      final okDateFin =
          (dateFin == null || s.date.isBefore(dateFin) || s.date.isAtSameMomentAs(dateFin));

      final okGroup =
          (groupId == null || s.groupId == groupId);

      final okSubject =
          (subjectId == null || s.subjectId == subjectId);

      return okDateDebut && okDateFin && okGroup && okSubject;
    }).toList();
  }
}
