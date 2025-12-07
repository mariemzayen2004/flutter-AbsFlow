import 'package:hive_flutter/hive_flutter.dart';
import '../models/group/group.dart';

class GroupesService {
  final Box<Group> _groupsBox;

  GroupesService(this._groupsBox);

  // Méthode pour insérer les groupes par défaut dans la box
  Future<void> insertGroups() async {
    // Vérifie si la Box est vide avant d'ajouter des groupes
    if (_groupsBox.isEmpty) {
      // Ajouter les groupes de test
      for (var group in Group.initialGroups) {
        await _groupsBox.add(group);  // Ajoute chaque groupe
      }
      print('Groupes ajoutés dans la box: ${_groupsBox.length}');
    } else {
      print('La Box contient déjà des groupes.');
    }
  }

  // getGroupes() : Retourne la liste de TOUS les groupes
  Future<List<Group>> getGroupes() async {
    print('Groupes dans la box: ${_groupsBox.length}');
    return _groupsBox.values.toList();  // Retourner tous les groupes dans la Box
  }

  // getGroupeById(id) : Retourne un groupe via son champ id
  Future<Group?> getGroupeById(int id) async {

    try {
      return _groupsBox.values
          .cast<Group?>()
          .firstWhere((g) => g!.id == id, orElse: () => null);
    } catch (e) {
      return null;
    }
  }

  /// ----------------------------------------------------------
  /// 3️⃣ filterGroupes(...) : Filtre les groupes selon des critères optionnels
  /// ----------------------------------------------------------
  Future<List<Group>> filterGroupes({
    String? filiere,
    int? niveau,
    int? numGroup,
  }) async {
    final groupes = _groupsBox.values.toList();

    return groupes.where((g) {
      if (filiere != null && g.filiere != filiere) return false;
      if (niveau != null && g.niveau != niveau) return false;
      if (numGroup != null && g.numGroup != numGroup) return false;
      return true;
    }).toList();
  }
}

