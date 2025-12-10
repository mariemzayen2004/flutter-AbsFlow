import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/settings/settings.dart';
import '../models/subject/subject.dart';
import '../services/setting_service.dart';
import '../services/subjectService.dart';
import '../services/group_services.dart';
import '../models/group/group.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsService _settingsService;
  late SubjectService _subjectService;
  late GroupesService _groupesService;
  bool _isLoading = false;
  
  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  
  // Contrôleurs pour les seuils globaux (en heures)
  final TextEditingController _globalSeuilAlerteController = TextEditingController();
  final TextEditingController _globalSeuilEliminationController = TextEditingController();
  
  // Contrôleurs pour les seuils par matière (en heures)
  final TextEditingController _subjectAlerteController = TextEditingController();
  final TextEditingController _subjectEliminationController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _settingsService = SettingsService.instance;
      
      // Initialiser les services de matières et groupes
      final groupsBox = await Hive.openBox<Group>('groups');
      final subjectsBox = await Hive.openBox<Subject>('subjects');
      
      _groupesService = GroupesService(groupsBox);
      _subjectService = SubjectService(subjectsBox);
      
      await _groupesService.insertGroups();
      await _subjectService.insertSubjects();
      
      _subjects = _subjectService.getSubjects();
      if (_subjects.isNotEmpty) {
        _selectedSubject = _subjects.first;
        _loadSubjectThresholds(_selectedSubject!);
      }
      
      final currentSettings = _settingsService.getSettings();
      
      // Initialiser les contrôleurs globaux (en heures)
      _globalSeuilAlerteController.text = currentSettings.seuilAvertissement.toString();
      _globalSeuilEliminationController.text = currentSettings.seuilElimination.toString();
      
    } catch (e) {
      print('Erreur d\'initialisation: $e');
      _showErrorSnackBar('Erreur lors du chargement des données');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateGlobalSeuilAlerte(String value) {
    final intValue = int.tryParse(value);
    if (intValue != null && intValue >= 0) {
      final currentSettings = _settingsService.getSettings();
      _settingsService.mettreAJourSeuils(
        intValue,
        currentSettings.seuilElimination,
      );
      _globalSeuilAlerteController.text = intValue.toString();
    }
  }

  void _updateGlobalSeuilElimination(String value) {
    final intValue = int.tryParse(value);
    if (intValue != null && intValue >= 0) {
      final currentSettings = _settingsService.getSettings();
      _settingsService.mettreAJourSeuils(
        currentSettings.seuilAvertissement,
        intValue,
      );
      _globalSeuilEliminationController.text = intValue.toString();
    }
  }

  void _toggleDarkMode(bool value) {
    _settingsService.mettreAJourTheme(value);
    // Le setState n'est pas nécessaire car ValueListenableBuilder s'en charge
  }

  void _changeDisplayMode(ModeAffichage mode) {
    _settingsService.mettreAJourModeAffichage(mode);
    setState(() {}); // Rafraîchir l'UI locale
  }

  Future<void> _loadSubjectThresholds(Subject subject) async {
    try {
      final box = await Hive.openBox('subject_thresholds');
      final data = box.get('subject_${subject.id}');
      
      if (data != null) {
        final thresholds = data as Map<String, dynamic>;
        _subjectAlerteController.text = thresholds['seuilAlerte'].toString();
        _subjectEliminationController.text = thresholds['seuilElimination'].toString();
      } else {
        _subjectAlerteController.text = '4';
        _subjectEliminationController.text = '5';
      }
    } catch (e) {
      print('Erreur lors du chargement des seuils: $e');
      _subjectAlerteController.text = '4';
      _subjectEliminationController.text = '5';
    }
  }

  Future<void> _saveSubjectThresholds() async {
    if (_selectedSubject == null) return;
    
    final seuilAlerte = int.tryParse(_subjectAlerteController.text);
    final seuilElimination = int.tryParse(_subjectEliminationController.text);
    
    if (seuilAlerte != null && seuilElimination != null && 
        seuilAlerte >= 0 && seuilElimination >= 0) {
      
      try {
        final box = await Hive.openBox('subject_thresholds');
        await box.put('subject_${_selectedSubject!.id}', {
          'seuilAlerte': seuilAlerte,
          'seuilElimination': seuilElimination,
          'subjectId': _selectedSubject!.id,
          'subjectName': _selectedSubject!.nom,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        
        _showSuccessSnackBar('Seuils pour ${_selectedSubject!.nom} sauvegardés');
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
      }
    } else {
      _showErrorSnackBar('Veuillez entrer des valeurs valides (nombres positifs)');
    }
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
        final newSettings = SettingsModel(
          seuilAvertissement: 4,
          seuilElimination: 5,
          isDarkMode: false,
          modeAffichage: ModeAffichage.liste,
        );
        await Hive.box<SettingsModel>('settings').put('current', newSettings);
        
        // Vider les autres boxes
        final boxesToClear = ['absences', 'pedagogical_events', 'events', 'alerts', 'subject_thresholds'];
        for (var boxName in boxesToClear) {
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).clear();
          }
        }
        
        _showSuccessSnackBar('Données réinitialisées avec succès');
        
        // Réinitialiser les contrôleurs
        _globalSeuilAlerteController.text = '4';
        _globalSeuilEliminationController.text = '5';
        if (_selectedSubject != null) {
          _subjectAlerteController.text = '4';
          _subjectEliminationController.text = '5';
        }
        
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
      final allData = await _collectAllData();
      
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Sauvegarder la sauvegarde',
        fileName: 'abs_flow_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json',
        allowedExtensions: ['json'],
        type: FileType.custom,
      );
      
      if (outputPath != null && outputPath.isNotEmpty) {
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        if (filePath != null) {
          final file = File(filePath);
          final jsonString = await file.readAsString();
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          
          await _restoreData(data);
          
          final currentSettings = _settingsService.getSettings();
          _globalSeuilAlerteController.text = currentSettings.seuilAvertissement.toString();
          _globalSeuilEliminationController.text = currentSettings.seuilElimination.toString();
          
          if (_selectedSubject != null) {
            _loadSubjectThresholds(_selectedSubject!);
          }
          
          _showSuccessSnackBar('Données importées avec succès');
          setState(() {});
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'import: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _collectAllData() async {
    final Map<String, dynamic> data = {};
    
    final boxes = ['settings', 'absences', 'pedagogical_events', 'events', 'groups', 'subjects', 'alerts', 'subject_thresholds'];
    
    for (var boxName in boxes) {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        final boxData = <Map<String, dynamic>>[];
        
        for (var key in box.keys) {
          final value = box.get(key);
          if (value != null) {
            boxData.add({
              'key': key.toString(),
              'value': value,
            });
          }
        }
        
        data[boxName] = boxData;
      }
    }
    
    data['metadata'] = {
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'totalItems': data.values.fold(0, (sum, boxData) => sum + (boxData as List).length),
    };
    
    return data;
  }

  Future<void> _restoreData(Map<String, dynamic> data) async {
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
      if (Hive.isBoxOpen('absences')) {
        final absencesBox = Hive.box('absences');
        final csvData = StringBuffer();
        
        csvData.writeln('ID,Étudiant ID,Date,Matière,Groupe,Heures manquées,Remarque,Justifié');
        
        for (var key in absencesBox.keys) {
          final absence = absencesBox.get(key);
          if (absence != null) {
            final absenceMap = absence.toJson() as Map<String, dynamic>;
            csvData.writeln('$key,${absenceMap['studentId']},${absenceMap['date']},'
                '${absenceMap['subjectId']},${absenceMap['groupId']},'
                '${absenceMap['heuresManquees'] ?? ""},${absenceMap['remarque'] ?? ""},'
                '${absenceMap['justifie'] ?? false}');
          }
        }
        
        final String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Exporter en CSV',
          fileName: 'absences_export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv',
          allowedExtensions: ['csv'],
          type: FileType.custom,
        );
        
        if (outputPath != null && outputPath.isNotEmpty) {
          final file = File(outputPath);
          await file.writeAsString(csvData.toString());
          _showSuccessSnackBar('CSV exporté avec succès');
        }
      } else {
        _showErrorSnackBar('Aucune donnée d\'absence à exporter');
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _globalSeuilAlerteController.dispose();
    _globalSeuilEliminationController.dispose();
    _subjectAlerteController.dispose();
    _subjectEliminationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<Box<SettingsModel>>(
              valueListenable: Hive.box<SettingsModel>('settings').listenable(),
              builder: (context, box, _) {
                final currentSettings = _settingsService.getSettings();
                
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionTitle('Seuils globaux d\'absence (en heures)', isDarkMode),
                    const SizedBox(height: 12),
                    _buildGlobalThresholdCard(isDarkMode, currentSettings),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Seuils par matière (en heures)', isDarkMode),
                    const SizedBox(height: 12),
                    _buildSubjectThresholdCard(isDarkMode),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Affichage', isDarkMode),
                    const SizedBox(height: 12),
                    _buildDisplayCard(isDarkMode, currentSettings),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Thème', isDarkMode),
                    const SizedBox(height: 12),
                    _buildThemeCard(isDarkMode, currentSettings),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Gestion des données', isDarkMode),
                    const SizedBox(height: 12),
                    _buildDataManagementCard(isDarkMode),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.blue[300] : Colors.blue,
      ),
    );
  }

  Widget _buildGlobalThresholdCard(bool isDarkMode, SettingsModel currentSettings) {
    return Card(
      elevation: 2,
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Définir les seuils d\'alerte et d\'élimination globaux',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildThresholdField(
                    label: 'Seuil d\'alerte (heures)',
                    controller: _globalSeuilAlerteController,
                    onChanged: _updateGlobalSeuilAlerte,
                    icon: Icons.warning,
                    color: Colors.orange,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildThresholdField(
                    label: 'Seuil d\'élimination (heures)',
                    controller: _globalSeuilEliminationController,
                    onChanged: _updateGlobalSeuilElimination,
                    icon: Icons.block,
                    color: Colors.red,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ces seuils s\'appliquent à toutes les matières sauf si des seuils spécifiques sont définis',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectThresholdCard(bool isDarkMode) {
    return Card(
      elevation: 2,
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Définir des seuils spécifiques par matière',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<Subject>(
              value: _selectedSubject,
              decoration: InputDecoration(
                labelText: 'Sélectionner une matière',
                border: OutlineInputBorder(),
                filled: isDarkMode,
                fillColor: isDarkMode ? Colors.grey[700] : null,
              ),
              dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              items: _subjects.map((Subject subject) {
                return DropdownMenuItem<Subject>(
                  value: subject,
                  child: Text(
                    '${subject.nom} - ${subject.enseignant}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (Subject? newValue) {
                setState(() {
                  _selectedSubject = newValue;
                  if (newValue != null) {
                    _loadSubjectThresholds(newValue);
                  }
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            if (_selectedSubject != null) ...[
              Text(
                'Matière sélectionnée: ${_selectedSubject!.nom}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                'Enseignant: ${_selectedSubject!.enseignant}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subjectAlerteController,
                      decoration: InputDecoration(
                        labelText: 'Seuil alerte (heures)',
                        border: OutlineInputBorder(),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[700] : null,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _subjectEliminationController,
                      decoration: InputDecoration(
                        labelText: 'Seuil élimination (heures)',
                        border: OutlineInputBorder(),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[700] : null,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: _saveSubjectThresholds,
                icon: Icon(Icons.save),
                label: Text('Sauvegarder les seuils'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Aucune matière disponible',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
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
    required bool isDarkMode,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(),
        suffixText: 'h',
        filled: isDarkMode,
        fillColor: isDarkMode ? Colors.grey[700] : null,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
    );
  }

  Widget _buildDisplayCard(bool isDarkMode, SettingsModel currentSettings) {
    return Card(
      elevation: 2,
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mode d\'affichage des listes d\'étudiants',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDisplayOption(
                    title: 'Liste',
                    icon: Icons.list,
                    mode: ModeAffichage.liste,
                    isSelected: currentSettings.modeAffichage == ModeAffichage.liste,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDisplayOption(
                    title: 'Grille',
                    icon: Icons.grid_view,
                    mode: ModeAffichage.grille,
                    isSelected: currentSettings.modeAffichage == ModeAffichage.grille,
                    isDarkMode: isDarkMode,
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
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: () => _changeDisplayMode(mode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? Colors.blue[900] : Colors.blue.withOpacity(0.1))
              : (isDarkMode ? Colors.grey[700] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.blue : (isDarkMode ? Colors.grey[400] : Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? Colors.blue 
                    : (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(bool isDarkMode, SettingsModel currentSettings) {
    return Card(
      elevation: 2,
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apparence de l\'application',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: currentSettings.isDarkMode,
              onChanged: _toggleDarkMode,
              title: Text(
                'Mode sombre',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Activer le thème sombre',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey,
                ),
              ),
              secondary: Icon(
                currentSettings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: currentSettings.isDarkMode ? Colors.amber : Colors.blue,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementCard(bool isDarkMode) {
    return Card(
      elevation: 2,
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion et sauvegarde des données',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildDataButton(
              title: 'Exporter les données',
              subtitle: 'Sauvegarder en format JSON',
              icon: Icons.backup,
              color: Colors.green,
              onTap: _exportData,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            _buildDataButton(
              title: 'Exporter en CSV',
              subtitle: 'Format tableur pour les absences',
              icon: Icons.table_chart,
              color: Colors.blue,
              onTap: _exportCSV,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            _buildDataButton(
              title: 'Importer des données',
              subtitle: 'Restaurer depuis un fichier JSON',
              icon: Icons.restore,
              color: Colors.orange,
              onTap: _importData,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            _buildDataButton(
              title: 'Réinitialiser les données',
              subtitle: 'Supprimer toutes les données (irréversible)',
              icon: Icons.delete_forever,
              color: Colors.red,
              onTap: _resetAllData,
              isDarkMode: isDarkMode,
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
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      tileColor: isDarkMode ? Colors.grey[700] : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
    );
  }
}