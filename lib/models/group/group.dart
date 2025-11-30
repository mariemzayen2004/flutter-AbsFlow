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
}
