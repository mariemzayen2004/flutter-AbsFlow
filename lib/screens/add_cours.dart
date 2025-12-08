import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// 🔹 Ajout des imports nécessaires
import 'package:hive_flutter/hive_flutter.dart';
import '../models/group/group.dart';
import '../models/subject/subject.dart';
import '../services/group_services.dart';
import '../services/subjectService.dart';

class AddCoursPage extends StatefulWidget {
  const AddCoursPage({Key? key}) : super(key: key);

  @override
  State<AddCoursPage> createState() => _AddCoursPageState();
}

class _AddCoursPageState extends State<AddCoursPage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // 🔹 Changement: utiliser Subject au lieu de String
  Subject? _selectedMatiere;
  List<int> _selectedGroupes = [];
  List<AttachedFile> _attachedFiles = [];
  bool _sendNotification = true;
  bool _isLoading = false;

  // 🔹 Ajout des services
  late GroupesService _groupesService;
  late SubjectService _subjectService;
  
  // 🔹 Ajout des listes chargées depuis Hive
  List<Subject> _matieres = [];
  List<Group> _groupes = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  // 🔹 Initialisation des services et chargement des données
  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les boxes Hive
      final groupsBox = await Hive.openBox<Group>('groups');
      final subjectsBox = await Hive.openBox<Subject>('subjects');

      // Initialiser les services
      _groupesService = GroupesService(groupsBox);
      _subjectService = SubjectService(subjectsBox);

      // Insérer les données initiales si nécessaire
      await _groupesService.insertGroups();
      await _subjectService.insertSubjects();

      // Charger les données
      final groupes = await _groupesService.getGroupes();
      final matieres = _subjectService.getSubjects();

      setState(() {
        _groupes = groupes;
        _matieres = matieres;
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

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
              type: FileType.custom,
              size: platformFile.size,
              bytes: platformFile.bytes,
            ),
          );
        });
      }
    } catch (e) {
      print('Erreur PDF: $e');
      _showErrorSnackBar('Erreur lors de la sélection du fichier PDF: ${e.toString()}');
    }
  }

  Future<void> _pickImageFromGallery() async {
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
              type: FileType.image,
              size: platformFile.size,
              bytes: platformFile.bytes,
            ),
          );
        });
      }
    } catch (e) {
      print('Erreur Image: $e');
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: ${e.toString()}');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        
        setState(() {
          _attachedFiles.add(
            AttachedFile(
              name: image.name,
              path: image.path,
              type: FileType.image,
              size: fileSize,
            ),
          );
        });
      }
    } catch (e) {
      print('Erreur Caméra: $e');
      _showErrorSnackBar('Erreur lors de la prise de photo');
    }
  }

  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
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
              type: FileType.video,
              size: platformFile.size,
              bytes: platformFile.bytes,
            ),
          );
        });
      }
    } catch (e) {
      print('Erreur Vidéo: $e');
      _showErrorSnackBar('Erreur lors de la sélection de la vidéo: ${e.toString()}');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
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
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Image de la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.purple),
                title: const Text('Vidéo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMatiere == null) {
      _showErrorSnackBar('Veuillez sélectionner une matière');
      return;
    }

    if (_selectedGroupes.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner au moins un groupe');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simuler un délai de sauvegarde
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Implémenter la logique de sauvegarde dans Hive
    // - Créer un modèle Course/Resource
    // - Sauvegarder les données
    // - Envoyer les notifications si nécessaire
    
    // 🔹 Affichage des informations sélectionnées pour debug
    print('Titre: ${_titreController.text}');
    print('Matière: ${_selectedMatiere!.nom} (ID: ${_selectedMatiere!.id})');
    print('Enseignant: ${_selectedMatiere!.enseignant}');
    print('Groupes sélectionnés: $_selectedGroupes');
    print('Description: ${_descriptionController.text}');
    print('Fichiers attachés: ${_attachedFiles.length}');
    print('Notification: $_sendNotification');

    setState(() {
      _isLoading = false;
    });

    _showSuccessSnackBar('Ressource ajoutée avec succès!');
    
    if (_sendNotification) {
      _showSuccessSnackBar('Notification envoyée aux étudiants concernés');
    }

    // Retour à la page précédente
    Navigator.pop(context);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
        title: const Text('Ajouter une Ressource'),
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
                    _buildSectionTitle('Informations générales'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titreController,
                      decoration: const InputDecoration(
                        labelText: 'Titre de la ressource *',
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
                    // 🔹 Modification: Dropdown avec Subject au lieu de String
                    DropdownButtonFormField<Subject>(
                      value: _selectedMatiere,
                      decoration: const InputDecoration(
                        labelText: 'Matière *',
                        prefixIcon: Icon(Icons.book),
                        border: OutlineInputBorder(),
                      ),
                      items: _matieres.map((matiere) {
                        return DropdownMenuItem(
                          value: matiere,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                matiere.nom,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                matiere.enseignant,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMatiere = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Groupes concernés'),
                    const SizedBox(height: 12),
                    // 🔹 Modification: FilterChips avec Group objects
                    Wrap(
                      spacing: 8,
                      children: _groupes.map((groupe) {
                        final isSelected = _selectedGroupes.contains(groupe.id);
                        return FilterChip(
                          label: Text(
                            'G${groupe.numGroup} - ${groupe.filiere} ${groupe.niveau}A',
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedGroupes.add(groupe.id);
                              } else {
                                _selectedGroupes.remove(groupe.id);
                              }
                            });
                          },
                          selectedColor: Colors.blue.withOpacity(0.3),
                          checkmarkColor: Colors.blue,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Pièces jointes'),
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
                      subtitle: const Text(
                        'Notifier les étudiants concernés',
                      ),
                      secondary: const Icon(Icons.notifications_active),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: const Icon(Icons.save),
                        label: const Text('Enregistrer la ressource'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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
        color: Colors.blue,
      ),
    );
  }

  Icon _getFileIcon(FileType type) {
    switch (type) {
      case FileType.custom:
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case FileType.image:
        return const Icon(Icons.image, color: Colors.blue);
      case FileType.video:
        return const Icon(Icons.video_library, color: Colors.purple);
      default:
        return const Icon(Icons.attach_file, color: Colors.grey);
    }
  }
}

class AttachedFile {
  final String name;
  final String path;
  final FileType type;
  final int size;
  final List<int>? bytes;

  AttachedFile({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    this.bytes,
  });
}