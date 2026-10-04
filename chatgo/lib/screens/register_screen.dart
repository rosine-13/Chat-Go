// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';

class _RegisterColors {
  static const Color teal = Color(0xFF17A589);
  static const Color green = Color(0xFF2ECC71);
  static const Color fieldBackground = Color(0xFFEAEAEA);
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyLoggedIn();
  }

  void _checkIfAlreadyLoggedIn() async {
    final isLoggedIn = await UserService.isUserLoggedIn();
    if (isLoggedIn && mounted) {
      final userName = await UserService.getFirstName();
      if (userName != null && userName.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(userName: userName),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // 🔥 FONCTION D'INSCRIPTION
  // ============================================================

  void _handleRegister() async {
    final isFormValid = _formKey.currentState!.validate();

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Merci d'accepter les conditions d'utilisation"),
        ),
      );
      return;
    }

    if (isFormValid) {
      setState(() => _isLoading = true);

      try {
        final firstName = _firstNameController.text.trim();
        final lastName = _lastNameController.text.trim();
        final email = _emailController.text.trim();
        final whatsapp = _whatsappController.text.trim();
        final password = _passwordController.text.trim();

        // 🔥 Appel à l'API d'inscription
        final response = await ApiService.register(
          firstName: firstName,
          lastName: lastName,
          email: email,
          whatsapp: whatsapp,
          password: password,
        );

        final user = response['user'];
        final displayName = user['first_name'];

        print('📝 NOUVELLE INSCRIPTION :');
        print('   Prénom : $displayName');
        print('   Email : $email');
        print('   ID : ${user['id']}');

        // 🔥 Sauvegarder en local
        await UserService.saveUser(
          firstName: displayName,
          lastName: lastName,
          email: email,
          whatsapp: whatsapp,
        );

        // 🔥 Indiquer que c'est un NOUVEL utilisateur
        await UserService.setNewUser(true);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                userName: displayName,
                isNewUser: true,
              ),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      _buildIconCircle(),
                      const SizedBox(height: 16),
                      const Text(
                        'Créez votre compte',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'NOM*',
                              controller: _lastNameController,
                              hint: 'Votre nom',
                              icon: Icons.person_outline,
                              textCapitalization: TextCapitalization.words,
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Requis'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              label: 'Prénom*',
                              controller: _firstNameController,
                              hint: 'Votre prénom',
                              icon: Icons.person_outline,
                              textCapitalization: TextCapitalization.words,
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Requis'
                                      : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildTextField(
                        label: 'Adresse mail*',
                        controller: _emailController,
                        hint: 'exemple@gmail.com',
                        icon: null,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Merci de saisir ton email';
                          }
                          if (!value.contains('@')) {
                            return 'Adresse email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      // ============================================================
                      // 🔥 CHAMP WHATSAPP AVEC VALIDATION IVOIRIENNE
                      // ============================================================
                      _buildTextField(
                        label: 'Numero Whatsapp*',
                        controller: _whatsappController,
                        hint: '+225 01 00 48 31 41',
                        icon: null,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          // 1️⃣ Vérifier si le champ est vide
                          if (value == null || value.trim().isEmpty) {
                            return 'Merci de saisir ton numéro';
                          }

                          // 2️⃣ Nettoyer le numéro (supprimer les espaces)
                          String cleaned = value.trim().replaceAll(RegExp(r'\s'), '');
                          print('📱 Numéro nettoyé : $cleaned');

                          // 3️⃣ Vérifier que le numéro commence par +225
                          if (!cleaned.startsWith('+225')) {
                            return 'Le numéro doit commencer par +225 (Côte d\'Ivoire)';
                          }

                          // 4️⃣ Vérifier que le numéro a la bonne longueur
                          // +225 + 10 chiffres = 14 caractères
                          if (cleaned.length != 14) {
                            return 'Numéro invalide. Format : +225 01 00 48 31 41 (10 chiffres)';
                          }

                          // 5️⃣ Vérifier que tout après +225 sont des chiffres
                          final digits = cleaned.substring(4);
                          if (!RegExp(r'^[0-9]+$').hasMatch(digits)) {
                            return 'Numéro invalide. Utilisez uniquement des chiffres.';
                          }

                          // ✅ Tout est valide
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildTextField(
                        label: 'Mot de passe*',
                        controller: _passwordController,
                        hint: 'Choisissez un mot de passe',
                        icon: null,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.black45,
                          ),
                          onPressed: () {
                            setState(() =>
                                _isPasswordVisible = !_isPasswordVisible);
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Merci de saisir un mot de passe';
                          }
                          if (value.length < 6) {
                            return '6 caractères minimum';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildTextField(
                        label: 'Confirmation*',
                        controller: _confirmPasswordController,
                        hint: 'Confirmez votre mot de passe',
                        icon: null,
                        obscureText: !_isConfirmPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.black45,
                          ),
                          onPressed: () {
                            setState(() =>
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible);
                          },
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            activeColor: _RegisterColors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (value) {
                              setState(() => _acceptTerms = value ?? false);
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "J'accepte les conditions d'utilisations",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _RegisterColors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Valider & Continuer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Retour',
                      style: TextStyle(color: Colors.black87, fontSize: 15),
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

  Widget _buildIconCircle() {
    return Container(
      width: 90,
      height: 90,
      decoration: const BoxDecoration(
        color: _RegisterColors.teal,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_add_alt_1,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          decoration: _fieldDecoration(
            hint: hint,
            icon: icon,
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: Colors.black54, size: 20) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _RegisterColors.fieldBackground,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(
          color: _RegisterColors.teal,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1,
        ),
      ),
      errorStyle: const TextStyle(fontSize: 11),
    );
  }
}