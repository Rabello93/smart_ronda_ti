import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:smart_ronda_ti/features/auth/controllers/auth_controller.dart';
import 'package:smart_ronda_ti/features/admin/controllers/admin_controller.dart';
import 'package:smart_ronda_ti/features/auth/models/user_model.dart';
import 'package:smart_ronda_ti/features/auth/pages/login_page.dart';
import 'package:smart_ronda_ti/features/rounds/pages/home_page.dart';
import 'package:smart_ronda_ti/features/dashboard/pages/dashboard_page.dart';
import 'package:smart_ronda_ti/core/utils/utils.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Recebida mensagem em background: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDw-u4mUVBhSpi0GjlrzO5vQvAenuK3dfo",
          authDomain: "smart-ronda-ti.firebaseapp.com",
          projectId: "smart-ronda-ti",
          storageBucket: "smart-ronda-ti.firebasestorage.app",
          messagingSenderId: "48533325947",
          appId: "1:48533325947:web:75bb72f1082f026309bade",
          measurementId: "G-B3YT7JNG29",
        ),
      );
    } else {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await NotificationService.initialize();
    }
  } catch (e) {
    debugPrint("Erro ao inicializar o Firebase: $e");
  }
  runApp(const RondaTIApp());
}

class RondaTIApp extends StatefulWidget {
  const RondaTIApp({super.key});

  static RondaTIAppState of(BuildContext context) =>
      context.findAncestorStateOfType<RondaTIAppState>()!;

  @override
  State<RondaTIApp> createState() => RondaTIAppState();
}

class RondaTIAppState extends State<RondaTIApp> {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Ronda TI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: AuthWrapper(themeMode: _themeMode, onChangeTheme: changeTheme),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final ThemeMode themeMode;
  final Function(ThemeMode) onChangeTheme;
  const AuthWrapper({super.key, required this.themeMode, required this.onChangeTheme});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = AuthController();
    final AdminController adminController = AdminController();
    
    return StreamBuilder(
      stream: authController.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData) {
          return StreamBuilder<UserModel?>(
            stream: authController.profileStream,
            builder: (context, profileSnap) {
              if (profileSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              
              final usuario = profileSnap.data;
              
              if (usuario == null) {
                return const HomePage();
              }
              
              // REGRA DE BLOQUEIO: Se o usuário não estiver ativo, mostra tela de pendente
              if (usuario.ativo == false) {
                return Scaffold(
                  body: StreamBuilder<DocumentSnapshot>(
                    stream: adminController.brandingStream,
                    builder: (context, configSnap) {
                      String logoUrl = "";
                      bool useLocalLogo = true;
                      
                      if (configSnap.hasData && configSnap.data!.exists) {
                        final config = configSnap.data!.data() as Map<String, dynamic>;
                        logoUrl = config['logo_url'] ?? "";
                        if (logoUrl.isNotEmpty) {
                          useLocalLogo = false;
                          if (logoUrl.contains("drive.google.com")) {
                            final fileId = RegExp(r"d/(.+)/").firstMatch(logoUrl)?.group(1) ?? RegExp(r"id=(.+)").firstMatch(logoUrl)?.group(1);
                            if (fileId != null) logoUrl = "https://docs.google.com/uc?export=download&id=$fileId";
                          }
                        }
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (useLocalLogo)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 30),
                                child: Image.asset("assets/logo.png", height: 100, errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 80, color: Colors.blue)),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(bottom: 30),
                                child: Image.network(logoUrl, height: 80, errorBuilder: (_, __, ___) => Image.asset("assets/logo.png", height: 80)),
                              ),
                            
                            const SizedBox(height: 10),
                            const Text(
                              "Acesso Pendente", 
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Seu cadastro foi realizado com sucesso! Por favor, aguarde a liberação de acesso para entrar no sistema.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            const SizedBox(height: 40),
                            ElevatedButton(
                              onPressed: () => authController.logout(),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 50),
                                backgroundColor: Colors.blue.shade900,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("VOLTAR PARA LOGIN"),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                );
              }

              if (usuario.nivelAcesso == 'espectador') {
                return DashboardPage(themeMode: themeMode, onChangeTheme: onChangeTheme);
              }

              return kIsWeb 
                ? DashboardPage(themeMode: themeMode, onChangeTheme: onChangeTheme) 
                : const HomePage();
            }
          );
        }

        return const LoginPage();
      },
    );
  }
}
