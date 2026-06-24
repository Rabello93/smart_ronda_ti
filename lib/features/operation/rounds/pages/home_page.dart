import 'package:flutter/material.dart';
import 'package:smart_ronda_ti/features/system/auth/controllers/auth_controller.dart';
import 'package:smart_ronda_ti/features/operation/rounds/pages/ronda_page.dart';
import 'package:smart_ronda_ti/features/operation/rounds/history/history_page.dart';
import 'package:smart_ronda_ti/features/management/dashboard/pages/dashboard_page.dart';
import 'package:smart_ronda_ti/features/system/about/pages/about_page.dart';
import 'package:smart_ronda_ti/features/management/admin/pages/admin_page.dart';
import 'package:smart_ronda_ti/features/system/auth/models/user_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _authController = AuthController();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _authController.profileStream,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final bool isAdmin = user?.isAdmin ?? false;

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
          body: _buildBody(_selectedIndex, isAdmin),
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
          persistentFooterButtons: [
            Center(
              child: Text(
                "Smart Ronda TI - v${const String.fromEnvironment('APP_VERSION', defaultValue: '3.0.1+Local')}",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(int index, bool isAdmin) {
    switch (index) {
      case 0: return const RondaPage();
      case 1: return const HistoryPage();
      case 2: return isAdmin ? const AdminPage() : const RondaPage();
      default: return const RondaPage();
    }
  }
}
