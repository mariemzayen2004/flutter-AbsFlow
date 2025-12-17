import 'package:hive/hive.dart';
part 'group.g.dart';

@HiveType(typeId: 2)
class Group extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int numGroup;

  @HiveField(2)
  String filiere;

  @HiveField(3)
  int niveau;

  Group({
    required this.id,
    required this.numGroup,
    required this.filiere,
    required this.niveau,
  });
  //Liste des groupes
  static final List<Group> initialGroups = [
    Group(
      id: 1,
      numGroup: 1,
      filiere: 'Informatique',
      niveau: 1, // 1ère année
    ),
    Group(
      id: 2,
      numGroup: 2,
      filiere: 'Informatique',
      niveau: 1, 
    ),
    Group(
      id: 3,
      numGroup: 3,
      filiere: 'Informatique',
      niveau: 1, 
    ),
    Group(
      id: 4,
      numGroup: 1,
      filiere: 'Informatique',
      niveau: 2, 
    ),
    Group(
      id: 5,
      numGroup: 2,
      filiere: 'Informatique',
      niveau: 2, 
    ),
    Group(
      id: 6,
      numGroup: 3,
      filiere: 'Informatique',
      niveau: 2, 
    ),
    Group(
      id: 7,
      numGroup: 1,
      filiere: 'Informatique',
      niveau: 3, 
    ),
    Group(
      id: 8,
      numGroup: 2,
      filiere: 'Informatique',
      niveau: 3, 
    ),
    Group(
      id: 9,
      numGroup: 3,
      filiere: 'Informatique',
      niveau: 3, 
    ),
  ];
}
