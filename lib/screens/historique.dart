import 'package:abs_flow/main.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/hive_service.dart';
import '../services/session_service.dart';
import '../services/attendance_service.dart';
import '../services/student_service.dart';
import '../services/group_services.dart';
import '../models/session/session.dart';
import '../models/attendance/attendance.dart';
import '../models/group/group.dart';
import '../models/subject/subject.dart';
import '../services/subjectService.dart';

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  _HistoriquePageState createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  // Services
  late SessionService _sessionService;
  late AttendanceService _attendanceService;
  late StudentService _studentService;
  late GroupesService _groupesService;
  late SubjectService _subjectService;

  // Variables d'état
  List<Session> _sessions = [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    final hive = HiveService.instance;
    _sessionService = SessionService(hive.sessionsBox);
    _attendanceService = AttendanceService(hive.attendancesBox);
    _studentService = StudentService(hive.studentsBox,attendanceService);
    _groupesService = GroupesService(hive.groupsBox);
    _subjectService = SubjectService(hive.subjectsBox);

    _loadSessions();
  }

  // Charger toutes les séances
  Future<void> _loadSessions() async {
    try {
      final box = await Hive.openBox<Session>('sessions');
      final sessions = box.values.toList();

      // Trier les séances par date (de la plus récente à la plus ancienne)
      sessions.sort((a, b) => b.date.compareTo(a.date)); // tri décroissant

      print('Nombre de séances dans la box : ${sessions.length}');

      setState(() {
        _sessions = sessions;
      });
    } catch (e) {
      print('Erreur de chargement des séances: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement des séances'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // Filtrer les séances selon la date
  Future<void> _filterSessions() async {
    final sessions = await _sessionService.filterSessions(
      date: _selectedDate,
    );
    setState(() {
      _sessions = sessions;
    });
  }

  // Supprimer une séance
  Future<void> _deleteSession(Session session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            const Text('Confirmer la suppression'),
          ],
        ),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette séance ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _sessionService.supprimerSession(session.id);
      setState(() {
        _sessions.remove(session);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Séance supprimée avec succès'),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // Afficher le dialogue de filtrage
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.filter_list, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              const Text('Filtrer les séances', style: TextStyle(fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterTile(
                icon: Icons.calendar_today,
                title: 'Sélectionner une date',
                subtitle: _selectedDate?.toLocal().toString().split(' ')[0] ?? 'Aucune date',
                color: Colors.purple,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
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
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                  Navigator.pop(context);
                  _filterSessions();
                },
              ),
            ],
          ),
          actions: [
            if (_selectedDate != null )
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                  });
                  Navigator.pop(context);
                  _loadSessions();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Réinitialiser'),
                style: TextButton.styleFrom(foregroundColor: Colors.orange.shade700),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  // Méthode asynchrone pour mettre à jour l'état d'une présence
  Future<void> _updateAttendanceStatus(Attendance attendance) async {
    try {
      // Appel au service pour modifier l'attendance
      await _attendanceService.modifierAttendance(
        attendance.id,
        attendance.present,
        attendance.heuresManquees,
        attendance.remarque,
        attendance.justifie,
      );

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Présence modifiée avec succès'),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      // En cas d'erreur lors de la mise à jour
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour de la présence'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildFilterTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // Afficher les présences des étudiants dans une séance
  void _showAttendanceDialog(List<Attendance> attendanceList) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.how_to_reg, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  const Text('Modifier les présences', style: TextStyle(fontSize: 20)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: attendanceList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune présence enregistrée',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: attendanceList.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final attendance = attendanceList[index];
                          final student = _studentService.getStudentById(attendance.studentId);  // Récupérer l'étudiant
                          final studentName = student != null ? '${student.prenom} ${student.nom}' : 'Étudiant inconnu';  // Nom et prénom de l'étudiant

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: attendance.present
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              child: Icon(
                                attendance.present ? Icons.check : Icons.close,
                                color: attendance.present
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                            title: Text(
                              studentName,  // Afficher le nom et prénom de l'étudiant
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              attendance.present ? 'Présent' : 'Absent',
                              style: TextStyle(
                                color: attendance.present
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.edit, color: Colors.blue.shade700, size: 20),
                              ),
                              onPressed: () => _openEditDialog(attendance, setDialogState),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Pour ouvrir le dialogue de modification de présence
  void _openEditDialog(Attendance attendance, Function setDialogState) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit_note, color: Colors.orange.shade700),
                  ),
                  const SizedBox(width: 12),
                  const Text('Modifier la présence', style: TextStyle(fontSize: 20)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ToggleButtons(
                      isSelected: [attendance.present, !attendance.present],
                      onPressed: (index) async {
                        setState(() {
                          // Met à jour l'état du bouton dans le dialogue
                          attendance.present = index == 0;
                          if (attendance.present) {
                            attendance.heuresManquees = 0;
                            attendance.remarque = '';
                          }
                        });

                        // Sauvegarde de l'état de l'attendance dans la base de données
                        attendance.save();
                      },
                      borderRadius: BorderRadius.circular(12),
                      selectedColor: Colors.white,
                      fillColor: attendance.present ? Colors.green.shade500 : Colors.red.shade500,
                      color: Colors.grey.shade700,
                      constraints: const BoxConstraints(minHeight: 48, minWidth: 100),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text('Présent', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: const [
                              Icon(Icons.cancel_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Absent', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _attendanceService.modifierAttendance(
                      attendance.id,
                      attendance.present,
                      attendance.heuresManquees,
                      attendance.remarque,
                      attendance.justifie,
                    );
                    setDialogState(() {}); // Rafraîchir l'interface du dialogue après modification
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Historique des Séances',
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
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.filter_list),
              ),
              onPressed: () => _showFilterDialog(),
            ),
          ),
        ],
      ),
      body:_sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune séance trouvée',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Les séances apparaîtront ici',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final attendanceList =
                        _attendanceService.getAttendanceBySession(session.id);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showAttendanceDialog(attendanceList),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.event_note,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Séance ${session.date}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.people,
                                            size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${attendanceList.length} étudiants',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Afficher la matière et le groupe
                                    const SizedBox(height: 4),
                                    FutureBuilder<Subject?>(
                                      future: _subjectService.getSubjectsById(session.subjectId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        }
                                        if (!snapshot.hasData) {
                                          return const Text('Matière non trouvée');
                                        }
                                        final subject = snapshot.data!;
                                        return Row(
                                          children: [
                                            Icon(Icons.book, size: 14, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Matière: ${subject.nom}',  // Affiche le nom de la matière
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    FutureBuilder<Group?>(
                                      future: _groupesService.getGroupeById(session.groupId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        }
                                        if (!snapshot.hasData) {
                                          return const Text('Groupe non trouvé');
                                        }
                                        final group = snapshot.data!;
                                        return Row(
                                          children: [
                                            Icon(Icons.group, size: 14, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Groupe ${group.numGroup} : ${group.filiere} ${group.niveau} ',  // Affichage du nom du groupe
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.delete_outline,
                                      color: Colors.red.shade700, size: 20),
                                ),
                                onPressed: () => _deleteSession(session),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
