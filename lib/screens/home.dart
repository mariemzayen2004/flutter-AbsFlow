import 'package:abs_flow/screens/add_cours.dart';
import 'package:abs_flow/screens/historique.dart';
import 'package:abs_flow/screens/send_alert_page.dart';
import 'package:abs_flow/screens/add_ratt.dart';
import 'package:abs_flow/screens/settings.dart';

import 'package:flutter/material.dart';


import 'prise_appel.dart';
import 'students_list.dart';
// Import à ajouter quand tu créeras la page paramètres
// import 'parametres.dart';

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
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
	    ListTile(
              leading: Icon(Icons.group),
              title: Text('Liste des étudiants'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentsListPage()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Prise d\'appel'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PriseAppelPage()),
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

	    ListTile(
              leading: Icon(Icons.add),
              title: Text('Ajouter cours'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCoursPage()),
                );
              },
            ),

            // ⭐ Ajouter rattrapage
            ListTile(
              leading: Icon(Icons.add_alarm),
              title: Text('Ajouter rattrapage'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddRattPage()),
                );
              },
            ),

            // ⭐ NOUVEAU : Paramètres
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Paramètres'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
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
