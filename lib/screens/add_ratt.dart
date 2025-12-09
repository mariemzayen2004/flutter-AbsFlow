import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/group/group.dart';
import '../models/subject/subject.dart';
import '../services/group_services.dart';
import '../services/subjectService.dart';

// Modèle pour les événements pédagogiques
class PedagogicalEvent {
  final int id;
  final String title;
  final int groupId;
  final int subjectId;
  final String eventType;
  final DateTime date;
  final TimeOfDay time;
  final String description;
  final List<AttachedFile>? attachedFiles;
  final bool sendNotification;

  PedagogicalEvent({
    required this.id,
    required this.title,
    required this.groupId,
    required this.subjectId,
    required this.eventType,
    required this.date,
    required this.time,
    required this.description,
    this.attachedFiles,
    this.sendNotification = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'groupId': groupId,
      'subjectId': subjectId,
      'eventType': eventType,
      'date': date.toIso8601String(),
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'description': description,
      'attachedFiles': attachedFiles?.map((file) => file.toJson()).toList(),
      'sendNotification': sendNotification,
    };
  }
}

class AttachedFile {
  final String name;
  final String path;
  final String type;
  final int size;
  final List<int>? bytes;

  AttachedFile({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    this.bytes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'type': type,
      'size': size,
    };
  }
}

class AddRattPage extends StatefulWidget {
  const AddRattPage({Key? key}) : super(key: key);

  @override
  State<AddRattPage> createState() => _AddRattPageState();
}

class _AddRattPageState extends State<AddRattPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late GroupesService _groupesService;
  late SubjectService _subjectService;
  
  List<Group> _groups = [];
  List<Subject> _subjects = [];
  List<Subject> _filteredSubjects = [];
  
  Group? _selectedGroup;
  Subject? _selectedSubject;
  String _selectedEventType = 'Rattrapage';
  
  final List<String> _eventTypes = [
    'Cours normal',
    'Rattrapage',
    'Absence du professeur',
    'Autre',
  ];
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<AttachedFile> _attachedFiles = [];
  bool _sendNotification = true;
  bool _isLoading = false;

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
      final groupsBox = await Hive.openBox<Group>('groups');
      final subjectsBox = await Hive.openBox<Subject>('subjects');

      _groupesService = GroupesService(groupsBox);
      _subjectService = SubjectService(subjectsBox);

      await _groupesService.insertGroups();
      await _subjectService.insertSubjects();

      final groupes = await _groupesService.getGroupes();
      final subjects = _subjectService.getSubjects();

      setState(() {
        _groups = groupes;
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur d\'initialisation: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement des données');
    }
  }

  void _onGroupChanged(Group? group) {
    setState(() {
      _selectedGroup = group;
      _selectedSubject = null;
      
      if (group != null) {
        _filteredSubjects = _subjectService.getSubjectsByGroup(group.id);
      } else {
        _filteredSubjects = [];
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = 
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickPDFFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        final platformFile = result.files.single;
        
        setState(() {
          _attachedFiles.add(
            AttachedFile(
              name: platformFile.name,
              path: platformFile.path ?? '',
              type: 'pdf',
              size: platformFile.size,
              bytes: platformFile.bytes,
            ),
          );
        });
      }
    } catch (e) {
      print('Erreur PDF: $e');
      _showErrorSnackBar('Erreur lors de la sélection du fichier PDF');
    }
  }

  Future<void> _pickImageFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        final platformFile = result.files.single;
        
        setState(() {
          _attachedFiles.add(
            AttachedFile(
              name: platformFile.name,
              path: platformFile.path ?? '',
              type: 'image',
              size: platformFile.size,
              bytes: platformFile.bytes,
            ),
          );
        });
      }
    } catch (e) {
      print('Erreur Image: $e');
      _showErrorSnackBar('Erreur lors de la sélection de l\'image');
    }
  }

  Future<void> _pickDocumentFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx', 'ppt', 'pptx', 'txt'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        final platformFile = result.files.single;
        
        setState(() {
          _attachedFiles.add(
            AttachedFile(
              name: platformFile.name,
              path: platformFile.path ?? '',
              type: 'document',
              size: platformFile.size,
              bytes: platformFile.bytes,
            ),
          );
        });
      }
    } catch (e) {
      print('Erreur Document: $e');
      _showErrorSnackBar('Erreur lors de la sélection du document');
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Fichier PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPDFFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: const Text('Image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.green),
                title: const Text('Document (Word, PPT, etc.)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocumentFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.grey),
                title: const Text('Annuler'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'Cours normal':
        return Colors.blue;
      case 'Rattrapage':
        return Colors.orange;
      case 'Absence du professeur':
        return Colors.red;
      case 'Autre':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGroup == null) {
      _showErrorSnackBar('Veuillez sélectionner un groupe');
      return;
    }

    if (_selectedSubject == null) {
      _showErrorSnackBar('Veuillez sélectionner une matière');
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      _showErrorSnackBar('Veuillez sélectionner la date et l\'heure');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer l'événement
      final event = PedagogicalEvent(
        id: DateTime.now().millisecondsSinceEpoch,
        title: _titleController.text.trim(),
        groupId: _selectedGroup!.id,
        subjectId: _selectedSubject!.id,
        eventType: _selectedEventType,
        date: _selectedDate!,
        time: _selectedTime!,
        description: _descriptionController.text.trim(),
        attachedFiles: _attachedFiles.isNotEmpty ? _attachedFiles : null,
        sendNotification: _sendNotification,
      );

      // Sauvegarder dans Hive
      final eventsBox = await Hive.openBox('pedagogical_events');
      await eventsBox.add(event.toJson());
      
      print('✅ Événement sauvegardé : ${event.toJson()}');

      // Simuler l'envoi de notification
      if (_sendNotification) {
        _sendSimpleNotification(event);
      }

      _showSuccessSnackBar('$_selectedEventType planifié avec succès');
      
      // Retour à la page précédente
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'enregistrement: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sendSimpleNotification(PedagogicalEvent event) {
    print('📢 Notification: ${_selectedEventType}');
    print('   Titre: ${_titleController.text}');
    print('   Groupe: ${_selectedGroup!.filiere} - Niveau ${_selectedGroup!.niveau} - Groupe ${_selectedGroup!.numGroup}');
    print('   Matière: ${_selectedSubject!.nom}');
    print('   Enseignant: ${_selectedSubject!.enseignant}');
    print('   Date: ${_dateController.text} à ${_timeController.text}');
    print('   Description: ${event.description}');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Icon _getFileIcon(String type) {
    switch (type) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'image':
        return const Icon(Icons.image, color: Colors.blue);
      case 'document':
        return const Icon(Icons.description, color: Colors.green);
      default:
        return const Icon(Icons.attach_file, color: Colors.grey);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
        title: const Text('Planifier un événement pédagogique'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Type d\'événement'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _eventTypes.map((type) {
                        final isSelected = _selectedEventType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedEventType = type);
                            }
                          },
                          selectedColor: _getEventTypeColor(type).withOpacity(0.3),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: isSelected ? _getEventTypeColor(type) : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Informations de l\'événement'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre de l\'événement *',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le titre est obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Group>(
                      value: _selectedGroup,
                      decoration: const InputDecoration(
                        labelText: 'Groupe *',
                        prefixIcon: Icon(Icons.group),
                        border: OutlineInputBorder(),
                      ),
                      items: _groups.map((group) {
                        return DropdownMenuItem(
                          value: group,
                          child: Text('${group.filiere} - Niveau ${group.niveau} - Groupe ${group.numGroup}'),
                        );
                      }).toList(),
                      onChanged: _onGroupChanged,
                      validator: (value) => value == null ? 'Sélectionnez un groupe' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Subject>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Matière *',
                        prefixIcon: Icon(Icons.book),
                        border: OutlineInputBorder(),
                      ),
                      items: _filteredSubjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(subject.nom),
                              Text(
                                subject.enseignant,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedSubject = value),
                      validator: (value) => value == null ? 'Sélectionnez une matière' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Date *',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            onTap: _selectDate,
                            validator: (value) => value == null || value.isEmpty ? 'Sélectionnez une date' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _timeController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Heure *',
                              prefixIcon: Icon(Icons.access_time),
                              border: OutlineInputBorder(),
                            ),
                            onTap: _selectTime,
                            validator: (value) => value == null || value.isEmpty ? 'Sélectionnez une heure' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description / Contenu *',
                        hintText: 'Décrivez le contenu de la séance...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer une description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Pièces jointes (optionnel)'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _showAttachmentOptions,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.attach_file, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ajouter des fichiers',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_attachedFiles.isNotEmpty)
                            const Divider(height: 1),
                          ..._attachedFiles.asMap().entries.map((entry) {
                            final index = entry.key;
                            final file = entry.value;
                            return ListTile(
                              leading: _getFileIcon(file.type),
                              title: Text(
                                file.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(_formatFileSize(file.size)),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _removeFile(index),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Notification'),
                    SwitchListTile(
                      value: _sendNotification,
                      onChanged: (value) {
                        setState(() {
                          _sendNotification = value;
                        });
                      },
                      title: const Text('Envoyer une notification'),
                      subtitle: const Text('Notifier les étudiants du groupe'),
                      secondary: const Icon(Icons.notifications_active),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveEvent,
                        icon: const Icon(Icons.save),
                        label: Text('Planifier $_selectedEventType'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Annuler'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.orange,
      ),
    );
  }
}