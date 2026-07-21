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
import 'package:smart_ronda_ti/features/operation/rounds/controllers/round_controller.dart';
import 'package:smart_ronda_ti/features/management/dashboard/controllers/dashboard_controller.dart';
import 'package:smart_ronda_ti/shared/widgets/dashboard_widgets.dart';
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
  final RoundController _roundController = RoundController();
  final DashboardController _dashboardController = DashboardController();
  int _selectedIndex = 0;
  StreamSubscription? _userSubscription;
  StreamSubscription? _inactiveDepSubscription;
  List<String> _departmentAlerts = [];

  bool _hasShownInactiveAlert = false;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
    _setupInactiveDepartmentListener();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _inactiveDepSubscription?.cancel();
    super.dispose();
  }

  void _setupInactiveDepartmentListener() {
    _inactiveDepSubscription = _adminController.sectorsStream.listen((setores) {
      _roundController.getHistoryStream().first.then((rondas) {
        final alerts = _dashboardController.getInactiveDepartmentAlerts(rondas, setores);
        if (mounted) {
          setState(() => _departmentAlerts = alerts);
          
          if (alerts.isNotEmpty && !_hasShownInactiveAlert) {
            NotificationService.showLocalNotification(
              title: "⚠️ Auditoria Pendente",
              body: "Existem ${alerts.length} departamentos precisando de ronda (há mais de 15 dias).",
            );
            _hasShownInactiveAlert = true; // Mostra apenas uma vez por sessão
          }
        }
      });
    });
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
            title: Text("SMART RONDA", style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1)),
            backgroundColor: isAdmin ? AppTheme.deepNavy : Colors.blue.shade900,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 20),
                onPressed: () => _authController.logout(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _buildBody(_selectedIndex, isAdmin, user),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: isAdmin ? AppTheme.cyanNeon : Colors.blue.shade900,
            unselectedItemColor: Colors.grey,
            backgroundColor: isAdmin ? AppTheme.charcoal : Colors.white,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            onTap: (index) => setState(() => _selectedIndex = index),
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: "Ronda"),
              const BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "Histórico"),
              const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_motion_rounded), label: "Alertas"),
              if (isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.security_rounded), label: "Admin"),
            ],
          ),
          persistentFooterButtons: [
            Center(
              child: Text(
                "Smart Ronda TI - v3.2.9",
                style: AppTheme.monoStyle(fontSize: 9, color: Colors.grey),
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
        return SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_departmentAlerts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CriticalAlertBanner(alerts: _departmentAlerts),
                ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.electricBlue, AppTheme.cyanNeon],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.electricBlue.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _iniciarRonda(user),
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: const Text("INICIAR NOVA RONDA"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(280, 70),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    textStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 25),
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
                  icon: const Icon(Icons.analytics_rounded),
                  label: const Text("DASHBOARD ESTRATÉGICO"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(280, 55),
                    side: const BorderSide(color: AppTheme.cyanNeon, width: 2),
                    foregroundColor: AppTheme.cyanNeon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
              const SizedBox(height: 40),
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
