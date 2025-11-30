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

  AlertModel({
    required this.id,
    required this.studentId,
    required this.totalHeuresAbsence,
    required this.niveau,
    required this.date,
  });
}
@HiveType(typeId: 9)
enum AlertLevel {
  @HiveField(0)
  avertissement,

  @HiveField(1)
  elimination,
}
