// ============================================================
// IMPORT DES PACKAGES NÉCESSAIRES
// ============================================================

import 'package:flutter/material.dart';
// Material : fournit tous les widgets Flutter (Scaffold, Text, etc.)

import 'login_screen.dart';
// LoginScreen : la page vers laquelle on navigue quand
// l'utilisateur clique sur "Commencer"

// ============================================================
// COULEURS DE LA MAQUETTE
// ============================================================

class AppColors {
  // Cette classe centralise TOUTES les couleurs utilisées
  // dans l'application. Avantage : si le design change,
  // on modifie une seule ligne au lieu de chercher partout.

  static const Color background = Color(0xFF0E5C4C);
  // Vert foncé : couleur de fond de l'écran splash
  // 0xFF0E5C4C = #0E5C4C (vert forêt)

  static const Color accentGreen = Color(0xFF2ECC71);
  // Vert clair : utilisé pour le cercle et le badge
  // 0xFF2ECC71 = #2ECC71 (vert émeraude)

  static const Color white = Colors.white;
  // Blanc : utilisé pour le texte et le bouton
}

// ============================================================
// ÉCRAN D'ACCUEIL (StatefulWidget)
// ============================================================

class ChatAndGoSplashScreen extends StatefulWidget {
  // StatefulWidget : l'écran peut changer d'état
  // (ici, le logo flotte en hauteur grâce à une animation)

  const ChatAndGoSplashScreen({super.key});
  // Constructeur constant

  @override
  State<ChatAndGoSplashScreen> createState() =>
      _ChatAndGoSplashScreenState();
  // Crée l'état associé à ce widget
}

// ============================================================
// ÉTAT DE L'ÉCRAN D'ACCUEIL
// ============================================================

class _ChatAndGoSplashScreenState extends State<ChatAndGoSplashScreen>
    // SingleTickerProviderStateMixin :
    // Fournit un "tick" (une horloge) qui permet à l'animation
    // de se rafraîchir à chaque frame (~60 fois par seconde)
    with SingleTickerProviderStateMixin {

  // ============================================================
  // 1. L'ANIMATION (le logo qui flotte)
  // ============================================================

  late final AnimationController _controller;
  // AnimationController : le moteur de l'animation.
  // Il pilote la progression dans le temps.
  // "late final" = initialisé plus tard (dans initState)

  late final Animation<double> _floatAnimation;
  // Animation<double> : la valeur qui change dans le temps.
  // Ici, c'est un déplacement vertical de -8 à +8 pixels.

  // ============================================================
  // 2. CYCLE DE VIE : initState() - Au démarrage de la page
  // ============================================================

  @override
  void initState() {
    // initState() s'exécute UNE SEULE FOIS, quand le widget
    // est créé. C'est l'endroit idéal pour démarrer une animation.

    super.initState();
    // Toujours appeler super.initState() en premier

    // ----------------------------------------------------------
    // Création du contrôleur d'animation
    // ----------------------------------------------------------

    _controller = AnimationController(
      vsync: this,
      // vsync = synchronisation avec l'écran.
      // "this" = le widget actuel (grâce à SingleTickerProviderStateMixin)
      // Évite de gaspiller des ressources si l'écran n'est pas visible.

      duration: const Duration(milliseconds: 1400),
      // Durée d'un aller simple : 1.4 secondes
    );

    // ----------------------------------------------------------
    // Création de l'animation de flottement
    // ----------------------------------------------------------

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      // Tween : définit les valeurs de début et de fin.
      // begin: -8 = le logo monte de 8 pixels
      // end: 8 = le logo descend de 8 pixels

      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        // easeInOut = accélère puis ralentit en douceur.
        // L'animation n'est pas saccadée, elle est fluide.
      ),
    );

    // ----------------------------------------------------------
    // Démarrer l'animation (en boucle)
    // ----------------------------------------------------------

    _controller.repeat(reverse: true);
    // repeat(reverse: true) : l'animation tourne en boucle.
    // Elle va de -8 à +8, puis revient de +8 à -8, etc.
    // Le logo flotte indéfiniment.
  }

  // ============================================================
  // 3. CYCLE DE VIE : dispose() - Quand on quitte la page
  // ============================================================

  @override
  void dispose() {
    // dispose() est appelé quand l'écran est fermé.
    // On doit libérer les ressources pour éviter les fuites de mémoire.

    _controller.dispose();
    // Arrête l'animation et libère la mémoire.

    super.dispose();
    // Toujours appeler super.dispose() à la fin
  }

  // ============================================================
  // 4. BUILD : CONSTRUCTION DE L'INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold = structure de base d'une page.
      // Il fournit le fond, l'appBar optionnelle, etc.

      backgroundColor: AppColors.background,
      // Fond de la page : vert foncé (#0E5C4C)

      body: SafeArea(
        // SafeArea : évite que le contenu passe sous la barre
        // de notification (en haut) ou la barre de navigation
        // (en bas sur certains téléphones).

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          // Padding à gauche et à droite de 24 pixels.

          child: Column(
            // Column : disposition VERTICALE des éléments.
            // Les widgets sont empilés de haut en bas.

            mainAxisAlignment: MainAxisAlignment.center,
            // Centrage vertical (au milieu de l'écran)

            crossAxisAlignment: CrossAxisAlignment.center,
            // Centrage horizontal

            children: [
              // ----------------------------------------------------------
              // ÉLÉMENT 1 : Espace vide en haut (flexible)
              // ----------------------------------------------------------

              const Spacer(flex: 3),
              // Spacer : prend un espace vide proportionnel.
              // flex: 3 = prend 3 parts sur le total (3+4+1 = 8 parts)
              // Pousse le contenu vers le centre-bas.

              // ----------------------------------------------------------
              // ÉLÉMENT 2 : Le LOGO animé (cercle avec éclair)
              // ----------------------------------------------------------

              AnimatedBuilder(
                // AnimatedBuilder : écoute l'animation à chaque frame.
                // Il ne reconstruit QUE ce qu'il y a dans "builder".
                // C'est plus performant que de reconstruire tout l'écran.

                animation: _floatAnimation,
                // L'animation à écouter

                builder: (context, child) {
                  // builder est appelé à chaque frame (60x par seconde)

                  return Transform.translate(
                    // Transform.translate : déplace le widget enfant
                    // sans changer sa taille ni sa place dans la mise en page.
                    // offset = décalage en X et Y.

                    offset: Offset(0, _floatAnimation.value),
                    // X = 0 (pas de mouvement horizontal)
                    // Y = _floatAnimation.value (-8 à +8)

                    child: child,
                    // On réutilise le child construit une seule fois
                  );
                },

                child: _buildLogoCircle(),
                // Le child est construit UNE SEULE FOIS,
                // puis réutilisé à chaque frame (optimisation).
              ),

              const SizedBox(height: 32),
              // Espace fixe de 32 pixels entre le logo et le titre

              // ----------------------------------------------------------
              // ÉLÉMENT 3 : Le TITRE "Chat&GO"
              // ----------------------------------------------------------

              const Text(
                'Chat&GO',
                style: TextStyle(
                  color: AppColors.white,
                  // Texte blanc
                  fontSize: 40,
                  // Taille : 40 pixels (grand)
                  fontWeight: FontWeight.w900,
                  // Très gras (le plus gras possible)
                ),
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------------------
              // ÉLÉMENT 4 : Le BADGE "Assistant IA Local"
              // ----------------------------------------------------------

              _buildBadge(),
              // Appelle la fonction qui construit le badge vert

              const SizedBox(height: 24),

              // ----------------------------------------------------------
              // ÉLÉMENT 5 : Le texte de DESCRIPTION
              // ----------------------------------------------------------

              const Text(
                'Trouvez instantanément le bon prestataire '
                'autour de vous et contactez-le en un clic via '
                'Whatsapp ou appel téléphonique.',
                textAlign: TextAlign.center,
                // Centrage du texte
                style: TextStyle(
                  color: Colors.white70,
                  // Blanc avec 70% d'opacité (légèrement transparent)
                  fontSize: 16,
                  height: 1.4,
                  // Interligne : 1.4 fois la taille normale
                ),
              ),

              const Spacer(flex: 4),
              // 4 parts d'espace vide (pousse le bouton vers le bas)

              // ----------------------------------------------------------
              // ÉLÉMENT 6 : Le BOUTON "Commencer"
              // ----------------------------------------------------------

              _buildStartButton(context),
              // Appelle la fonction qui construit le bouton

              const SizedBox(height: 24),
              // Espace en bas
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 5. FONCTIONS AUXILIAIRES (pour construire les widgets)
  // ============================================================

  // ------------------------------------------------------------
  // _buildLogoCircle() : Le cercle avec l'éclair
  // ------------------------------------------------------------
  // Structure :
  //   ┌─────────────────────┐
  //   │   Container (blanc)  │  ← Grand cercle blanc (bordure)
  //   │   ┌───────────────┐  │
  //   │   │  Container    │  │  ← Petit cercle vert
  //   │   │  (vert)       │  │
  //   │   │   ⚡ (éclair) │  │  ← Icône éclair
  //   │   └───────────────┘  │
  //   └─────────────────────┘

  Widget _buildLogoCircle() {
    return Container(
      width: 130,
      height: 130,
      // Cercle blanc de 130x130 pixels

      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        // Forme circulaire
      ),

      child: Center(
        // Center : centre le contenu à l'intérieur

        child: Container(
          width: 110,
          height: 110,
          // Cercle vert de 110x110 pixels

          decoration: const BoxDecoration(
            color: AppColors.accentGreen,
            shape: BoxShape.circle,
          ),

          child: const Icon(
            Icons.bolt,
            // Icône éclair (⚡) fournie par Material Icons
            color: AppColors.white,
            size: 55,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // _buildBadge() : Le badge "Assistant IA Local"
  // ------------------------------------------------------------
  // Forme : une pilule (coins très arrondis)

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20, // 20 pixels à gauche et à droite
        vertical: 10, // 10 pixels en haut et en bas
      ),

      decoration: BoxDecoration(
        color: AppColors.accentGreen,
        borderRadius: BorderRadius.circular(30),
        // Coins arrondis → forme de pilule
      ),

      child: const Text(
        'Assistant IA Local',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // _buildStartButton() : Le bouton "Commencer →"
  // ------------------------------------------------------------
  // Structure :
  //   ┌─────────────────────────────────┐
  //   │  [Commencer] →                 │  ← Texte + flèche
  //   └─────────────────────────────────┘

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      // Prend TOUTE la largeur disponible

      height: 56,
      // Hauteur fixe de 56 pixels

      child: ElevatedButton(
        onPressed: () {
          // ----------------------------------------------------------
          // Navigation vers la page de CONNEXION
          // ----------------------------------------------------------

          Navigator.push(
            // Navigator.push : ajoute une nouvelle page par-dessus
            // l'écran actuel (avec animation de transition)

            context,
            MaterialPageRoute(
              // MaterialPageRoute : décrit quelle page afficher

              builder: (context) => const LoginScreen(),
              // Crée la page de connexion
            ),
          );
        },

        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          // Fond blanc
          foregroundColor: AppColors.background,
          // Texte vert foncé
          elevation: 0,
          // Pas d'ombre (flat design)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            // Coins arrondis (pilule)
          ),
        ),

        child: const Row(
          // Row : disposition horizontale
          // [Commencer] + [→]

          mainAxisAlignment: MainAxisAlignment.center,
          // Centre le contenu horizontalement

          children: [
            Text(
              'Commencer',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            // Espace entre le texte et la flèche

            Icon(
              Icons.arrow_forward,
              // Flèche vers la droite
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}