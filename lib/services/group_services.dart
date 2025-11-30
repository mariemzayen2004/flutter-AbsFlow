import 'package:hive_flutter/hive_flutter.dart';
import '../models/group/group.dart';

class GroupesService {
  static final GroupesService _instance = GroupesService._internal();

  factory GroupesService() => _instance;

  GroupesService._internal();

  final String _groupsBoxName = "groups";
  Box<Group>? _groupsBox;

  /// ----------------------------------------------------------
  /// Ouvre la box Hive si elle n'est pas déjà ouverte
  /// ----------------------------------------------------------
  Future<Box<Group>> _openGroupsBox() async {
    if (_groupsBox != null && _groupsBox!.isOpen) {
      return _groupsBox!;
    }
    _groupsBox = await Hive.openBox<Group>(_groupsBoxName);
    return _groupsBox!;
  }

  /// ----------------------------------------------------------
  /// 1️⃣ getGroupes() : Retourne la liste de TOUS les groupes
  /// ----------------------------------------------------------
  Future<List<Group>> getGroupes() async {
    final box = await _openGroupsBox();
    return box.values.toList();
  }

  /// ----------------------------------------------------------
  /// 2️⃣ getGroupeById(id) : Retourne un groupe via son champ id
  /// ----------------------------------------------------------
  Future<Group?> getGroupeById(int id) async {
    final box = await _openGroupsBox();
    try {
      return box.values
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
    final box = await _openGroupsBox();
    final groupes = box.values.toList();

    return groupes.where((g) {
      if (filiere != null && g.filiere != filiere) return false;
      if (niveau != null && g.niveau != niveau) return false;
      if (numGroup != null && g.numGroup != numGroup) return false;
      return true;
    }).toList();
  }
}

