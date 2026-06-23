import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:smart_ronda_ti/app/app.dart';
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
