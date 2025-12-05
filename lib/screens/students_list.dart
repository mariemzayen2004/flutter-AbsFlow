import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/student/student.dart';

class StudentsListPage extends StatefulWidget {
  const StudentsListPage({Key? key}) : super(key: key);

  @override
  State<StudentsListPage> createState() => _StudentsListPageState();
}

class _StudentsListPageState extends State<StudentsListPage> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedGroupId;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Student> _filterStudents(List<Student> students) {
    return students.where((student) {
      final matchesSearch = _searchQuery.isEmpty ||
          student.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.prenom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.matricule.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesGroup =
          _selectedGroupId == null || student.groupId == _selectedGroupId;

      return matchesSearch && matchesGroup && student.isActive;
    }).toList();
  }

  String _getStudentStatus(Student student) {
    if (student.tauxAbsence >= 30) return 'Échec';
    if (student.tauxAbsence >= 20) return 'Alerte';
    return 'Normal';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Échec':
        return Colors.red;
      case 'Alerte':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          tooltip: 'Retour à l\'accueil',
        ),
        title: const Text('Liste des Étudiants'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Student>('students').listenable(),
              builder: (context, Box<Student> box, _) {
                final allStudents = box.values.toList();
                final filteredStudents = _filterStudents(allStudents);

                if (filteredStudents.isEmpty) {
                  return const Center(
                    child: Text('Aucun étudiant trouvé'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    return StudentCard(student: filteredStudents[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher (nom, prénom, matricule)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Groupe: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tous'),
                        selected: _selectedGroupId == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedGroupId = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(3, (index) {
                        final groupId = index + 1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('Groupe $groupId'),
                            selected: _selectedGroupId == groupId,
                            onSelected: (selected) {
                              setState(() {
                                _selectedGroupId = selected ? groupId : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StudentCard extends StatelessWidget {
  final Student student;

  const StudentCard({Key? key, required this.student}) : super(key: key);

  String _getStudentStatus(Student student) {
    if (student.tauxAbsence >= 30) return 'Échec';
    if (student.tauxAbsence >= 20) return 'Alerte';
    return 'Normal';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Échec':
        return Colors.red;
      case 'Alerte':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStudentStatus(student);
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentProfilePage(student: student),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                      '${student.prenom} ${student.nom}',
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${student.tauxAbsence.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    '${student.totalHeuresAbsence}h',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentProfilePage extends StatelessWidget {
  final Student student;

  const StudentProfilePage({Key? key, required this.student}) : super(key: key);

  String _getStudentStatus(Student student) {
    if (student.tauxAbsence >= 30) return 'Échec';
    if (student.tauxAbsence >= 20) return 'Alerte';
    return 'Normal';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Échec':
        return Colors.red;
      case 'Alerte':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStudentStatus(student);
    final statusColor = _getStatusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Étudiant'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: student.photoPath != null
                        ? AssetImage(student.photoPath!)
                        : null,
                    child: student.photoPath == null
                        ? Text(
                            '${student.prenom[0]}${student.nom[0]}',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${student.prenom} ${student.nom}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations Personnelles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InfoRow(
                    icon: Icons.badge,
                    label: 'Matricule',
                    value: student.matricule,
                  ),
                  InfoRow(
                    icon: Icons.group,
                    label: 'Groupe',
                    value: 'Groupe ${student.groupId ?? "Non assigné"}',
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Statistiques d\'Absence',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.percent,
                          label: 'Taux d\'absence',
                          value: '${student.tauxAbsence.toStringAsFixed(1)}%',
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.access_time,
                          label: 'Heures manquées',
                          value: '${student.totalHeuresAbsence}h',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showJustifyAbsenceDialog(context);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Justifier une absence'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showAbsenceHistory(context);
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('Historique d\'absences'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nomController = TextEditingController(text: student.nom);
    final prenomController = TextEditingController(text: student.prenom);
    final matriculeController = TextEditingController(text: student.matricule);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier les données'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: prenomController,
                decoration: const InputDecoration(labelText: 'Prénom'),
              ),
              TextField(
                controller: matriculeController,
                decoration: const InputDecoration(labelText: 'Matricule'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              student.nom = nomController.text;
              student.prenom = prenomController.text;
              student.matricule = matriculeController.text;
              student.save();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Données modifiées avec succès')),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showJustifyAbsenceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Justifier une absence'),
        content: const Text(
          'Fonctionnalité de justification d\'absence.\nVous pouvez implémenter ici la logique pour réduire les heures d\'absence.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAbsenceHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historique d\'absences'),
        content: const Text(
          'Historique des absences de l\'étudiant.\nVous pouvez afficher ici la liste détaillée des absences par date et matière.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}