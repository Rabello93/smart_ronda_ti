import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:smart_ronda_ti/app/app.dart';
import 'package:smart_ronda_ti/core/utils/utils.dart';
import 'package:smart_ronda_ti/firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Recebida mensagem em background: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await NotificationService.initialize();
    }
  } catch (e) {
    debugPrint("Erro ao inicializar o Firebase: $e");
  }
  runApp(const RondaTIApp());
}
