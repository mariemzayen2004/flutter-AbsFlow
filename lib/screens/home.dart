import 'package:abs_flow/screens/add_cours.dart';
import 'package:abs_flow/screens/historique.dart';
import 'package:abs_flow/screens/send_alert_page.dart';
import 'package:abs_flow/screens/add_ratt.dart';
import 'package:abs_flow/screens/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/settings/settings.dart';
import '../services/setting_service.dart';
import 'prise_appel.dart';
import 'students_list.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<SettingsModel>('settings').listenable(),
      builder: (context, Box<SettingsModel> box, _) {
        final settingsService = SettingsService.instance;
        final settings = settingsService.getSettings();
        final isDarkMode = settings.isDarkMode;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'AbsFlow',
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
          ),
          drawer: Drawer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [Colors.grey[900]!, Colors.grey[800]!]
                      : [Colors.blue.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [Colors.grey[850]!, Colors.grey[800]!]
                            : [Colors.blue.shade700, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.school,
                              size: 40,
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.blue.shade700),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Menu Principal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.group,
                    title: 'Liste des étudiants',
                    page: StudentsListPage(),
                    color: Colors.purple,
                    isDarkMode: isDarkMode,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.check_circle,
                    title: 'Prise d\'appel',
                    page: PriseAppelPage(),
                    color: Colors.green,
                    isDarkMode: isDarkMode,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.add_alert,
                    title: 'Envoyer alert',
                    page: SendAlertPage(),
                    color: Colors.orange,
                    isDarkMode: isDarkMode,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.add,
                    title: 'Ajouter cours',
                    page: AddCoursPage(),
                    color: Colors.blue,
                    isDarkMode: isDarkMode,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.add_alarm,
                    title: 'Ajouter rattrapage',
                    page: AddRattPage(),
                    color: Colors.teal,
                    isDarkMode: isDarkMode,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.history,
                    title: 'Historique',
                    page: HistoriquePage(),
                    color: Colors.indigo,
                    isDarkMode: isDarkMode,
                  ),
                  Divider(
                    height: 32,
                    thickness: 1,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings,
                    title: 'Paramètres',
                    page: SettingsPage(),
                    color: Colors.grey,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [Colors.grey[900]!, Colors.grey[850]!]
                    : [Colors.blue.shade50, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de bienvenue
                    Text(
                      'Bienvenue Professeur ! ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.blue[200]
                            : Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Gérez vos absences facilement',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 32),

                    // Actions rapides
                    Text(
                      'Actions rapides',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.blue[200]
                            : Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Grille de cartes principales
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildActionCard(
                          context,
                          icon: Icons.check_circle,
                          title: 'Prise d\'appel',
                          color: Colors.green,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PriseAppelPage()),
                          ),
                          isDarkMode: isDarkMode,
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.group,
                          title: 'Étudiants',
                          color: Colors.purple,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => StudentsListPage()),
                          ),
                          isDarkMode: isDarkMode,
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.add_alert,
                          title: 'Envoyer alert',
                          color: Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SendAlertPage()),
                          ),
                          isDarkMode: isDarkMode,
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.history,
                          title: 'Historique',
                          color: Colors.indigo,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HistoriquePage()),
                          ),
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),

                    SizedBox(height: 32),

                    // Gestion des cours
                    Text(
                      'Gestion des cours',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.blue[200]
                            : Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(height: 16),

                    _buildWideCard(
                      context,
                      icon: Icons.add,
                      title: 'Ajouter un cours',
                      subtitle: 'Créer un nouveau cours',
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddCoursPage()),
                      ),
                      isDarkMode: isDarkMode,
                    ),
                    SizedBox(height: 12),
                    _buildWideCard(
                      context,
                      icon: Icons.add_alarm,
                      title: 'Ajouter un rattrapage',
                      subtitle: 'Planifier une séance de rattrapage',
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddRattPage()),
                      ),
                      isDarkMode: isDarkMode,
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

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDarkMode ? Colors.grey[200] : Colors.black87,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(isDarkMode ? 0.5 : 0.7),
                color.withOpacity(isDarkMode ? 0.7 : 1.0)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}