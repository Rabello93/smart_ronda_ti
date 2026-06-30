import 'package:flutter/material.dart';
import 'package:smart_ronda_ti/app/app.dart';
import 'package:smart_ronda_ti/features/management/dashboard/pages/dashboard_page.dart';
import 'package:smart_ronda_ti/features/system/auth/controllers/auth_controller.dart';
import 'package:smart_ronda_ti/features/operation/rounds/pages/ronda_page.dart';
import 'package:smart_ronda_ti/features/operation/rounds/pages/history/history_page.dart';
import 'package:smart_ronda_ti/features/system/about/pages/about_page.dart';
import 'package:smart_ronda_ti/features/management/admin/pages/admin_page.dart';
import 'package:smart_ronda_ti/features/management/admin/controllers/admin_controller.dart';
import 'package:smart_ronda_ti/features/system/auth/models/user_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _authController = AuthController();
  final AdminController _adminController = AdminController();
  int _selectedIndex = 0;

  void _iniciarRonda(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Selecione o Setor"),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _adminController.sectorsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final setores = snapshot.data!;
              if (setores.isEmpty) return const Text("Nenhum setor cadastrado. Vá em Admin > Setores.");

              return ListView.builder(
                shrinkWrap: true,
                itemCount: setores.length,
                itemBuilder: (context, index) {
                  final s = setores[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.blue),
                    title: Text(s['nome']),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => RondaPage(
                          setor: s['nome'],
                          tecnico: user.nome,
                          tecnicoId: user.uid,
                        ),
                      ));
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _authController.profileStream,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final bool isAdmin = user.isAdmin;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Smart Ronda TI"),
            backgroundColor: Colors.blue.shade900,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _authController.logout(),
              ),
            ],
          ),
          body: _buildBody(_selectedIndex, isAdmin, user),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue.shade900,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.play_arrow), label: "Ronda"),
              const BottomNavigationBarItem(icon: Icon(Icons.history), label: "Histórico"),
              if (isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
            ],
          ),
          persistentFooterButtons: const [
            const Center(
              child: Text(
                "Smart Ronda TI - v3.2.0",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(int index, bool isAdmin, UserModel user) {
    switch (index) {
      case 0: 
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.checklist_rtl, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _iniciarRonda(user),
                icon: const Icon(Icons.play_arrow),
                label: const Text("INICIAR NOVA RONDA"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 60),
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    final appState = RondaTIApp.of(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DashboardPage(
                        themeMode: appState.themeMode, 
                        onChangeTheme: appState.changeTheme
                      ),
                    ));
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text("DASHBOARD ANALÍTICO"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(250, 50),
                    side: BorderSide(color: Colors.blue.shade900, width: 2),
                    foregroundColor: Colors.blue.shade900,
                  ),
                ),
              ],
            ],
          ),
        );
      case 1: return const HistoryPage();
      case 2: return isAdmin ? const AdminPage() : const HistoryPage();
      default: return const HistoryPage();
    }
  }
}
