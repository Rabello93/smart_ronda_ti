import 'package:flutter/material.dart';
import 'package:smart_ronda_ti/app/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthController _authController = AuthController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _funcaoController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _nascimentoController = TextEditingController();
  
  bool _loading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _authController.profileStream.listen((user) {
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _nomeController.text = user.nome;
          _funcaoController.text = user.funcao;
          _matriculaController.text = user.matricula;
          _nascimentoController.text = user.dataNascimento;
        });
      }
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _funcaoController.dispose();
    _matriculaController.dispose();
    _nascimentoController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    setState(() => _loading = true);
    try {
      final updatedUser = _currentUser!.copyWith(
        nome: _nomeController.text.trim(),
        funcao: _funcaoController.text.trim(),
        matricula: _matriculaController.text.trim(),
        dataNascimento: _nascimentoController.text.trim(),
      );

      await _authController.updateProfile(updatedUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil atualizado com sucesso!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red),
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
      appBar: AppBar(
        title: Text("MEU PERFIL", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
        backgroundColor: isDark ? AppTheme.deepNavy : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.electricBlue.withValues(alpha: 0.1),
                    child: const Icon(Icons.person_rounded, size: 50, color: AppTheme.electricBlue),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppTheme.cyanNeon, shape: BoxShape.circle),
                      child: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.deepNavy),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: "Nome Completo", prefixIcon: Icon(Icons.badge_rounded)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _funcaoController,
              decoration: const InputDecoration(labelText: "Cargo / Função", prefixIcon: Icon(Icons.work_rounded)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _matriculaController,
                    decoration: const InputDecoration(labelText: "Matrícula", prefixIcon: Icon(Icons.numbers_rounded)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nascimentoController,
                    decoration: const InputDecoration(labelText: "Data Nascimento", prefixIcon: Icon(Icons.calendar_today_rounded), hintText: "dd/mm/aaaa"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            if (_loading)
              const CircularProgressIndicator()
            else
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
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  child: Text("SALVAR ALTERAÇÕES", style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
