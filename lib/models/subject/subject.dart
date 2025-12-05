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

  // Liste des matières
  static final List<Subject> initialStudents = [
    Subject(
      id: 1,
      nom: 'Algorithmique et Programmation',
      enseignant: 'Mme. Nouha chaaben',
      volumeHoraire: 30,
      groupIds: [1, 2], 
    ),
    Subject(
      id: 2,
      nom: 'Bases de Données',
      enseignant: 'Mme. Nahla Fendri',
      volumeHoraire: 24,
      groupIds: [1],
    ),
    Subject(
      id: 3,
      nom: 'Réseaux Informatiques',
      enseignant: 'Mr. Riadh Turki',
      volumeHoraire: 26,
      groupIds: [2],
    ),
    Subject(
      id: 4,
      nom: 'Génie Logiciel',
      enseignant: 'Mme. Sourour Njeh',
      volumeHoraire: 28,
      groupIds: [1, 2],
    ),
    Subject(
      id: 5,
      nom: 'Cloud',
      enseignant: 'Mr. Kais Loukil',
      volumeHoraire: 28,
      groupIds: [1, 2],
    ),
  ];
}
