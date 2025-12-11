// lib/services/settings_service.dart
import 'package:hive/hive.dart';

import '../models/settings/settings.dart';

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const String _settingsKey = 'current';

  Box<SettingsModel> get _box => Hive.box<SettingsModel>('settings');

  // getSettings() → récupérer les paramètres actuels
  SettingsModel getSettings() {
    final existing = _box.get(_settingsKey);
    if (existing != null) return existing;

    // Si rien en base, on initialise avec les valeurs par défaut
    return initialiserSettingsParDefaut();
  }

  // initialiserSettingsParDefaut() → config par défaut au 1er lancement
  SettingsModel initialiserSettingsParDefaut() {
    var settings = _box.get(_settingsKey);
    if (settings != null) return settings;

    settings = SettingsModel(
      seuilAvertissement: 3,   // 🔁 adapte les valeurs par défaut
      seuilElimination: 7,
      isDarkMode: false,
      modeAffichage: ModeAffichage.liste,
    );

    _box.put(_settingsKey, settings);
    return settings;
  }

  // mettreAJourSeuils(seuilAvertissement, seuilElimination) → Seuils GLOBAUX
  SettingsModel mettreAJourSeuils(int seuilAvertissement, int seuilElimination) {
    final settings = getSettings();
    settings.seuilAvertissement = seuilAvertissement;
    settings.seuilElimination = seuilElimination;
    settings.save();
    return settings;
  }

  // mettreAJourSeuilsParMatiere(subjectId, seuilAlerte, seuilElimination) → Seuils PAR MATIÈRE
  Future<Map<String, dynamic>> mettreAJourSeuilsParMatiere({
    required String subjectId,
    required String subjectName,
    required int seuilAlerte,
    required int seuilElimination,
  }) async {
    // Ouvrir ou récupérer la box des seuils par matière
    Box box;
    if (Hive.isBoxOpen('subject_thresholds')) {
      box = Hive.box('subject_thresholds');
    } else {
      box = await Hive.openBox('subject_thresholds');
    }

    // Créer l'objet des seuils
    final thresholds = {
      'seuilAlerte': seuilAlerte,
      'seuilElimination': seuilElimination,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    // Sauvegarder
    await box.put('subject_$subjectId', thresholds);
    
    return thresholds;
  }

  // getSeuilsParMatiere(subjectId) → Récupérer les seuils d'une matière
  Future<Map<String, dynamic>?> getSeuilsParMatiere(String subjectId) async {
    try {
      Box box;
      if (Hive.isBoxOpen('subject_thresholds')) {
        box = Hive.box('subject_thresholds');
      } else {
        box = await Hive.openBox('subject_thresholds');
      }

      final data = box.get('subject_$subjectId');
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
      
      // Si pas de seuils spécifiques, retourner les seuils globaux
      final globalSettings = getSettings();
      return {
        'seuilAlerte': globalSettings.seuilAvertissement,
        'seuilElimination': globalSettings.seuilElimination,
        'isGlobal': true,
      };
    } catch (e) {
      print('Erreur lors de la récupération des seuils: $e');
      return null;
    }
  }

  // supprimerSeuilsParMatiere(subjectId) → Supprimer les seuils personnalisés d'une matière
  Future<void> supprimerSeuilsParMatiere(String subjectId) async {
    try {
      Box box;
      if (Hive.isBoxOpen('subject_thresholds')) {
        box = Hive.box('subject_thresholds');
      } else {
        box = await Hive.openBox('subject_thresholds');
      }

      await box.delete('subject_$subjectId');
    } catch (e) {
      print('Erreur lors de la suppression des seuils: $e');
    }
  }

  // mettreAJourTheme(isDarkMode)
  SettingsModel mettreAJourTheme(bool isDarkMode) {
    final settings = getSettings();
    settings.isDarkMode = isDarkMode;
    settings.save();
    return settings;
  }

  // mettreAJourModeAffichage(modeListeOuGrille)
  SettingsModel mettreAJourModeAffichage(ModeAffichage modeAffichage) {
    final settings = getSettings();
    settings.modeAffichage = modeAffichage;
    settings.save();
    return settings;
  }
}