// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'register_screen.dart';
import 'chat_screen.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';  // 🔥 NOUVEAU

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // 🔥 FONCTION DE CONNEXION (MODIFIÉE)
  // ============================================================

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        print('🔑 Tentative de connexion : $email');

        // 🔥 Appel à l'API de connexion
        final response = await ApiService.login(
          email: email,
          password: password,
        );

        final user = response['user'];
        final firstName = user['first_name'];
        final isFirstLogin = user['isFirstLogin'];

        print('✅ Connexion réussie : $firstName');
        print('   🔥 Première connexion : $isFirstLogin');

        // 🔥 Sauvegarder en local
        await UserService.saveUser(
          firstName: firstName,
          lastName: user['last_name'] ?? '',
          email: email,
          whatsapp: user['whatsapp'] ?? '',
        );

        // 🔥 Stocker l'indicateur
        await UserService.setFirstLogin(isFirstLogin);

        if (mounted) {
          setState(() => _isLoading = false);

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                userName: firstName,
                isFirstLogin: isFirstLogin,
              ),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur : ${e.toString()}')));

          print('❌ Erreur de connexion : $e');
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 8),

                _buildSmallLogo(),
                const SizedBox(height: 32),

                const Text(
                  'Content de te revoir 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connecte-toi pour continuer',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 32),

                _buildFieldLabel('Adresse email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    hint: 'exemple@email.com',
                    icon: Icons.email_outlined,
                  ),
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
                const SizedBox(height: 20),

                _buildFieldLabel('Mot de passe'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        );
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Merci de saisir ton mot de passe';
                    }
                    if (value.length < 6) {
                      return '6 caractères minimum';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(color: AppColors.accentGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.background,
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
                              color: AppColors.background,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Pas encore de compte ? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "S'inscrire",
                          style: TextStyle(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.accentGreen,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.bolt, color: Colors.white, size: 32),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }
}