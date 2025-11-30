import 'package:hive/hive.dart';
part 'session.g.dart';

@HiveType(typeId: 4)
class Session extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int groupId;

  @HiveField(2)
  int subjectId;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  DateTime heureDebut;

  @HiveField(5)
  DateTime heureFin;


  Session({
    required this.id,
    required this.groupId,
    required this.subjectId,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
  });
}
