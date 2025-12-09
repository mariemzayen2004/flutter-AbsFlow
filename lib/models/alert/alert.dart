import 'package:hive/hive.dart';
part 'alert.g.dart';

@HiveType(typeId: 7)
class AlertModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int studentId;

  @HiveField(2)
  int totalHeuresAbsence;

  @HiveField(3)
  AlertLevel niveau;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  int groupId;  

  @HiveField(6)
  int subjectId;  

  AlertModel({
    required this.id,
    required this.studentId,
    required this.totalHeuresAbsence,
    required this.niveau,
    required this.date,
    required this.groupId,
    required this.subjectId,
  });
}

@HiveType(typeId: 9)
enum AlertLevel {
  @HiveField(0)
  avertissement,  // Alerte

  @HiveField(1)
  elimination,    // Élimination
}
