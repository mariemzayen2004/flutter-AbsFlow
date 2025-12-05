import 'package:hive/hive.dart';

import '../models/session/session.dart';

class SessionService {
  static const String _boxName = 'sessionsBox';

  // -------------------------------------------------------------
  // Ouverture du Box Hive
  // -------------------------------------------------------------
  Future<Box<Session>> _openBox() async {
    return await Hive.openBox<Session>(_boxName);
  }

  // -------------------------------------------------------------
  // 1️⃣ ajouterSession()
  // -------------------------------------------------------------
  Future<int> ajouterSession(
    int groupId,
    int subjectId,
    DateTime date,
    DateTime heureDebut,
    DateTime heureFin,
  ) async {
    final box = await _openBox();

    final newId = DateTime.now().millisecondsSinceEpoch;

    final session = Session(
      id: newId,
      groupId: groupId,
      subjectId: subjectId,
      date: date,
      heureDebut: heureDebut,
      heureFin: heureFin,
    );

    await box.put(newId, session);
    return newId;
  }

  // -------------------------------------------------------------
  // 2️⃣ supprimerSession()
  // -------------------------------------------------------------
  Future<void> supprimerSession(int sessionId) async {
    final box = await _openBox();

    if (box.containsKey(sessionId)) {
      await box.delete(sessionId);
    }
  }

  // -------------------------------------------------------------
  // 3️⃣ getSessionById()
  // -------------------------------------------------------------
  Future<Session?> getSessionById(int sessionId) async {
    final box = await _openBox();
    return box.get(sessionId);
  }

  // -------------------------------------------------------------
  // 4️⃣ getSessions()
  // -------------------------------------------------------------
  Future<List<Session>> getSessions() async {
    final box = await _openBox();
    return box.values.toList();
  }

  // -------------------------------------------------------------
  // 5️⃣ getSessionsByGroup()
  // -------------------------------------------------------------
  Future<List<Session>> getSessionsByGroup(int groupId) async {
    final box = await _openBox();

    return box.values
        .where((s) => s.groupId == groupId)
        .toList();
  }

  // -------------------------------------------------------------
  // 6️⃣ getSessionsBySubject()
  // -------------------------------------------------------------
  Future<List<Session>> getSessionsBySubject(int subjectId) async {
    final box = await _openBox();

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
    final box = await _openBox();

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
