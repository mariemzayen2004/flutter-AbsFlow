import 'package:hive/hive.dart';
part 'subject.g.dart';

@HiveType(typeId: 3)
class Subject extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String nom;

  @HiveField(2)
  String enseignant;

  @HiveField(3)
  int volumeHoraire;

  @HiveField(4)
  List<int> groupIds;


  Subject({
    required this.id,
    required this.nom,
    required this.enseignant,
    required this.volumeHoraire,
    required this.groupIds,
  });
}
