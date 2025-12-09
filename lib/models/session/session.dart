import 'package:hive/hive.dart';
part 'session.g.dart';

@HiveType(typeId: 4)
class Session extends HiveObject {

  @HiveField(0)
  int groupId;

  @HiveField(1)
  int subjectId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  DateTime heureDebut;

  @HiveField(4)
  DateTime heureFin;


  Session({
    required this.groupId,
    required this.subjectId,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
  });
  // Accéder à l'ID généré par Hive
  int get id => this.key as int; 
}
