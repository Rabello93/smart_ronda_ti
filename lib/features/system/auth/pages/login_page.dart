import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_ronda_ti/app/theme.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLogin = true;
  bool _loading = false;
  final _authController = AuthController();
  final _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _canCheckBiometrics = canCheck && isDeviceSupported;
      });
    } catch (e) {
      debugPrint("Erro ao verificar biometria: $e");
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Autentique-se para entrar no Smart Ronda TI',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        final email = await _secureStorage.read(key: 'user_email');
        final password = await _secureStorage.read(key: 'user_password');

        if (email != null && password != null) {
          _emailController.text = email;
          _passwordController.text = password;
          _submit();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Faça login com e-mail e senha primeiro para habilitar a biometria."))
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Erro na autenticação biométrica: $e");
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Preencha e-mail e senha"))
       );
       return;
    }

    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await _authController.login(email, password);
        // Salva as credenciais para futuro login biométrico
        await _secureStorage.write(key: 'user_email', value: email);
        await _secureStorage.write(key: 'user_password', value: password);
      } else {
        await _authController.registerSimple(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      String mensagem = "Erro: ${e.toString()}";
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.deepNavy : AppTheme.coolGrey,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.2,
            colors: [AppTheme.cyanNeon.withValues(alpha: 0.05), AppTheme.deepNavy],
          ) : null,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    colors: [AppTheme.cyanNeon, AppTheme.electricBlue],
                  ).createShader(rect),
                  child: Image.asset(
                    "assets/logo.png",
                    height: 140,
                    color: Colors.white,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.hub_rounded,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "SMART RONDA TI",
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: isDark ? Colors.white : AppTheme.deepNavy,
                  ),
                ),
                Text(
                  "ASSET GOVERNANCE SYSTEM",
                  style: AppTheme.monoStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.cyanNeon,
                  ),
                ),
                const SizedBox(height: 50),
                TextField(
                  controller: _emailController, 
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-MAIL CORPORATIVO', 
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                  )
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController, 
                  decoration: const InputDecoration(
                    labelText: 'SENHA DE ACESSO', 
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                  ), 
                  obscureText: true
                ),
                const SizedBox(height: 32),
                _loading 
                  ? const CircularProgressIndicator(color: AppTheme.cyanNeon)
                  : Column(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.electricBlue, AppTheme.cyanNeon]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: AppTheme.electricBlue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _submit, 
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              _isLogin ? "AUTENTICAR SISTEMA" : "SOLICITAR ACESSO",
                              style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          ),
                        ),
                        if (_isLogin && _canCheckBiometrics) ...[
                          const SizedBox(height: 25),
                          InkWell(
                            onTap: _authenticateWithBiometrics,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  const Icon(Icons.fingerprint_rounded, size: 50, color: AppTheme.cyanNeon),
                                  const SizedBox(height: 8),
                                  Text(
                                    "BIOMETRIA", 
                                    style: AppTheme.monoStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin), 
                  child: Text(
                    _isLogin ? "NÃO POSSUI CONTA? CADASTRE-SE" : "JÁ POSSUI CONTA? AUTENTICAR",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
