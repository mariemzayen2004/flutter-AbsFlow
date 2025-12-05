import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 6)
enum ModeAffichage {
  @HiveField(0)
  liste,
  @HiveField(1)
  grille,
}

@HiveType(typeId: 8) 
class SettingsModel extends HiveObject {
  @HiveField(0)
  int seuilAvertissement; // pourcentage ex: 20

  @HiveField(1)
  int seuilElimination; // pourcentage ex: 30

  @HiveField(2)
  bool isDarkMode; // true = mode sombre

  @HiveField(3)
  ModeAffichage modeAffichage; // liste ou grille pour les étudiants

  SettingsModel({
    required this.seuilAvertissement,
    required this.seuilElimination,
    required this.isDarkMode,
    required this.modeAffichage,
  });
}
