import 'package:abs_flow/main.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';  // AJOUTÉ pour ValueListenableBuilder
import '../models/attendance/attendance.dart';
import '../models/student/student.dart';
import '../models/group/group.dart';
import '../models/settings/settings.dart';  // AJOUTÉ pour SettingsModel
import '../services/student_service.dart';
import '../services/group_services.dart';
import '../services/attendance_service.dart';
import '../services/setting_service.dart';
import 'student_profile.dart';

class StudentsListPage extends StatefulWidget {
  const StudentsListPage({Key? key}) : super(key: key);

  @override
  _StudentsListPageState createState() => _StudentsListPageState();
}

class _StudentsListPageState extends State<StudentsListPage> {
  late StudentService _studentService;
  late GroupesService _groupesService;
  late AttendanceService _attendanceService;
  late SettingsService _settingsService;
  bool _isInitialized = false;

  List<Group> _groupes = [];
  List<Student> _students = [];
  int? _selectedGroupId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final studentBox = await Hive.openBox<Student>('students');
    final groupBox = await Hive.openBox<Group>('groups');
    final attendanceBox = await Hive.openBox<Attendance>('attendances');

    _studentService = StudentService(studentBox, attendanceService);
    _groupesService = GroupesService(groupBox);
    _attendanceService = AttendanceService(attendanceBox);
    _settingsService = SettingsService.instance;

    await studentService.initStudentsIfEmpty();  
    await _groupesService.insertGroups();

    final groupes = await _groupesService.getGroupes();
    final students = _studentService.getStudents();

    setState(() {
      _groupes = groupes;
      _students = students;
      _isInitialized = true;
    });
  }

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

      final matchesGroup = _selectedGroupId == null || student.groupId == _selectedGroupId;

      return matchesSearch && matchesGroup && student.isActive;
    }).toList();
  }

  String _getGroupDisplayName(int groupId) {
    final groupe = _groupes.firstWhere(
      (g) => g.id == groupId,
      orElse: () => Group(id: 0, numGroup: 0, filiere: 'Inconnu', niveau: 0),
    );

    if (groupe.id == 0) return 'Groupe $groupId';
    return 'G${groupe.numGroup} - ${groupe.filiere} ${groupe.niveau}A';
  }

  Color _getStatusColor(Student student) {
    if (student.tauxAbsence >= 30) return Colors.red.shade600;
    if (student.tauxAbsence >= 20) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  IconData _getStatusIcon(Student student) {
    if (student.tauxAbsence >= 30) return Icons.error;
    if (student.tauxAbsence >= 20) return Icons.warning;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
              const SizedBox(height: 16),
              Text(
                'Chargement des étudiants...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredStudents = _filterStudents(_students);

    // ============= MODIFIÉ: Ajout du ValueListenableBuilder =============
    return ValueListenableBuilder(
      valueListenable: Hive.box<SettingsModel>('settings').listenable(),
      builder: (context, Box<SettingsModel> box, _) {
        final settings = _settingsService.getSettings();
        final isDarkMode = settings.isDarkMode;

        return Scaffold(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'Liste des Étudiants',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode 
                      ? [Colors.grey[850]!, Colors.grey[800]!]
                      : [Colors.blue.shade700, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredStudents.length} étudiants',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSearchAndFilterSection(isDarkMode),  // MODIFIÉ: ajout isDarkMode
              Expanded(
                child: filteredStudents.isEmpty
                    ? _buildEmptyState(isDarkMode)  // MODIFIÉ: ajout isDarkMode
                    : _buildStudentListView(filteredStudents, isDarkMode),  // MODIFIÉ: ajout isDarkMode
              ),
            ],
          ),
        );
      },
    );
    // ================================================================
  }

  // ============= MODIFIÉ: ajout paramètre isDarkMode =============
  Widget _buildSearchAndFilterSection(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
              ? [Colors.grey[850]!, Colors.grey[900]!]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de recherche moderne
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode ? Colors.black26 : Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher un étudiant...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[500] : Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded, 
                    color: isDarkMode ? Colors.blue[300] : Colors.blue.shade500, 
                    size: 24,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear, 
                            color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Filtres de groupe
            Row(
              children: [
                Icon(
                  Icons.filter_list_rounded, 
                  color: isDarkMode ? Colors.grey[400] : Colors.grey.shade700, 
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filtrer par groupe',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Tous',
                    isSelected: _selectedGroupId == null,
                    count: _students.where((s) => s.isActive).length,
                    onTap: () {
                      setState(() {
                        _selectedGroupId = null;
                      });
                    },
                    isDarkMode: isDarkMode,  // AJOUTÉ
                  ),
                  const SizedBox(width: 10),
                  ..._groupes.map((groupe) {
                    final count = _students
                        .where((s) => s.groupId == groupe.id && s.isActive)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildFilterChip(
                        label: 'G${groupe.numGroup} ${groupe.filiere}',
                        isSelected: _selectedGroupId == groupe.id,
                        count: count,
                        onTap: () {
                          setState(() {
                            _selectedGroupId = groupe.id;
                          });
                        },
                        isDarkMode: isDarkMode,  // AJOUTÉ
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============= MODIFIÉ: ajout paramètre isDarkMode =============
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required int count,
    required VoidCallback onTap,
    required bool isDarkMode,  // AJOUTÉ
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: isDarkMode
                      ? [Colors.blue[700]!, Colors.blue[600]!]
                      : [Colors.blue.shade700, Colors.blue.shade500],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected 
              ? null 
              : (isDarkMode ? Colors.grey[800] : Colors.white),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent 
                : (isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDarkMode ? Colors.blue[700]! : Colors.blue.shade500)
                        .withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : (isDarkMode ? Colors.grey[300] : Colors.grey.shade700),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : (isDarkMode ? Colors.grey[700] : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : (isDarkMode ? Colors.grey[300] : Colors.grey.shade700),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============= MODIFIÉ: ajout paramètre isDarkMode =============
  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: isDarkMode ? Colors.grey[600] : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun étudiant trouvé',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey[300] : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[500] : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ============= MODIFIÉ: ajout paramètre isDarkMode =============
  Widget _buildStudentListView(List<Student> students, bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final statusColor = _getStatusColor(student);
        final statusIcon = _getStatusIcon(student);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? Colors.black26 : Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentProfilePage(
                      student: student,
                      groupDisplayName: _getGroupDisplayName(student.groupId!),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? [Colors.blue[700]!, Colors.blue[500]!]
                              : [Colors.blue.shade700, Colors.blue.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isDarkMode 
                                ? Colors.blue[700]! 
                                : Colors.blue.shade500).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: student.photoPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                student.photoPath!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                '${student.prenom[0]}${student.nom[0]}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Informations de l'étudiant
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${student.prenom} ${student.nom}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 14,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                student.matricule,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.groups_outlined,
                                size: 14,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getGroupDisplayName(student.groupId!),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Badge de statut
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            statusIcon,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
