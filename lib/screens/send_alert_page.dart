import 'package:abs_flow/main.dart';
import 'package:flutter/material.dart';
import '../models/alert/alert.dart';
import '../models/group/group.dart';
import '../models/student/student.dart';
import '../models/subject/subject.dart';
import '../services/alert_services.dart';
import '../services/hive_service.dart';
import '../services/setting_service.dart';
import '../services/student_service.dart';
import '../services/group_services.dart';
import '../services/subjectService.dart';

class SendAlertPage extends StatefulWidget {
  const SendAlertPage({super.key});

  @override
  _SendAlertPageState createState() => _SendAlertPageState();
}

class _SendAlertPageState extends State<SendAlertPage> {
  late AlertService _alertService;
  late StudentService _studentService;
  late SettingsService _settingsService;
  late GroupesService _groupesService;
  late SubjectService _subjectService;

  List<Student> _students = [];
  List<int> _selectedStudentsIds = [];
  AlertLevel _alertLevel = AlertLevel.avertissement;

  int? _selectedGroupId;
  int? _selectedSubjectId;

  List<Group> _groups = [];
  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();

    final hive = HiveService.instance;
    _studentService = StudentService(hive.studentsBox,attendanceService);
    _alertService = AlertService(hive.alertsBox, _studentService);
    _settingsService = SettingsService.instance;
    _groupesService = GroupesService(hive.groupsBox);
    _subjectService = SubjectService(hive.subjectsBox);

    _loadStudents();
    _loadGroupsAndSubjects();
  }

  Future<void> _loadStudents() async {
    final students = await _studentService.getStudents();
    final settings = _settingsService.getSettings();

    // Filtrer les étudiants qui dépassent les seuils d'avertissement ou d'élimination
    setState(() {
      _students = students.where((student) {
        final totalAbsence = student.totalHeuresAbsence; // Remplace par ta logique pour obtenir l'absence totale
        return totalAbsence >= settings.seuilAvertissement;
      }).toList();
    });
  }

  // Charger les groupes et matières depuis les box
  Future<void> _loadGroupsAndSubjects() async {
    final groups = await _groupesService.getGroupes();
    final subjects = await _subjectService.getSubjects();

    setState(() {
      _groups = groups;
      _subjects = subjects;
    });
  }

  // Envoi de l'alerte
  Future<void> _sendAlerts() async {
    if (_selectedStudentsIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner des étudiants.')),
      );
      return;
    }

    if (_selectedGroupId == null || _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un groupe et une matière.')),
      );
      return;
    }

    // Créer l'alerte pour chaque étudiant sélectionné
    for (var studentId in _selectedStudentsIds) {
      final student = _students.firstWhere((s) => s.id == studentId);

      int totalHeuresAbsence = student.totalHeuresAbsence; // Remplace cette logique par ton calcul

      final alerte = await _alertService.creerAlerte(
        studentId: student.id,
        totalHeuresAbsence: totalHeuresAbsence,
        niveau: _alertLevel,
        groupId: _selectedGroupId!,
        subjectId: _selectedSubjectId!,
      );

      // Simuler l'envoi de l'alerte par email
      await _alertService.envoyerAlerteEmail(alerte.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alerte envoyée à ${student.nom} ${student.prenom}'),
        ),
      );
    }
  }

  // Sélectionner un groupe
  Widget _buildGroupDropdown() {
    return DropdownButton<int>(
      value: _selectedGroupId,
      hint: const Text('Sélectionner un groupe'),
      onChanged: (value) {
        setState(() {
          _selectedGroupId = value;
        });
      },
      items: _groups.map((group) {
        return DropdownMenuItem<int>(
          value: group.id,
          child: Text('Groupe ${group.numGroup} - ${group.filiere}'),
        );
      }).toList(),
    );
  }

  // Sélectionner une matière
  Widget _buildSubjectDropdown() {
    return DropdownButton<int>(
      value: _selectedSubjectId,
      hint: const Text('Sélectionner une matière'),
      onChanged: (value) {
        setState(() {
          _selectedSubjectId = value;
        });
      },
      items: _subjects.map((subject) {
        return DropdownMenuItem<int>(
          value: subject.id,
          child: Text(subject.nom),
        );
      }).toList(),
    );
  }

  // Liste des étudiants avec case à cocher
  Widget _buildStudentList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];

          return CheckboxListTile(
            title: Text('${student.nom} ${student.prenom}'),
            value: _selectedStudentsIds.contains(student.id),
            onChanged: (bool? selected) {
              setState(() {
                if (selected!) {
                  _selectedStudentsIds.add(student.id);
                } else {
                  _selectedStudentsIds.remove(student.id);
                }
              });
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envoyer une alerte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildGroupDropdown(),
            const SizedBox(height: 16),
            _buildSubjectDropdown(),
            const SizedBox(height: 16),
            _buildStudentList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendAlerts,
              child: const Text('Envoyer les alertes'),
            ),
          ],
        ),
      ),
    );
  }
}
