// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
// ❌ SUPPRIMÉ : import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'login_screen.dart';

// COULEURS SPÉCIFIQUES À CETTE PAGE
class _ChatColors {
  static const Color header = Color(0xFF179C7C);
  static const Color chatBackground = Color(0xFFEDE6DE);
  static const Color botBubble = Colors.white;
  static const Color userBubble = Color(0xFFD9F7E3);
  static const Color cardDark = Color(0xFF1C2431);
  static const Color availableGreen = Color(0xFF2ECC71);
  static const Color callBlue = Color(0xFFB9D6F2);
  static const Color whatsappGreen = Color(0xFF25D366);
}

// ============================================================
// MODÈLES DE DONNÉES
// ============================================================

enum MessageType { bot, user, providerCard }

class ChatMessage {
  final MessageType type;
  final String? text;
  final ProviderInfo? provider;

  ChatMessage.bot(this.text) : type = MessageType.bot, provider = null;
  ChatMessage.user(this.text) : type = MessageType.user, provider = null;
  ChatMessage.providerCard(this.provider)
    : type = MessageType.providerCard,
      text = null;
}

class ProviderInfo {
  final String name;
  final String location;
  final String phone;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final String? photoUrl;

  const ProviderInfo({
    required this.name,
    required this.location,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.isAvailable = true,
    this.photoUrl,
  });
}

// ============================================================
// ÉCRAN DE CHAT (StatefulWidget)
// ============================================================

class ChatScreen extends StatefulWidget {
  final String userName;
  final bool isNewUser;
  final bool isFirstLogin;

  const ChatScreen({
    super.key,
    required this.userName,
    this.isNewUser = false,
    this.isFirstLogin = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// ============================================================
// ÉTAT DE L'ÉCRAN DE CHAT
// ============================================================

class _ChatScreenState extends State<ChatScreen> {
  // ============================================================
  // 1. CONTROLEURS
  // ============================================================

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  DateTime? _lastBackPressTime;

  // ============================================================
  // 2. ÉTATS DE L'INTERFACE
  // ============================================================

  bool _isProcessing = false;
  bool _isLoading = true;

  // ============================================================
  // 3. LISTE DES MESSAGES
  // ============================================================

  final List<ChatMessage> _messages = [];
  final List<String> _suggestions = ['Plombier', 'Electricien', 'Restaurant'];

  // ============================================================
  // 4. CYCLE DE VIE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _showWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // 5. AFFICHAGE DU MESSAGE D'ACCUEIL PERSONNALISÉ
  // ============================================================

  void _showWelcomeMessage() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _addWelcomeMessage();
      });
      _scrollToBottom();
    }
  }

  // ============================================================
  // 🔥 AJOUT DU MESSAGE DE BIENVENUE (AVEC {bold:...})
  // ============================================================

  void _addWelcomeMessage() {
    final userName = widget.userName;
    String welcomeMessage;

    // 🔥 CAS 1 : NOUVEL UTILISATEUR (inscription)
    if (widget.isNewUser) {
      welcomeMessage =
          '''
🎉 {bold:Bienvenue dans la famille Chat&GO, $userName !}

Je suis {bold:ton assistant personnel} 🤖, conçu pour te faciliter la vie en Côte d'Ivoire.

Avec moi, fini les numéros qu'on cherche, les appels qui tombent dans le vide, ou les heures passées à appeler plusieurs prestataires.

✅ {bold:Je te trouve} le bon prestataire (plombier, électricien, restaurant, taxi, coiffeur...)
✅ {bold:Je te mets en relation} en un clic (Appel ou WhatsApp)
✅ {bold:Je te localise} les meilleurs autour de toi

{bold:Dis-moi ce que tu cherches}, et je m'occupe de tout !

Alors, {bold:par quoi on commence ?} 🚀
''';
    }
    // 🔥 CAS 2 : PREMIÈRE CONNEXION
    else if (widget.isFirstLogin) {
      welcomeMessage =
          '''
👋 {bold:Content de te revoir $userName !}

C'est ta première connexion depuis ton inscription.

Je suis là pour t'aider à trouver des prestataires en Côte d'Ivoire.

{bold:Dis-moi ce que tu cherches}, je m'occupe du reste ! 🎯
''';
    }
    // 🔥 CAS 3 : RETOUR (connexion suivante)
    else {
      final messages = [
        '{bold:Content de te revoir $userName !} 👋\n\nQue puis-je faire pour vous aujourd\'hui ?',
        '{bold:De retour $userName !} 😊\n\nEn quoi puis-je vous aider ?',
        '{bold:Ravi de te revoir $userName !} 🌟\n\nQuel service recherchez-vous ?',
        '{bold:Bonjour $userName !} Heureux de te revoir 🎯\n\nComment puis-je vous assister ?',
      ];
      final randomIndex = DateTime.now().millisecond % messages.length;
      welcomeMessage = messages[randomIndex];
    }

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage.bot(welcomeMessage));
      });
    }
  }

  // ============================================================
  // 6. DÉFILEMENT AUTOMATIQUE
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ============================================================
  // 7. ENVOI DU MESSAGE
  // ============================================================

  void _sendMessage(String text) async {
    final userText = text.trim();
    if (userText.isEmpty) return;

    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage.user(userText));
      _isProcessing = true;
    });
    _scrollToBottom();

    try {
      final resultat = await ApiService.analyserMessage(userText);
      final intention = resultat['intention'] ?? {};
      final prestataires = (resultat['prestataires'] as List?) ?? [];
      final reponseAmicale = resultat['reponse_amicale'];

      setState(() {
        _isProcessing = false;

        if (reponseAmicale != null && reponseAmicale.isNotEmpty) {
          _messages.add(ChatMessage.bot(reponseAmicale));
          return;
        }

        if (prestataires.isNotEmpty) {
          _messages.add(
            ChatMessage.bot(
              prestataires.length > 1
                  ? "Voici ce que j'ai trouvé pour vous :"
                  : "J'ai trouvé ceci pour vous :",
            ),
          );
          for (final prestataire in prestataires) {
            _messages.add(
              ChatMessage.providerCard(
                ProviderInfo(
                  name: prestataire['nom'] ?? 'Nom inconnu',
                  location: prestataire['ville'] ?? 'Adresse inconnue',
                  phone: prestataire['telephone'] ?? '',
                  latitude: (prestataire['latitude'] ?? 0.0).toDouble(),
                  longitude: (prestataire['longitude'] ?? 0.0).toDouble(),
                  isAvailable: prestataire['disponible'] == 1,
                  photoUrl: prestataire['photo_url'],
                ),
              ),
            );
          }
        } else {
          final categorie = intention['categorie'];
          String message;
          if (categorie == 'autre') {
            message =
                "Je ne comprends pas bien votre demande. Pouvez-vous reformuler ? (ex: 'Je cherche un plombier' ou 'Je veux une pizza')";
          } else {
            message =
                "Désolé, aucun prestataire trouvé pour cette demande (${intention['categorie'] ?? 'inconnue'}).";
          }
          _messages.add(ChatMessage.bot(message));
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _messages.add(ChatMessage.bot("❌ Erreur : ${e.toString()}"));
      });
    }

    _scrollToBottom();
  }

  // ============================================================
  // 8. FONCTIONS NATIVES
  // ============================================================

  Future<void> _appeler(String telephone) async {
    final uri = Uri(scheme: 'tel', path: telephone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _contacterWhatsapp(
    String telephone,
    String nomPrestataire,
  ) async {
    final numeroNettoye = telephone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      "Bonjour $nomPrestataire, je vous contacte via l'application Chat&Go.",
    );
    final uri = Uri.parse("https://wa.me/$numeroNettoye?text=$message");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _ouvrirLocalisation(double latitude, double longitude) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ============================================================
  // 9. DÉCONNEXION
  // ============================================================

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await UserService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  // ============================================================
  // 10. GESTION DU BOUTON RETOUR
  // ============================================================

  Future<bool> _handleBackPress() async {
    final now = DateTime.now();
    final isSecondPress =
        _lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) < const Duration(seconds: 2);

    if (isSecondPress) {
      return true;
    }

    _lastBackPressTime = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appuie encore une fois pour quitter'),
        duration: Duration(seconds: 2),
      ),
    );
    return false;
  }

  // ============================================================
  // 11. BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBackPress();
        if (shouldPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: _ChatColors.chatBackground,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildMessageList()),
              _buildSuggestions(),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 12. COMPOSANTS UI
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _ChatColors.header,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // GROUPE GAUCHE : Retour + Avatar + Nom
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.black87,
                    child: Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _ChatColors.availableGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: _ChatColors.header, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat&GO Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'En ligne',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          // GROUPE DROITE : Déconnexion
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        _buildDateDivider("AUJOURD'HUI"),
        const SizedBox(height: 12),
        if (_isLoading) _buildTypingIndicator(),
        for (final message in _messages) ...[
          _buildMessageBubble(message),
          const SizedBox(height: 12),
        ],
        if (_isProcessing) _buildTypingIndicator(),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DotAnimation(delay: 0),
            SizedBox(width: 4),
            _DotAnimation(delay: 300),
            SizedBox(width: 4),
            _DotAnimation(delay: 600),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(String label) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    switch (message.type) {
      case MessageType.bot:
        return _buildTextBubble(message.text!, isBot: true);
      case MessageType.user:
        return _buildTextBubble(message.text!, isBot: false);
      case MessageType.providerCard:
        return _buildProviderCard(message.provider!);
    }
  }

  Widget _buildTextBubble(String text, {required bool isBot}) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isBot ? _ChatColors.botBubble : _ChatColors.userBubble,
          borderRadius: BorderRadius.circular(18),
        ),
        child: _buildRichText(text),
      ),
    );
  }

  Widget _buildRichText(String raw) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\{bold:(.*?)\}');
    int lastEnd = 0;

    for (final match in pattern.allMatches(raw)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: raw.substring(lastEnd, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < raw.length) {
      spans.add(TextSpan(text: raw.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildProviderCard(ProviderInfo provider) {
    final bool hasPhoto =
        provider.photoUrl != null && provider.photoUrl!.isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            hasPhoto ? _buildPhotoHeader(provider) : _buildIconHeader(provider),
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _buildCardActionButton(
                      label: 'Appeler',
                      icon: Icons.call,
                      color: _ChatColors.callBlue,
                      textColor: Colors.black87,
                      onTap: () => _appeler(provider.phone),
                    ),
                  ),
                  Expanded(
                    child: _buildCardActionButton(
                      label: 'Whatsapp',
                      icon: Icons.chat,
                      color: _ChatColors.whatsappGreen,
                      textColor: Colors.white,
                      onTap: () =>
                          _contacterWhatsapp(provider.phone, provider.name),
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

  Widget _buildPhotoHeader(ProviderInfo provider) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            provider.photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: _ChatColors.cardDark,
              alignment: Alignment.center,
              child: const Icon(
                Icons.storefront,
                color: Colors.white38,
                size: 32,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.35, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          if (provider.isAvailable)
            Positioned(top: 12, left: 12, child: _buildAvailableBadge()),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _ouvrirLocalisation(
                    provider.latitude,
                    provider.longitude,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: _ChatColors.availableGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          provider.location,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.open_in_new,
                        color: Colors.white38,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconHeader(ProviderInfo provider) {
    return Container(
      width: double.infinity,
      color: _ChatColors.cardDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (provider.isAvailable) _buildAvailableBadge(),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _ChatColors.availableGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            provider.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () =>
                _ouvrirLocalisation(provider.latitude, provider.longitude),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: _ChatColors.availableGreen,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    provider.location,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.open_in_new, color: Colors.white38, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _ChatColors.availableGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Disponible',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCardActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return OutlinedButton(
            onPressed: () => _sendMessage(suggestion),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(
                color: _ChatColors.header.withValues(alpha: 0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              suggestion,
              style: const TextStyle(color: _ChatColors.header, fontSize: 13),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // 🔥 BARRE DE SAISIE (SANS MICRO)
  // ============================================================

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: _ChatColors.chatBackground,
      child: Row(
        children: [
          // ---------- BOUTON "+" (Ajouter un fichier) ----------
          GestureDetector(
            onTap: _ajouterFichier,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),

          // ---------- CHAMP DE TEXTE ----------
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: _sendMessage,
                      decoration: const InputDecoration(
                        hintText: 'Tapez votre message...',
                        hintStyle: TextStyle(color: Colors.black38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  // ❌ MICRO SUPPRIMÉ
                  const SizedBox(width: 12),

                  // ---------- BOUTON CAMÉRA ----------
                  GestureDetector(
                    onTap: _prendrePhoto,
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ---------- BOUTON ENVOYER ----------
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: _ChatColors.header,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔥 FONCTIONS POUR LES BOUTONS
  // ============================================================

  // Ajouter un fichier (image)
  void _ajouterFichier() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _messages.add(ChatMessage.user('📷 Image envoyée'));
      });
      _scrollToBottom();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ Image : ${image.name}')));
    }
  }

  // Prendre une photo
  void _prendrePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _messages.add(ChatMessage.user('📷 Photo prise'));
      });
      _scrollToBottom();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ Photo : ${photo.name}')));
    }
  }
}

// ============================================================
// 13. WIDGET D'ANIMATION DES POINTS DE FRAPPE
// ============================================================

class _DotAnimation extends StatefulWidget {
  final int delay;

  const _DotAnimation({required this.delay});

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: const CircleAvatar(radius: 4, backgroundColor: Colors.black54),
        );
      },
    );
  }
}
