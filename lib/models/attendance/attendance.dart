import 'package:hive/hive.dart';
part 'attendance.g.dart';

@HiveType(typeId: 5)
class Attendance extends HiveObject {

  @HiveField(0)
  int sessionId;

  @HiveField(2)
  int studentId;

  @HiveField(3)
  bool present;

  @HiveField(4)
  int heuresManquees;

  @HiveField(5)
  String? remarque;

  @HiveField(6)
  bool justifie;

  Attendance({
    required this.sessionId,
    required this.studentId,
    required this.present,
    required this.heuresManquees,
    this.remarque,
    this.justifie = false,
  });
}
