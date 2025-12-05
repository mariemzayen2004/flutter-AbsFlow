import 'package:abs_flow/models/subject/subject.dart';
import 'package:hive/hive.dart';

class SubjectService {
  SubjectService._();

  static final SubjectService instance = SubjectService._();

  /// Box Hive déjà ouverte dans HiveService.init()
  Box<Subject> get _box => Hive.box<Subject>('subjects');

  // Liste de toutes les matières
  List<Subject> getSubjects() {
    return _box.values.toList();
  }

  // Détails d’une matière par id
  Subject? getSubjectById(int subjectId) {
    // 🔹 Option 1 : si tu utilises l'id comme clé Hive
    // return _box.get(subjectId);

    // 🔹 Option 2 : si l'id est un champ du modèle Subject
    try {
      return _box.values.firstWhere((s) => s.id == subjectId);
    } catch (_) {
      return null; // si pas trouvé
    }
  }

  // Matières d’un groupe pour la prise d’appel
  List<Subject> getSubjectsByGroup(int groupId) {
    return _box.values
        .where((s) => s.groupIds.contains(groupId))
        .toList();
  }
}