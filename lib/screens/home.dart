import 'package:abs_flow/screens/add_cours.dart';
import 'package:abs_flow/screens/historique.dart';
import 'package:abs_flow/screens/send_alert_page.dart';
import 'package:flutter/material.dart';

import 'prise_appel.dart';
import 'students_list.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page d\'Accueil'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.group),
              title: Text('Prise d\'appel'),
              onTap: () {
                // Naviguer vers la page "Prise d'appel"
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PriseAppelPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Liste des étudiants'),
              onTap: () {
                // Naviguer vers la page "Liste des étudiants"
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentsListPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Ajouter cours'),
              onTap: () {
                // Naviguer vers la page "Liste des étudiants"
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCoursPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Historique'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoriquePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.add_alert),
              title: Text('Envoyer alert'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SendAlertPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text('Bienvenue sur la page d\'accueil!'),
      ),
    );
  }
}
