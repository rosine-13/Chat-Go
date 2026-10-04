// ============================================================
// IMPORT DES PACKAGES NÉCESSAIRES
// ============================================================

import 'package:flutter/material.dart';
// Material : fournit tous les widgets Flutter (MaterialApp, Scaffold, etc.)

import 'screens/splash_screen.dart';
// splash_screen : l'écran d'accueil de l'application
// On importe le fichier qui contient ChatAndGoSplashScreen

// ============================================================
// POINT D'ENTRÉE DE L'APPLICATION
// ============================================================

// La fonction main() est le point de départ de toute application Dart.
// C'est la première fonction exécutée quand l'application démarre.

void main() {
  // runApp() : la fonction qui lance l'application Flutter.
  // Elle prend un widget (ici ChatAndGoApp) et le place à la racine de l'arbre.
  runApp(const ChatAndGoApp());
  // const : la construction de l'application est constante (optimisation)
}

// ============================================================
// CLASSE PRINCIPALE : L'APPLICATION
// ============================================================

class ChatAndGoApp extends StatelessWidget {
  // ChatAndGoApp est un StatelessWidget : il ne change jamais d'état.
  // Une fois construit, il reste identique.

  const ChatAndGoApp({super.key});
  // Constructeur constant (optimisation)

  // ============================================================
  // build() : CONSTRUCTION DE L'INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // La méthode build() est appelée une seule fois au démarrage
    // (car c'est un StatelessWidget)

    return MaterialApp(
      // MaterialApp : le conteneur principal de toute application Flutter.
      // Il fournit :
      // - Le thème (couleurs, polices)
      // - La navigation (routes)
      // - Les traductions
      // - Les fonctionnalités Material Design

      // ----------------------------------------------------------
      // 1. debugShowCheckedModeBanner
      // ----------------------------------------------------------

      debugShowCheckedModeBanner: false,
      // false = cache le bandeau "DEBUG" rouge en haut à droite.
      // En développement, il est affiché par défaut.
      // En production, on le met souvent à false pour une app propre.

      // ----------------------------------------------------------
      // 2. title
      // ----------------------------------------------------------

      title: 'Chat&GO',
      // Le titre de l'application.
      // Utilisé par :
      // - Le gestionnaire de tâches (Android/iOS)
      // - La barre de titre de la fenêtre (Web/Desktop)
      // - Les notifications système

      // ----------------------------------------------------------
      // 3. home (L'ÉCRAN D'ACCUEIL)
      // ----------------------------------------------------------

      home: const ChatAndGoSplashScreen(),
      // home = le premier écran affiché quand l'application démarre.
      // Ici, c'est l'écran de démarrage (splash screen).

      // const : l'instance de ChatAndGoSplashScreen est constante.
      // Cela permet à Flutter d'optimiser la construction.
    );
  }
}