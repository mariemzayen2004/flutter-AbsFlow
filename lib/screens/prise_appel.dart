import 'package:flutter/material.dart';
import '../models/attendance/attendance.dart';
import '../models/group/group.dart';
import '../models/session/session.dart';
import '../models/student/student.dart';
import '../models/subject/subject.dart';
import '../services/hive_service.dart';


class PriseAppelPage extends StatefulWidget {
  const PriseAppelPage({super.key});

  @override
  State<PriseAppelPage> createState() => _PriseAppelPageState();
}

class _PriseAppelPageState extends State<PriseAppelPage> {
  final hive = HiveService.instance;

  List<Group> _groups = [];
  List<Subject> _subjects = [];
  List<Student> _students = [];

  Group? _selectedGroup;
  Subject? _selectedSubject;

  TimeOfDay _heureDebut = TimeOfDay.now();
  TimeOfDay _heureFin = TimeOfDay.now();

  bool _isGridView = false;
  bool _isSaving = false;

  // Etat de présence pour chaque étudiant
  final Map<int, _StudentPresenceState> _presenceStates = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _groups = hive.groupsBox.values.toList();
    _subjects = hive.subjectsBox.values.toList();
    setState(() {});
  }

  void _onGroupSelected(Group? group) {
    setState(() {
      _selectedGroup = group;
      _students = hive.studentsBox.values
          .where((s) => s.groupId == group?.id)
          .toList();
      _presenceStates.clear();
      for (final student in _students) {
        _presenceStates[student.id] = _StudentPresenceState(
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
      // 1) Créer la Session
      final newSessionId = hive.sessionsBox.length + 1;
      final now = DateTime.now();

      final debutDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _heureDebut.hour,
        _heureDebut.minute,
      );

      final finDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _heureFin.hour,
        _heureFin.minute,
      );

      final session = Session(
        id: newSessionId,
        groupId: _selectedGroup!.id,
        subjectId: _selectedSubject!.id,
        date: DateTime(now.year, now.month, now.day),
        heureDebut: debutDateTime, // DateTime
        heureFin: finDateTime,     // DateTime
      );

      await hive.sessionsBox.put(session.id, session);

      // 2) Créer les Attendance pour chaque étudiant
      var nextAttendanceId = hive.attendancesBox.length + 1;

      for (final student in _students) {
        final state = _presenceStates[student.id];
        if (state == null) continue;

        final present = state.present;
        final heuresManquees = present ? 0 : state.heuresManquees;
        final remarque = state.remarque.isEmpty ? null : state.remarque;

        final attendance = Attendance(
          id: nextAttendanceId++,
          sessionId: session.id,
          studentId: student.id,
          present: present ? true : false,
          heuresManquees: heuresManquees,
          remarque: remarque,
        );

        await hive.attendancesBox.put(attendance.id, attendance);

        // 3) TODO: ici, tu peux calculer le total d'heures d'absence
        // de l'étudiant et comparer aux seuils pour générer une alerte.
        //
        // Exemple de logique (à implémenter plus tard) :
        // - lire toutes les Attendance de ce student
        // - sommer les heuresManquees
        // - comparer avec SettingsModel (seuilAvertissement / seuilElimination)
        // - si dépassé : créer un AlertModel et déclencher l'envoi d'e-mail
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Séance enregistrée avec succès.')),
      );

      // Option : tu peux vider la sélection ou revenir en arrière ici

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prise d\'appel'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: 'Changer affichage',
          ),
        ],
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
                      : _isGridView
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

  Widget _buildSelectionRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<Group>(
            value: _selectedGroup,
            decoration: const InputDecoration(
              labelText: 'Groupe',
              border: OutlineInputBorder(),
            ),
            items: _groups
                .map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text('G${g.numGroup} - ${g.filiere} ${g.niveau}'),
                  ),
                )
                .toList(),
            onChanged: _onGroupSelected,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<Subject>(
            value: _selectedSubject,
            decoration: const InputDecoration(
              labelText: 'Matière',
              border: OutlineInputBorder(),
            ),
            items: _subjects
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.nom),
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
            icon: const Icon(Icons.access_time),
            label: Text('Début : ${_heureDebut.format(context)}'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickTimeFin,
            icon: const Icon(Icons.access_time),
            label: Text('Fin : ${_heureFin.format(context)}'),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final state = _presenceStates[student.id]!;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentHeader(student, state),
                if (!state.present) const SizedBox(height: 8),
                if (!state.present) _buildAbsenceFields(student, state),
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
        childAspectRatio: 3 / 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final state = _presenceStates[student.id]!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentHeader(student, state),
                const Spacer(),
                if (!state.present) _buildHeuresField(student, state),
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
        Expanded(
          child: Text(
            '${student.nom} ${student.prenom}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        ToggleButtons(
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
      ],
    );
  }

  Widget _buildAbsenceFields(Student student, _StudentPresenceState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeuresField(student, state),
        const SizedBox(height: 4),
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
      ],
    );
  }

  Widget _buildHeuresField(Student student, _StudentPresenceState state) {
    return TextField(
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
    );
  }
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
