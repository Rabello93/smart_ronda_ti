import 'package:flutter/material.dart';
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
                : ElevatedButton(
                    onPressed: _submit, 
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: Text(_isLogin ? "ENTRAR" : "CADASTRAR"),
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
