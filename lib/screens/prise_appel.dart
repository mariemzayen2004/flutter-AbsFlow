import 'package:abs_flow/main.dart';
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
  bool _isLoading = true;

  final Map<int, _StudentPresenceState> _presenceStates = {};

  @override
  void initState() {
    super.initState();

    final hive = HiveService.instance;
    _groupesService = GroupesService(hive.groupsBox);
    _subjectService = SubjectService(hive.subjectsBox);
    _settingsService = SettingsService.instance;
    _sessionService = SessionService(hive.sessionsBox);
    _studentService = StudentService(hive.studentsBox);
    _alertService = AlertService(hive.alertsBox, _studentService);
    _attendanceService = AttendanceService(hive.attendancesBox);

    _groupesService.insertGroups();
    _subjectService.insertSubjects();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final groupes = await _groupesService.getGroupes();
    final subjects = _subjectService.getSubjects();
    final settings = _settingsService.getSettings();

    print('Groupes chargés : ${_groupes.length}');

    setState(() {
      _groupes = groupes;
      _subjects = subjects;
      _modeAffichage = settings.modeAffichage;
      _isLoading = false;
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
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
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Choisissez un groupe et une matière.')),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Aucun étudiant dans ce groupe.')),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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

      final sessionId = await _sessionService.ajouterSession(
        _selectedGroup!.id,
        _selectedSubject!.id,
        date,
        heureDebutDt,
        heureFinDt,
      );

      for (final student in _students) {
        final state = _presenceStates[student.id];
        if (state == null) continue;

        final present = state.present;
        final heuresManquees = present ? 0 : state.heuresManquees;
        final remarque =
            state.remarque.trim().isEmpty ? null : state.remarque.trim();

        await _attendanceService.ajouterAttendancePourSession(
          sessionId,
          student.id,
          present,
          heuresManquees,
          remarque,
        );
        
        print("Nombre d'heures manquées pour ${student.prenom} ${student.nom}: $heuresManquees");
        //await _verifierSeuilsEtGenererAlerte(student.id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Séance enregistrée avec succès.')),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      setState(() {
        _selectedGroup = null;
        _selectedSubject = null;
        _students.clear();
        _presenceStates.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erreur lors de l\'enregistrement : $e')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Future<void> _verifierSeuilsEtGenererAlerte(int studentId) async {
  //   final settings = _settingsService.getSettings();
  //   final attendances = _attendanceService.getAttendanceByStudent(studentId);

  //   final totalHeuresAbsence = attendances.fold<int>(
  //     0,
  //     (sum, a) => sum + a.heuresManquees,
  //   );

  //   AlertLevel? niveau;

  //   if (totalHeuresAbsence >= settings.seuilElimination) {
  //     niveau = AlertLevel.elimination;
  //   } else if (totalHeuresAbsence >= settings.seuilAvertissement) {
  //     niveau = AlertLevel.avertissement;
  //   }

  //   if (niveau == null) return;

  //   final alerte = await _alertService.creerAlerte(
  //     studentId: studentId,
  //     totalHeuresAbsence: totalHeuresAbsence,
  //     niveau: niveau,
  //   );

  //   await _alertService.envoyerAlerteEmail(alerte.id);
  // }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
              const SizedBox(height: 16),
              Text(
                'Chargement des données...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Prise d\'appel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _modeAffichage = _modeAffichage == ModeAffichage.grille
                      ? ModeAffichage.liste
                      : ModeAffichage.grille;
                });
                _settingsService.mettreAJourModeAffichage(_modeAffichage);
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_modeAffichage == ModeAffichage.grille
                    ? Icons.view_list
                    : Icons.grid_view),
              ),
              tooltip: 'Changer affichage',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSelectionCard(),
              const SizedBox(height: 16),
              _buildTimeCard(),
              const SizedBox(height: 16),
              Expanded(
                child: (_selectedGroup == null || _selectedSubject == null)
                    ? _buildEmptyState()
                    : _students.isEmpty
                        ? _buildNoStudentsState()
                        : _modeAffichage == ModeAffichage.grille
                            ? _buildStudentsGrid()
                            : _buildStudentsList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _validerSeance,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check_circle_outline, size: 24),
            label: Text(
              _isSaving ? 'Enregistrement...' : 'Valider la séance',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.settings, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Configuration de la séance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Group>(
                    value: _selectedGroup,
                    decoration: InputDecoration(
                      labelText: 'Groupe',
                      prefixIcon: Icon(Icons.group, color: Colors.blue.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: _groupes
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              'G${g.numGroup} - ${g.filiere} ${g.niveau}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (group) => _onGroupSelected(group),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Subject>(
                    value: _selectedSubject,
                    decoration: InputDecoration(
                      labelText: 'Matière',
                      prefixIcon: Icon(Icons.book, color: Colors.blue.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: _subjects
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s.nom,
                              style: const TextStyle(fontWeight: FontWeight.w600),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.schedule, color: Colors.orange.shade700),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Horaires de la séance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickTimeDebut,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.blue.shade700, size: 24),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Début',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _heureDebut.format(context),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTimeFin,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.blue.shade700, size: 24),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fin',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _heureFin.format(context),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.playlist_add_check,
              size: 80,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Configurez votre séance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez un groupe et une matière\npour démarrer la prise d\'appel',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoStudentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_off,
              size: 80,
              color: Colors.orange.shade300,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun étudiant',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ce groupe ne contient aucun étudiant',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final state = _presenceStates[student.id]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentHeader(student, state),
                if (!state.present) const SizedBox(height: 16),
                if (!state.present) _buildAbsenceFields(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentsGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final state = _presenceStates[student.id]!;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStudentHeaderCompact(student, state),
                const Spacer(),
                if (!state.present) _buildHeuresFieldCompact(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentHeader(Student student, _StudentPresenceState state) {
    return Row(
      children: [
        Hero(
          tag: 'student_${student.id}',
          child: CircleAvatar(
            radius: 32,
            backgroundColor: state.present ? Colors.green.shade100 : Colors.red.shade100,
            backgroundImage: student.photoPath != null
                ? AssetImage(student.photoPath!)
                : null,
            child: student.photoPath == null
                ? Text(
                    '${student.prenom[0]}${student.nom[0]}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: state.present ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${student.nom} ${student.prenom}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: state.present ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.present ? 'Présent' : 'Absent',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: state.present ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ToggleButtons(
            isSelected: [state.present, !state.present],
            onPressed: (index) {
              setState(() {
                state.present = (index == 0);
                if (state.present) {
                  state.heuresManquees = 0;
                  state.remarque = '';
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            selectedColor: Colors.white,
            fillColor: state.present ? Colors.green.shade500 : Colors.red.shade500,
            color: Colors.grey.shade700,
            constraints: const BoxConstraints(minHeight: 40, minWidth: 80),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: const [
                    Icon(Icons.check, size: 16),
                    SizedBox(width: 4),
                    Text('P', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: const [
                    Icon(Icons.close, size: 16),
                    SizedBox(width: 4),
                    Text('A', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentHeaderCompact(Student student, _StudentPresenceState state) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: state.present ? Colors.green.shade100 : Colors.red.shade100,
          backgroundImage: student.photoPath != null
              ? AssetImage(student.photoPath!)
              : null,
          child: student.photoPath == null
              ? Text(
                  '${student.prenom[0]}${student.nom[0]}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: state.present ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          '${student.nom}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${student.prenom}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ToggleButtons(
            isSelected: [state.present, !state.present],
            onPressed: (index) {
              setState(() {
                state.present = (index == 0);
                if (state.present) {
                  state.heuresManquees = 0;
                  state.remarque = '';
                }
              });
            },
            borderRadius: BorderRadius.circular(10),
            selectedColor: Colors.white,
            fillColor: state.present ? Colors.green.shade500 : Colors.red.shade500,
            color: Colors.grey.shade700,
            constraints: const BoxConstraints(minHeight: 32, minWidth: 50),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.check, size: 16),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.close, size: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAbsenceFields(_StudentPresenceState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Détails de l\'absence',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHeuresField(state),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Remarque (optionnel)',
              hintText: 'Justification, raison...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              prefixIcon: Icon(Icons.note, color: Colors.red.shade400),
            ),
            minLines: 2,
            maxLines: 3,
            onChanged: (value) {
              state.remarque = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeuresField(_StudentPresenceState state) {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Heures manquées',
        hintText: 'Ex: 2',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        prefixIcon: Icon(Icons.schedule, color: Colors.red.shade400),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final parsed = int.tryParse(value);
        state.heuresManquees = parsed ?? 0;
      },
    );
  }

  Widget _buildHeuresFieldCompact(_StudentPresenceState state) {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Heures',
        hintText: '0',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.red.shade50,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.bold),
      onChanged: (value) {
        final parsed = int.tryParse(value);
        state.heuresManquees = parsed ?? 0;
      },
    );
  }
}