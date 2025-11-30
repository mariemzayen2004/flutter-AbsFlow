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
  // Liste d'étudiants 
  static final List<Student> initialStudents = [
    Student(
      id: 1,
      matricule: '2024-001',
      nom: 'Ben Ali',
      prenom: 'Amine',
      groupId: 1,
    ),
    Student(
      id: 2,
      matricule: '2024-002',
      nom: 'Trabelsi',
      prenom: 'Sarra',
      groupId: 1,
    ),
    Student(
      id: 3,
      matricule: '2024-003',
      nom: 'Gharbi',
      prenom: 'Youssef',
      groupId: 1,
    ),
    Student(
      id: 4,
      matricule: '2024-004',
      nom: 'Mansour',
      prenom: 'Meriem',
      groupId: 2,
    ),
    Student(
      id: 5,
      matricule: '2024-005',
      nom: 'Khaldi',
      prenom: 'Oussama',
      groupId: 2,
    ),
    Student(
      id: 6,
      matricule: '2024-006',
      nom: 'Haddad',
      prenom: 'Ines',
      groupId: 2,
    ),
    Student(
      id: 7,
      matricule: '2024-007',
      nom: 'Jaziri',
      prenom: 'Malek',
      groupId: 3,
    ),
    Student(
      id: 8,
      matricule: '2024-008',
      nom: 'Saidi',
      prenom: 'Walid',
      groupId: 3,
    ),
    Student(
      id: 9,
      matricule: '2024-009',
      nom: 'Chebbi',
      prenom: 'Amina',
      groupId: 3,
    ),
  ];
}


