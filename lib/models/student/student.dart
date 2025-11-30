import 'package:hive/hive.dart';
part 'student.g.dart';

@HiveType(typeId: 1)
class Student extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String matricule;

  @HiveField(2)
  String nom;

  @HiveField(3)
  String prenom;

  @HiveField(4)
  int? groupId;

  @HiveField(5)
  String? photoPath;

  @HiveField(6)
  bool isActive;

  @HiveField(7)
  int totalHeuresAbsence;

  @HiveField(8)
  double tauxAbsence;

  Student({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    this.groupId,
    this.photoPath,
    this.isActive = true,
    this.totalHeuresAbsence =0,
    this.tauxAbsence =0,
  });
}
