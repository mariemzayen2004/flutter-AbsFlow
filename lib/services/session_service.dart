import 'package:hive/hive.dart';
import '../models/session/session.dart';

class SessionService {
  final Box<Session> _sessionBox;

  SessionService(this._sessionBox);

  // Ouverture de la Box Hive 
  Future<Box<Session>> _openSessionBox() async {
    return _sessionBox;
  }

  // Méthode pour ajouter une séance
  Future<int> ajouterSession(
  int groupId,
  int subjectId,
  DateTime date,
  DateTime heureDebut,
  DateTime heureFin,
) async {
  final box = await _openSessionBox();

  // Créer la session
  final session = Session(
    groupId: groupId,
    subjectId: subjectId,
    date: date,
    heureDebut: heureDebut,
    heureFin: heureFin,
  );

  // Ajouter la session dans la box (ajouter sans spécifier l'ID)
  final key = await box.add(session);  // `add()` génère un ID automatiquement

  // Vérification dans la console pour voir si l'ID est généré
  print('Séance ajoutée avec ID : $key');  // Afficher l'ID généré

  // Retourner l'ID généré par Hive
  return key;  // Le retour doit être un int (l'ID de la session)
}

  // Méthode pour supprimer une séance
  Future<void> supprimerSession(int sessionId) async {
    final box = await _openSessionBox();

    if (box.containsKey(sessionId)) {
      await box.delete(sessionId);
    }
  }

  // Méthode pour récupérer une séance par l'id
  Future<Session?> getSessionById(int sessionId) async {
    final box = await _openSessionBox();
    return box.get(sessionId);
  }

  // Méthode pour récupérer une séance
  Future<List<Session>> getSessions() async {
    final box = await _openSessionBox();
    return box.values.toList();
  }

  // Méthode pour récupérer une séance par groupe
  Future<List<Session>> getSessionsByGroup(int groupId) async {
    final box = await _openSessionBox();

    return box.values
        .where((s) => s.groupId == groupId)
        .toList();
  }

  // Méthode pour récupérer une séance par matière
  Future<List<Session>> getSessionsBySubject(int subjectId) async {
    final box = await _openSessionBox();

    return box.values
        .where((s) => s.subjectId == subjectId)
        .toList();
  }

  // Méthode pour filtrer les séance
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
