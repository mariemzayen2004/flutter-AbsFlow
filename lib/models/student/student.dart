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
  //Liste d'étudiants 
  static final List<Student> initialStudents = [
    Student(
      id: 1,
      matricule: '2024-001',
      nom: 'Ben Ali',
      prenom: 'Amine',
      groupId: 1,
      photoPath: 'assets/images/etu_gar6.jpg'
    ),
    Student(
      id: 2,
      matricule: '2024-002',
      nom: 'Trabelsi',
      prenom: 'Sarra',
      groupId: 1,
      photoPath: 'assets/images/etu_fille6.png'
    ),
    Student(
      id: 3,
      matricule: '2024-003',
      nom: 'Gharbi',
      prenom: 'Youssef',
      groupId: 1,
      photoPath: 'assets/images/etu_gar2.jpg'
    ),
    Student(
      id: 4,
      matricule: '2024-004',
      nom: 'Mansour',
      prenom: 'Meriem',
      groupId: 2,
      photoPath: 'assets/images/etu_fille.jpg'
    ),
    Student(
      id: 5,
      matricule: '2024-005',
      nom: 'Khaldi',
      prenom: 'Oussama',
      groupId: 2,
      photoPath: 'assets/images/etu_gar3.png'
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
      photoPath: 'assets/images/etu_fille3.jpg'
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
      photoPath: 'assets/images/etu_fille7.jpg'
    ),
    Student(
      id: 10,
      matricule: '2024-010',
      nom: 'Njeh',
      prenom: 'Emna',
      groupId: 4,
      photoPath: 'assets/images/etu_fille8.jpg'
    ),
    Student(
      id: 11,
      matricule: '2024-011',
      nom: 'Feki',
      prenom: 'Fatma',
      groupId: 4,
      photoPath: 'assets/images/etu_fille9.jpg'
    ),
    Student(
      id: 12,
      matricule: '2024-012',
      nom: 'Chaaben',
      prenom: 'Ala',
      groupId: 4,
      photoPath: 'assets/images/etu_gar4.png'
    ),
    Student(
      id: 13,
      matricule: '2024-013',
      nom: 'Kammoun',
      prenom: 'Eya',
      groupId: 5,
      photoPath: 'assets/images/etu_fille2.jpg'
    ),
    Student(
      id: 14,
      matricule: '2024-014',
      nom: 'Ben massaoud',
      prenom: 'Wiem',
      groupId: 5,
      photoPath: 'assets/images/etu_fille4.jpg'
    ),
    Student(
      id: 15,
      matricule: '2024-015',
      nom: 'Ghozzi',
      prenom: 'Ahmed',
      groupId: 5,
      photoPath: 'assets/images/etu_gar7.jpg'
    ),
    Student(
      id: 16,
      matricule: '2024-016',
      nom: 'Salmen',
      prenom: 'Mounir',
      groupId: 6,
      photoPath: 'assets/images/etu_gar5.jpg'
    ),
  ];
}


