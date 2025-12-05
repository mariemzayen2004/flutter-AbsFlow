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

  // mettreAJourSeuils(seuilAvertissement, seuilElimination)
  SettingsModel mettreAJourSeuils(int seuilAvertissement, int seuilElimination) {
    final settings = getSettings();
    settings.seuilAvertissement = seuilAvertissement;
    settings.seuilElimination = seuilElimination;
    settings.save();
    return settings;
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
