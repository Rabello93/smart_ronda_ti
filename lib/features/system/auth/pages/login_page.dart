import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Image.asset(
                "assets/logo.png",
                height: 180,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.checklist_rtl,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 30),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 20),
              _loading 
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _submit, 
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                        child: Text(_isLogin ? "ENTRAR" : "CADASTRAR"),
                      ),
                      if (_isLogin && _canCheckBiometrics) ...[
                        const SizedBox(height: 16),
                        IconButton(
                          iconSize: 50,
                          icon: const Icon(Icons.fingerprint, color: Colors.blue),
                          onPressed: _authenticateWithBiometrics,
                          tooltip: "Login com Biometria",
                        ),
                        const Text("Entrar com biometria", style: TextStyle(color: Colors.grey)),
                      ],
                    ],
                  ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin), 
                child: Text(_isLogin ? "Não tem conta? Cadastre-se" : "Já tenho conta. Fazer Login")
              ),
            ],
          ),
        ),
      ),
    );
  }
}
