import 'package:flutter/material.dart';
import '../models/group/group.dart';
import '../models/subject/subject.dart';
import '../models/student/student.dart';
import '../models/alert/alert.dart';
import '../models/settings/settings.dart';

import '../services/alert_services.dart';
import '../services/group_services.dart';
import '../services/hive_service.dart';
import '../services/setting_service.dart';
import '../services/student_service.dart';
import '../services/session_service.dart';
import '../services/attendance_service.dart';
import '../services/subjectService.dart';


class PriseAppelPage extends StatefulWidget {
  const PriseAppelPage({super.key});

  @override
  State<PriseAppelPage> createState() => _PriseAppelPageState();
}

class _StudentPresenceState {
  bool present;
  int heuresManquees;
  String remarque;

  _StudentPresenceState({
    required this.present,
    required this.heuresManquees,
    required this.remarque,
  });
}

class _PriseAppelPageState extends State<PriseAppelPage> {
  // Déclaration des services
  late GroupesService _groupesService;
  late SubjectService _subjectService;
  late SettingsService _settingsService;
  late SessionService _sessionService;
  late StudentService _studentService;
  late AlertService _alertService;
  late AttendanceService _attendanceService;

  // Données UI
  List<Group> _groupes = [];
  List<Subject> _subjects = [];
  List<Student> _students = [];

  Group? _selectedGroup;
  Subject? _selectedSubject;

  TimeOfDay _heureDebut = TimeOfDay.now();
  TimeOfDay _heureFin = TimeOfDay.now();

  ModeAffichage _modeAffichage = ModeAffichage.liste;
  bool _isSaving = false;
  bool _isLoading = true; // Indicateur de chargement

  final Map<int, _StudentPresenceState> _presenceStates = {};

  @override
  void initState() {
    super.initState();

    // Initialisation des services dans initState
    final hive = HiveService.instance;
    _groupesService = GroupesService(hive.groupsBox); // Passer la Box<Group>
    _subjectService = SubjectService(hive.subjectsBox);
    _settingsService = SettingsService.instance;
    _sessionService = SessionService(hive.sessionsBox); // Passer la Box<Session>
    _studentService = StudentService(hive.studentsBox); // Passer la Box<Student>
    _alertService = AlertService(hive.alertsBox, _studentService); // Passer Box<AlertModel> et StudentService
    _attendanceService = AttendanceService(hive.attendancesBox); // Passer la Box<Attendance>

    _groupesService.insertGroups();
    _subjectService.insertSubjects();
    // Charger les données initiales
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Récupérer les groupes et les matières
    final groupes = await _groupesService.getGroupes();
    final subjects = _subjectService.getSubjects();
    final settings = _settingsService.getSettings();

    print('Groupes chargés : ${_groupes.length}');

    setState(() {
      _groupes = groupes;  // Charger les groupes ici
      _subjects = subjects;
      _modeAffichage = settings.modeAffichage;
      _isLoading = false;  // Fin du chargement
    });
  }

  Future<void> _onGroupSelected(Group? group) async {
    setState(() {
      _selectedGroup = group;
      _students = [];
      _presenceStates.clear();
    });

    if (group == null) return;

    final students = _studentService.getStudentsByGroup(group.id);

    setState(() {
      _students = students;
      for (final s in students) {
        _presenceStates[s.id] = _StudentPresenceState(
          present: true,
          heuresManquees: 0,
          remarque: '',
        );
      }
    });
  }

  Future<void> _pickTimeDebut() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heureDebut,
    );
    if (picked != null) {
      setState(() {
        _heureDebut = picked;
      });
    }
  }

  Future<void> _pickTimeFin() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heureFin,
    );
    if (picked != null) {
      setState(() {
        _heureFin = picked;
      });
    }
  }

  Future<void> _validerSeance() async {
  if (_selectedGroup == null || _selectedSubject == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Choisissez un groupe et une matière.')),
    );
    return;
  }

  if (_students.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucun étudiant dans ce groupe.')),
    );
    return;
  }

  setState(() {
    _isSaving = true;
  });

  try {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);

    final heureDebutDt = DateTime(
      date.year,
      date.month,
      date.day,
      _heureDebut.hour,
      _heureDebut.minute,
    );

    final heureFinDt = DateTime(
      date.year,
      date.month,
      date.day,
      _heureFin.hour,
      _heureFin.minute,
    );

    // 1️⃣ Créer la séance via le service SessionService sans spécifier l'ID
    final sessionId = await _sessionService.ajouterSession(
      _selectedGroup!.id,
      _selectedSubject!.id,
      date,
      heureDebutDt,
      heureFinDt,
    );

    // 2️⃣ Enregistrer les présences pour chaque étudiant via le service AttendanceService
    for (final student in _students) {
      final state = _presenceStates[student.id];
      if (state == null) continue;

      final present = state.present;
      final heuresManquees = present ? 0 : state.heuresManquees;
      final remarque =
          state.remarque.trim().isEmpty ? null : state.remarque.trim();

      // Utiliser le service pour ajouter la présence sans spécifier d'ID
      await _attendanceService.ajouterAttendancePourSession(
        sessionId,
        student.id,
        present,
        heuresManquees,
        remarque,
      );

      // 3️⃣ Vérifier en "temps réel" après l'enregistrement pour générer une alerte si nécessaire
      await _verifierSeuilsEtGenererAlerte(student.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Séance enregistrée avec succès.')),
    );

    // Option : reset après validation
    setState(() {
      _selectedGroup = null;
      _selectedSubject = null;
      _students.clear();
      _presenceStates.clear();
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur lors de l\'enregistrement : $e'),
      ),
    );
  } finally {
    setState(() {
      _isSaving = false;
    });
  }
}

  /// Vérifie les seuils d'alerte/élimination pour un étudiant donné
  Future<void> _verifierSeuilsEtGenererAlerte(int studentId) async {
    final settings = _settingsService.getSettings();

    // Toutes les présences/absences de cet étudiant
    final attendances = _attendanceService.getAttendanceByStudent(studentId);

    final totalHeuresAbsence = attendances.fold<int>(
      0,
      (sum, a) => sum + a.heuresManquees,
    );

    AlertLevel? niveau;

    if (totalHeuresAbsence >= settings.seuilElimination) {
      niveau = AlertLevel.elimination;
    } else if (totalHeuresAbsence >= settings.seuilAvertissement) {
      niveau = AlertLevel.avertissement;
    }

    if (niveau == null) return;

    // Création de l’alerte
    final alerte = await _alertService.creerAlerte(
      studentId: studentId,
      totalHeuresAbsence: totalHeuresAbsence,
      niveau: niveau,
    );

    // Envoi email (mock → print)
    await _alertService.envoyerAlerteEmail(alerte.id);
  }

  @override
  Widget build(BuildContext context) {
    // Affichage de l'indicateur de chargement
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prise d\'appel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectionRow(),
            const SizedBox(height: 8),
            _buildTimeRow(),
            const SizedBox(height: 12),
            Expanded(
              child: (_selectedGroup == null || _selectedSubject == null)
                  ? const Center(
                      child: Text(
                        'Sélectionnez un groupe et une matière pour démarrer la séance.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _students.isEmpty
                      ? const Center(child: Text('Aucun étudiant dans ce groupe.'))
                      : _modeAffichage == ModeAffichage.grille
                          ? _buildStudentsGrid()
                          : _buildStudentsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _validerSeance,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isSaving ? 'Enregistrement...' : 'Valider la séance'),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Échec':
        return Colors.red;
      case 'Alerte':
        return Colors.orange;
      default:
        return Colors.green; // Normal
    }
  }

  // ---------------- Dropdown Box ----------------

  Widget _buildSelectionRow() {
  return Row(
    children: [
      Expanded(
        child: DropdownButtonFormField<Group>(
          value: _selectedGroup,
          decoration: InputDecoration(
            labelText: 'Groupe',
            labelStyle: TextStyle(color: Colors.blueAccent),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _groupes
              .map(
                (g) => DropdownMenuItem(
                  value: g,
                  child: Text(
                    'G${g.numGroup} - ${g.filiere} ${g.niveau}',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              )
              .toList(),
          onChanged: (group) => _onGroupSelected(group),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: DropdownButtonFormField<Subject>(
          value: _selectedSubject,
          decoration: InputDecoration(
            labelText: 'Matière',
            labelStyle: TextStyle(color: Colors.blueAccent),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _subjects
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s.nom,
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              )
              .toList(),
          onChanged: (subject) {
            setState(() {
              _selectedSubject = subject;
            });
          },
        ),
      ),
    ],
  );
}

  Widget _buildTimeRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickTimeDebut,
            icon: Icon(Icons.access_time, color: Colors.blue),
            label: Text('Début : ${_heureDebut.format(context)}',
                style: TextStyle(color: Colors.blue)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue),
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickTimeFin,
            icon: Icon(Icons.access_time, color: Colors.blue),
            label: Text('Fin : ${_heureFin.format(context)}',
                style: TextStyle(color: Colors.blue)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue),
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList() {
    return SingleChildScrollView( // Ajout de SingleChildScrollView pour le défilement
      child: Column(
        children: List.generate(_students.length, (index) {
          final student = _students[index];
          final state = _presenceStates[student.id]!;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStudentHeader(student, state),
                  if (!state.present) const SizedBox(height: 8),
                  if (!state.present) _buildAbsenceFields(state),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStudentsGrid() {
  // Obtenir la largeur de l'écran
  double screenWidth = MediaQuery.of(context).size.width;

  // Ajuster le nombre de colonnes en fonction de la largeur de l'écran
  int crossAxisCount = screenWidth < 600 ? 2 : 3; // Par exemple, 2 colonnes pour petits écrans, 3 pour grands écrans

  // Calculer un ratio d'aspect adapté
  double aspectRatio = screenWidth / 2 / 150; // Ajuster selon la taille de l'élément dans la grille

  return SingleChildScrollView(  // Ajouter un scroll vertical si nécessaire
    child: GridView.builder(
      shrinkWrap: true,  // Permet à GridView de ne pas prendre plus d'espace que nécessaire
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,  // Dynamique en fonction de l'écran
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final state = _presenceStates[student.id]!;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildStudentHeader(student, state),
                const Spacer(), // Utiliser Spacer pour donner de l'espace
                if (!state.present) _buildHeuresField(state),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildStudentHeader(Student student, _StudentPresenceState state) {
  return Row(
    children: [
      CircleAvatar(
        radius: 30,
        backgroundColor: Colors.blue[100],
        backgroundImage: student.photoPath != null
            ? AssetImage(student.photoPath!)
            : null,
        child: student.photoPath == null
            ? Text(
                '${student.prenom[0]}${student.nom[0]}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${student.nom} ${student.prenom}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Matricule: ${student.matricule}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Groupe: ${student.groupId ?? "Non assigné"}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Toggle button pour marquer Présent/Absent
          ToggleButtons(
            isSelected: [state.present, !state.present],
            onPressed: (index) {
              setState(() {
                // Modifie l'état de 'Présent' ou 'Absent' en fonction du bouton sélectionné
                state.present = index == 0; // Présent si index 0, Absent si index 1

                if (state.present) {
                  // Réinitialiser les heures manquées et les remarques si l'étudiant est présent
                  state.heuresManquees = 0;
                  state.remarque = '';
                }
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Présent'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Absent'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Afficher les heures manquées (si absent)
          if (!state.present)
            TextField(
              decoration: const InputDecoration(
                labelText: 'Heures manquées',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final parsed = int.tryParse(value);
                state.heuresManquees = parsed ?? 0;
              },
            ),
          
          const SizedBox(height: 8),
          
          // Champ pour ajouter une remarque (si absent)
          if (!state.present)
            TextField(
              decoration: const InputDecoration(
                labelText: 'Remarque (optionnel)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              minLines: 1,
              maxLines: 2,
              onChanged: (value) {
                state.remarque = value;
              },
            ),
          
          const SizedBox(height: 8),

          // Affichage de l'état (Présent/Absent)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(state.present ? 'Normal' : 'Absent')
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getStatusColor(state.present ? 'Normal' : 'Absent')),
            ),
            child: Text(
              state.present ? 'Présent' : 'Absent',
              style: TextStyle(
                color: _getStatusColor(state.present ? 'Normal' : 'Absent'),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Affichage des heures manquées si nécessaire
          if (!state.present)
            Text(
              '${state.heuresManquees}h',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    ],
  );
}

  Widget _buildAbsenceFields(_StudentPresenceState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeuresField(state),
        const SizedBox(height: 4),
        TextField(
          decoration: InputDecoration(
            labelText: 'Remarque (optionnel)',
            labelStyle: TextStyle(color: Colors.blueAccent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
            isDense: true,
          ),
          minLines: 1,
          maxLines: 2,
          onChanged: (value) {
            state.remarque = value;
          },
        ),
      ],
    );
  }

  Widget _buildHeuresField(_StudentPresenceState state) {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Heures manquées',
        labelStyle: TextStyle(color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final parsed = int.tryParse(value);
        state.heuresManquees = parsed ?? 0;
      },
    );
  }
}