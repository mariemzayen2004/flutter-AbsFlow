import 'package:abs_flow/models/subject/subject.dart';
import 'package:hive/hive.dart';

class SubjectService {

  final Box<Subject> _subjectBox;
  SubjectService(this._subjectBox);

  // Méthode pour insérer les groupes par défaut dans la box
  Future<void> insertSubjects() async {
    // Vérifie si la Box est vide avant d'ajouter des groupes
    if (_subjectBox.isEmpty) {

      for (var subject in Subject.initialSubjects) {
        await _subjectBox.add(subject);  // Ajoute chaque groupe
      }
      print('Matières ajoutés dans la box: ${_subjectBox.length}');
    } else {
      print('La Box contient déjà des Matières.');
    }
  }

  // Liste de toutes les matières
  List<Subject> getSubjects() {
    return _subjectBox.values.toList();
  }

  // Détails d’une matière par id
  Subject? getSubjectById(int subjectId) {
    try {
      return _subjectBox.values.firstWhere((s) => s.id == subjectId);
    } catch (_) {
      return null; // si pas trouvé
    }
  }

  // Méthode modifiée pour retourner un Future<Subject?> au lieu d'un Subject?
Future<Subject?> getSubjectsById(int subjectId) async {
  try {
    final subject = _subjectBox.values.firstWhere((s) => s.id == subjectId);
    return subject;
  } catch (_) {
    return null; // si pas trouvé
  }
}


  // Matières d’un groupe pour la prise d’appel
  List<Subject> getSubjectsByGroup(int groupId) {
    return _subjectBox.values
        .where((s) => s.groupIds.contains(groupId))
        .toList();
  }
}