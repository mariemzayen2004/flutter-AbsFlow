import 'package:abs_flow/main.dart';
import 'package:abs_flow/models/session/session.dart';
import 'package:abs_flow/models/subject/subject.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/attendance/attendance.dart';
import '../models/student/student.dart';
import '../services/session_service.dart';
import '../services/student_service.dart';
import '../services/attendance_service.dart';
import '../services/subjectService.dart';

class StudentProfilePage extends StatefulWidget {
  final Student student;
  final String groupDisplayName;

  const StudentProfilePage({
    Key? key,
    required this.student,
    required this.groupDisplayName,
  }) : super(key: key);

  @override
  _StudentProfilePageState createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  late StudentService _studentService;
  late AttendanceService _attendanceService;
  late SessionService _sessionService;
  late SubjectService _subjectService;


  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final studentBox = await Hive.openBox<Student>('students');
    final attendanceBox = await Hive.openBox<Attendance>('attendances');
    final sessionBox = await Hive.openBox<Session>('sessions');
    final subjectBox = await Hive.openBox<Subject>('subjects');

    _studentService = StudentService(studentBox, attendanceService);
    _attendanceService = AttendanceService(attendanceBox);
    _sessionService = SessionService(sessionBox);
    _subjectService = SubjectService(subjectBox);

    await _studentService.updateTotalHeuresAbsence(widget.student.id);
  }

  String _getStudentStatus(Student student) {
    return student.isActive ? 'Actif' : 'Inactif';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Actif':
        return Colors.green.shade600;
      case 'Inactif':
        return Colors.red.shade600; // ou Colors.grey.shade600 si tu préfères
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Actif':
        return Icons.check_circle;
      case 'Inactif':
        return Icons.block; // ou Icons.pause_circle_filled
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Student student = widget.student;
    final status = _getStudentStatus(widget.student);
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Profil Étudiant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
              child: Column(
                children: [
                  // En-tête avec photo et statut
                  _buildHeader(status, statusColor),
                  
                  // Contenu principal
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informations personnelles
                        _buildSectionTitle('Informations Personnelles', Icons.person),
                        const SizedBox(height: 16),
                        _buildInfoCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Actions rapides
                        _buildSectionTitle('Actions Rapides', Icons.flash_on),
                        const SizedBox(height: 16),
                        _buildActionButtons(context,student),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(String status, Color statusColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade300.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
          child: Column(
            children: [
              // Photo de profil avec bordure animée
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: widget.student.photoPath != null
                        ? AssetImage(widget.student.photoPath!)
                        : null,
                    child: widget.student.photoPath == null
                        ? Text(
                            '${widget.student.prenom[0]}${widget.student.nom[0]}',
                            style: TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Nom de l'étudiant
              Text(
                '${widget.student.prenom} ${widget.student.nom}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Badge de statut amélioré
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(status), color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            InfoRow(
              icon: Icons.badge_outlined,
              label: 'Matricule',
              value: widget.student.matricule,
            ),
            const Divider(height: 24),
            InfoRow(
              icon: Icons.groups_outlined,
              label: 'Groupe',
              value: widget.groupDisplayName,
            ),
            const Divider(height: 24),
            InfoRow(
              icon: Icons.access_time_rounded,
              label: 'Heures manquées',
              value: '${widget.student.totalHeuresAbsence}h',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context,Student student) {
    return Column(
      children: [
        // Bouton Historique
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showAbsenceHistory(context, student.id),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, color: Colors.blue.shade600, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Historique d\'absences',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showJustifyAbsenceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Justifier une absence',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Fonctionnalité de justification d\'absence.\nVous pouvez implémenter ici la logique pour réduire les heures d\'absence.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbsenceHistory(BuildContext context, int studentId) async {

  final Student student = widget.student;

  final attendances = _attendanceService.getAttendanceByStudent(studentId);

  // Filtrer les absences 
  final absences = attendances.where((attendance) => !attendance.present).toList();

  // Récupérer les informations des séances et matières (asynchrone)
  List<Widget> absenceWidgets = [];
  for (var attendance in absences) {
    // Attendre la récupération de la séance
    final session = await _sessionService.getSessionById(attendance.sessionId);

    // Vérifier si la session est récupérée
    if (session != null) {
      // Récupérer la matière associée à la séance
      final subject = await _subjectService.getSubjectById(session.subjectId);

      // Récupérer la date de la séance
      final formattedDate = session.date != null
          ? "${session.date.day}/${session.date.month}/${session.date.year}"
          : 'Date inconnue';

      absenceWidgets.add(
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: Colors.red.shade100,
            child: Icon(
              Icons.close,
              color: Colors.red.shade700,
            ),
          ),
          title: Text(
            'Séance du $formattedDate', // Afficher la date de la séance
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Matière: ${subject?.nom ?? 'Inconnue'}', // Afficher le nom de la matière
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Absent',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Afficher le dialogue avec les absences
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
              child: Icon(Icons.history, color: Colors.blue.shade700, size: 48),
            ),
            const SizedBox(width: 12),
            Text('Absences de ${student.prenom}', style: TextStyle(fontSize: 20)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: absenceWidgets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune absence enregistrée',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: absenceWidgets.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return absenceWidgets[index];
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
}

}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue.shade700, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Gradient gradient;

  const StatCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}