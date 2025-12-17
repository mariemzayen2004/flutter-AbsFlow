import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';  // AJOUTÉ pour ValueListenableBuilder

import '../models/student/student.dart';
import '../models/subject/subject.dart';
import '../models/alert/alert.dart';
import '../models/session/session.dart';
import '../models/settings/settings.dart';  // AJOUTÉ pour SettingsModel

import '../services/hive_service.dart';
import '../services/attendance_service.dart';
import '../services/session_service.dart';
import '../services/subjectService.dart';
import '../services/student_service.dart';
import '../services/alert_services.dart';
import '../services/setting_service.dart';

class SendAlertPage extends StatefulWidget {
  const SendAlertPage({Key? key}) : super(key: key);

  @override
  State<SendAlertPage> createState() => _SendAlertPageState();
}

class _SendAlertPageState extends State<SendAlertPage> {
  late AttendanceService _attendanceService;
  late SessionService _sessionService;
  late SubjectService _subjectService;
  late StudentService _studentService;
  late AlertService _alertService;
  late SettingsService _settingsService;

  List<Subject> _subjects = [];
  Subject? _selectedSubject;

  int? _seuilAlerte;
  int? _seuilElimination;
  bool _seuilsFromGlobal = false;

  bool _isLoading = false;
  bool _isComputing = false;

  List<_AlertCandidate> _candidates = [];

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  void _initServices() {
    final hive = HiveService.instance;

    _attendanceService = AttendanceService(hive.attendancesBox);
    // ⚠️ Adapter la signature au StudentService actuel :
    // si ton StudentService a un constructeur (Box<Student> box, AttendanceService attendanceService)
    _studentService = StudentService(hive.studentsBox, _attendanceService);
    // sinon, si c'est encore StudentService(Box<Student> box), remplace par :
    // _studentService = StudentService(hive.studentsBox);

    _sessionService = SessionService(hive.sessionsBox);
    _subjectService = SubjectService(hive.subjectsBox);
    _alertService = AlertService(hive.alertsBox, _studentService);
    _settingsService = SettingsService.instance;

    // Charger toutes les matières
    setState(() {
      _subjects = _subjectService.getSubjects();
    });
  }

  Future<void> _onSubjectSelected(Subject? subject) async {
    setState(() {
      _selectedSubject = subject;
      _candidates.clear();
      _seuilAlerte = null;
      _seuilElimination = null;
      _seuilsFromGlobal = false;
    });

    if (subject == null) return;

    await _loadThresholdsAndCandidates();
  }

  Future<void> _loadThresholdsAndCandidates() async {
    if (_selectedSubject == null) return;

    setState(() {
      _isLoading = true;
      _isComputing = true;
    });

    try {
      // 1️⃣ Récupérer les seuils pour cette matière
      final seuilMap = await _settingsService
          .getSeuilsParMatiere(_selectedSubject!.id.toString());

      final globalSettings = _settingsService.getSettings();

      final seuilAlerte =
          seuilMap?['seuilAlerte'] ?? globalSettings.seuilAvertissement;
      final seuilElimination =
          seuilMap?['seuilElimination'] ?? globalSettings.seuilElimination;
      final fromGlobal = seuilMap?['isGlobal'] == true;

      setState(() {
        _seuilAlerte = seuilAlerte;
        _seuilElimination = seuilElimination;
        _seuilsFromGlobal = fromGlobal;
      });

      // 2️⃣ Récupérer tous les étudiants (tu peux filtrer par groupe si tu veux)
      final allStudents = _studentService.getStudents();

      final List<_AlertCandidate> candidates = [];

      // 3️⃣ Pour chaque étudiant, calculer heures d'absence dans cette matière
      for (final student in allStudents) {
        final attendances =
            _attendanceService.getAttendanceByStudent(student.id);

        int totalHeuresForSubject = 0;

        for (final a in attendances) {
          if (a.present) continue; // On ne compte que les absences

          final Session? session =
              await _sessionService.getSessionById(a.sessionId);
          if (session == null) continue;

          if (session.subjectId == _selectedSubject!.id) {
            totalHeuresForSubject += a.heuresManquees;
          }
        }

        // 4️⃣ Appliquer les seuils (ici >=, c'est plus logique qu'"égal" strict)
        if (totalHeuresForSubject >= seuilAlerte) {
          final niveau = totalHeuresForSubject >= seuilElimination
              ? AlertLevel.elimination
              : AlertLevel.avertissement;

          candidates.add(
            _AlertCandidate(
              student: student,
              totalHeuresAbsence: totalHeuresForSubject,
              niveau: niveau,
            ),
          );
        }
      }

      setState(() {
        _candidates = candidates;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du calcul des alertes : $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isComputing = false;
      });
    }
  }

  Future<void> _envoyerAlertesSelectionnees() async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une matière.')),
      );
      return;
    }

    final selectionnes =
        _candidates.where((c) => c.selected == true).toList();

    if (selectionnes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner au moins un étudiant.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      for (final cand in selectionnes) {
        final alerte = await _alertService.creerAlerte(
          studentId: cand.student.id,
          totalHeuresAbsence: cand.totalHeuresAbsence,
          niveau: cand.niveau,
          groupId: cand.student.groupId ?? 0, // groupId dans ton modèle Student
          subjectId: _selectedSubject!.id,
        );

        // Simuler l'envoi par email
        await _alertService.envoyerAlerteEmail(alerte.id);
      }

      // Message de confirmation
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Alertes envoyées'),
          content: Text(
            'Les alertes ont été envoyées par email à ${selectionnes.length} étudiant(s).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );

      // On peut décocher tout après envoi
      setState(() {
        for (final c in _candidates) {
          c.selected = false;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi des alertes : $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ───────────────────────────────────────── UI ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ============= MODIFIÉ: Ajout du ValueListenableBuilder =============
    return ValueListenableBuilder(
      valueListenable: Hive.box<SettingsModel>('settings').listenable(),
      builder: (context, Box<SettingsModel> box, _) {
        final settings = _settingsService.getSettings();
        final isDarkMode = settings.isDarkMode;

        return Scaffold(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          appBar: AppBar(
            title: const Text('Envoyer des alertes'),
            backgroundColor: isDarkMode ? Colors.grey[850] : Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            children: [
              _buildSubjectSelector(isDarkMode),
              _buildThresholdInfo(isDarkMode),
              Expanded(child: _buildCandidatesList(isDarkMode)),
              _buildSendButton(isDarkMode),
            ],
          ),
        );
      },
    );
    // ================================================================
  }

  // ============= MODIFIÉ: ajout paramètre isDarkMode =============
  Widget _buildSubjectSelector(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDarkMode ? Colors.grey[850] : Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionnez une matière',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Subject>(
            value: _selectedSubject,
            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.book,
                color: isDarkMode ? Colors.blue[300] : Colors.blue,
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
            ),
            items: _subjects
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s.nom,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (s) => _onSubjectSelected(s),
          ),
        ],
      ),
    );
  }

  // ============= MODIFIÉ: ajout paramètre isDarkMode =============
  Widget _buildThresholdInfo(bool isDarkMode) {
    if (_selectedSubject == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDarkMode ? Colors.grey[850] : Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(
                    'Seuil avertissement : ${_seuilAlerte ?? '-'}h',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.black87 : Colors.black87,
                    ),
                  ),
                  backgroundColor: Colors.orange.shade100,
                ),
                Chip(
                  label: Text(
                    'Seuil élimination : ${_seuilElimination ?? '-'}h',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.black87 : Colors.black87,
                    ),
                  ),
                  backgroundColor: Colors.red.shade100,
                ),
                if (_seuilsFromGlobal)
                  Chip(
                    label: Text(
                      'Seuils globaux',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.black87 : Colors.black87,
                      ),
                    ),
                    backgroundColor: Colors.blue.shade50,
                  )
                else
                  Chip(
                    label: Text(
                      'Seuils spécifiques à la matière',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.black87 : Colors.black87,
                      ),
                    ),
                    backgroundColor: Colors.green.shade50,
                  ),
              ],
            ),
          ),
          if (_isComputing)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.blue[300]! : Colors.blue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============= MODIFIÉ: ajout paramètre isDarkMode =============
  Widget _buildCandidatesList(bool isDarkMode) {
    if (_selectedSubject == null) {
      return Center(
        child: Text(
          'Choisissez une matière pour voir les étudiants.',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.black87,
          ),
        ),
      );
    }

    if (_isLoading && _candidates.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDarkMode ? Colors.blue[300]! : Colors.blue,
          ),
        ),
      );
    }

    if (_candidates.isEmpty) {
      return Center(
        child: Text(
          'Aucun étudiant ne dépasse les seuils pour cette matière.',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.black87,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _candidates.length,
      itemBuilder: (context, index) {
        final cand = _candidates[index];
        final color =
            cand.niveau == AlertLevel.elimination ? Colors.red : Colors.orange;
        final niveauLabel =
            cand.niveau == AlertLevel.elimination ? 'Élimination' : 'Avertissement';

        return Card(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          elevation: isDarkMode ? 4 : 1,
          child: CheckboxListTile(
            value: cand.selected,
            onChanged: (v) {
              setState(() {
                cand.selected = v ?? false;
              });
            },
            activeColor: isDarkMode ? Colors.blue[400] : Colors.blue,
            checkColor: Colors.white,
            title: Text(
              '${cand.student.prenom} ${cand.student.nom}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Matricule : ${cand.student.matricule}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.black87,
                  ),
                ),
                Text(
                  'Heures d\'absence dans "${_selectedSubject!.nom}" : ${cand.totalHeuresAbsence}h',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    niveauLabel,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============= MODIFIÉ: ajout paramètre isDarkMode =============
  Widget _buildSendButton(bool isDarkMode) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: Text(
              _isLoading ? 'Envoi en cours...' : 'Envoyer les alertes sélectionnées',
            ),
            onPressed: _isLoading ? null : _envoyerAlertesSelectionnees,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.blue[700] : Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Petit modèle interne pour l'écran
class _AlertCandidate {
  final Student student;
  final int totalHeuresAbsence;
  final AlertLevel niveau;
  bool selected;

  _AlertCandidate({
    required this.student,
    required this.totalHeuresAbsence,
    required this.niveau,
    this.selected = false,
  });
}