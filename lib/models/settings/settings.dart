import 'package:hive/hive.dart';
part 'settings.g.dart';

@HiveType(typeId: 8)
class SettingsModel extends HiveObject {
  @HiveField(0)
  int seuilAvertissement; // pourcentage ex: 20

  @HiveField(1)
  int seuilElimination; // pourcentage ex: 30

  SettingsModel({
    required this.seuilAvertissement,
    required this.seuilElimination,
  });
}