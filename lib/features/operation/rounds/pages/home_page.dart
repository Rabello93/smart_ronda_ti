import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_ronda_ti/app/app.dart';
import 'package:smart_ronda_ti/core/utils/utils.dart';
import 'package:smart_ronda_ti/features/management/dashboard/pages/dashboard_page.dart';
import 'package:smart_ronda_ti/features/system/auth/controllers/auth_controller.dart';
import 'package:smart_ronda_ti/features/operation/rounds/pages/ronda_page.dart';
import 'package:smart_ronda_ti/features/operation/rounds/pages/history/history_page.dart';
import 'package:smart_ronda_ti/features/system/about/pages/about_page.dart';
import 'package:smart_ronda_ti/features/system/notifications/pages/notifications_page.dart';
import 'package:smart_ronda_ti/features/management/admin/pages/admin_page.dart';
import 'package:smart_ronda_ti/features/management/admin/controllers/admin_controller.dart';
import 'package:smart_ronda_ti/features/system/auth/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _authController = AuthController();
  final AdminController _adminController = AdminController();
  int _selectedIndex = 0;
  StreamSubscription? _userSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationListener() {
    // Monitora novos cadastros pendentes para notificar Master/Gerente (em foreground)
    _authController.profileStream.listen((user) {
      if (user != null && (user.isAdmin)) {
        _userSubscription?.cancel();
        _userSubscription = FirebaseFirestore.instance
            .collection('tecnicos')
            .where('ativo', isEqualTo: false)
            .snapshots()
            .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data() as Map<String, dynamic>;
              NotificationService.showLocalNotification(
                title: "🆕 Novo Cadastro Pendente",
                body: "O usuário ${data['nome'] ?? 'Desconhecido'} acabou de se registrar e aguarda aprovação.",
              );
            }
          }
        });
      }
    });
  }

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
              const BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alertas"),
              if (isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
            ],
          ),
          persistentFooterButtons: const [
            Center(
              child: Text(
                "Smart Ronda TI - v3.2.4",
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
      case 2: return const NotificationsPage();
      case 3: return isAdmin ? const AdminPage() : const HistoryPage();
      default: return const HistoryPage();
    }
  }
}
