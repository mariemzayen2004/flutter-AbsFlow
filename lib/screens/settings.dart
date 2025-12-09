import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/settings/settings.dart';
import '../services/setting_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsService _settingsService;
  late SettingsModel _currentSettings;
  bool _isLoading = false;
  
  // Contrôleurs pour les seuils
  final TextEditingController _seuilAlerteController = TextEditingController();
  final TextEditingController _seuilEliminationController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _initializeSettings() {
    _settingsService = SettingsService.instance;
    _currentSettings = _settingsService.getSettings();
    _seuilAlerteController.text = _currentSettings.seuilAvertissement.toString();
    _seuilEliminationController.text = _currentSettings.seuilElimination.toString();
  }

  void _updateSeuilAlerte(String value) {
    final intValue = int.tryParse(value);
    if (intValue != null && intValue >= 0 && intValue <= 100) {
      setState(() {
        _currentSettings = _settingsService.mettreAJourSeuils(
          intValue,
          _currentSettings.seuilElimination,
        );
      });
    }
  }

  void _updateSeuilElimination(String value) {
    final intValue = int.tryParse(value);
    if (intValue != null && intValue >= 0 && intValue <= 100) {
      setState(() {
        _currentSettings = _settingsService.mettreAJourSeuils(
          _currentSettings.seuilAvertissement,
          intValue,
        );
      });
    }
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _currentSettings = _settingsService.mettreAJourTheme(value);
    });
  }

  void _changeDisplayMode(ModeAffichage mode) {
    setState(() {
      _currentSettings = _settingsService.mettreAJourModeAffichage(mode);
    });
  }

  Future<void> _resetAllData() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
          'Êtes-vous sûr de vouloir réinitialiser toutes les données ? '
          'Cette action est irréversible et supprimera :\n'
          '• Toutes les absences\n'
          '• Tous les événements\n'
          '• Tous les paramètres\n\n'
          'Les groupes et matières seront conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      
      try {
        // Réinitialiser les paramètres
        _currentSettings = SettingsModel(
          seuilAvertissement: 3,
          seuilElimination: 7,
          isDarkMode: false,
          modeAffichage: ModeAffichage.liste,
        );
        await Hive.box('settings').put('current', _currentSettings);
        
        // Vider les autres boxes (sauf groups et subjects)
        final boxesToClear = ['absences', 'pedagogical_events', 'events'];
        for (var boxName in boxesToClear) {
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).clear();
          }
        }
        
        _showSuccessSnackBar('Données réinitialisées avec succès');
        
        // Réinitialiser les contrôleurs
        _seuilAlerteController.text = '3';
        _seuilEliminationController.text = '7';
        
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la réinitialisation: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    
    try {
      // Récupérer toutes les données
      final allData = await _collectAllData();
      
      // Demander où sauvegarder
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Sauvegarder la sauvegarde',
        fileName: 'abs_flow_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}',
        allowedExtensions: ['json'],
        type: FileType.custom,
      );
      
      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(jsonEncode(allData));
        _showSuccessSnackBar('Sauvegarde exportée avec succès');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'export: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importData() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importation des données'),
        content: const Text(
          'Attention : L\'importation va écraser toutes les données existantes. '
          'Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Importer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    
    try {
      // Sélectionner le fichier
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );
      
      if (result != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString);
        
        // Restaurer les données
        await _restoreData(data);
        
        // Recharger les paramètres
        _currentSettings = _settingsService.getSettings();
        _seuilAlerteController.text = _currentSettings.seuilAvertissement.toString();
        _seuilEliminationController.text = _currentSettings.seuilElimination.toString();
        
        _showSuccessSnackBar('Données importées avec succès');
        setState(() {});
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'import: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _collectAllData() async {
    final Map<String, dynamic> data = {};
    
    // Collecter les données de chaque box
    final boxes = ['settings', 'absences', 'pedagogical_events', 'events', 'groups', 'subjects'];
    
    for (var boxName in boxes) {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        data[boxName] = box.keys.map((key) => {
          'key': key.toString(),
          'value': box.get(key),
        }).toList();
      }
    }
    
    // Ajouter les métadonnées
    data['metadata'] = {
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'totalItems': data.values.fold(0, (sum, boxData) => sum + (boxData as List).length),
    };
    
    return data;
  }

  Future<void> _restoreData(Map<String, dynamic> data) async {
    // Restaurer chaque box
    for (var entry in data.entries) {
      if (entry.key == 'metadata') continue;
      
      if (Hive.isBoxOpen(entry.key)) {
        final box = Hive.box(entry.key);
        await box.clear();
        
        for (var item in (entry.value as List)) {
          await box.put(item['key'], item['value']);
        }
      }
    }
  }

  Future<void> _exportCSV() async {
    setState(() => _isLoading = true);
    
    try {
      // Exemple: exporter les absences en CSV
      if (Hive.isBoxOpen('absences')) {
        final absencesBox = Hive.box('absences');
        final csvData = StringBuffer();
        
        // En-tête CSV
        csvData.writeln('ID,Étudiant,Date,Matière,Groupe,Heure');
        
        // Données
        for (var key in absencesBox.keys) {
          final absence = absencesBox.get(key);
          if (absence != null) {
            // Adapter selon votre modèle d'absence
            csvData.writeln('$key,${absence.toString()}');
          }
        }
        
        // Sauvegarder
        final String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Exporter en CSV',
          fileName: 'absences_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv',
          allowedExtensions: ['csv'],
          type: FileType.custom,
        );
        
        if (outputPath != null) {
          final file = File(outputPath);
          await file.writeAsString(csvData.toString());
          _showSuccessSnackBar('CSV exporté avec succès');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'export CSV: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _seuilAlerteController.dispose();
    _seuilEliminationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle('Seuils d\'absence'),
                const SizedBox(height: 12),
                _buildThresholdCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Affichage'),
                const SizedBox(height: 12),
                _buildDisplayCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Thème'),
                const SizedBox(height: 12),
                _buildThemeCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Gestion des données'),
                const SizedBox(height: 12),
                _buildDataManagementCard(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildThresholdCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Définir les pourcentages d\'alerte et d\'élimination',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildThresholdField(
                    label: 'Seuil d\'alerte (%)',
                    controller: _seuilAlerteController,
                    onChanged: _updateSeuilAlerte,
                    icon: Icons.warning,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildThresholdField(
                    label: 'Seuil d\'élimination (%)',
                    controller: _seuilEliminationController,
                    onChanged: _updateSeuilElimination,
                    icon: Icons.block,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
             Text(
              'L\'alerte est déclenchée à ${_currentSettings.seuilAvertissement}% d\'absence, '
              'l\'élimination à ${_currentSettings.seuilElimination}%',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    required IconData icon,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        border: const OutlineInputBorder(),
        suffixText: '%',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
    );
  }

  Widget _buildDisplayCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mode d\'affichage des listes d\'étudiants',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDisplayOption(
                    title: 'Liste',
                    icon: Icons.list,
                    mode: ModeAffichage.liste,
                    isSelected: _currentSettings.modeAffichage == ModeAffichage.liste,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDisplayOption(
                    title: 'Grille',
                    icon: Icons.grid_view,
                    mode: ModeAffichage.grille,
                    isSelected: _currentSettings.modeAffichage == ModeAffichage.grille,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayOption({
    required String title,
    required IconData icon,
    required ModeAffichage mode,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _changeDisplayMode(mode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apparence de l\'application',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _currentSettings.isDarkMode,
              onChanged: _toggleDarkMode,
              title: const Text('Mode sombre'),
              subtitle: const Text('Activer le thème sombre'),
              secondary: Icon(
                _currentSettings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: _currentSettings.isDarkMode ? Colors.amber : Colors.blue,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestion et sauvegarde des données',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildDataButton(
              title: 'Exporter les données',
              subtitle: 'Sauvegarder en format JSON',
              icon: Icons.backup,
              color: Colors.green,
              onTap: _exportData,
            ),
            const SizedBox(height: 12),
            _buildDataButton(
              title: 'Exporter en CSV',
              subtitle: 'Format tableur pour les absences',
              icon: Icons.table_chart,
              color: Colors.blue,
              onTap: _exportCSV,
            ),
            const SizedBox(height: 12),
            _buildDataButton(
              title: 'Importer des données',
              subtitle: 'Restaurer depuis un fichier JSON',
              icon: Icons.restore,
              color: Colors.orange,
              onTap: _importData,
            ),
            const SizedBox(height: 12),
            _buildDataButton(
              title: 'Réinitialiser les données',
              subtitle: 'Supprimer toutes les données (irréversible)',
              icon: Icons.delete_forever,
              color: Colors.red,
              onTap: _resetAllData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      tileColor: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
    );
  }
}