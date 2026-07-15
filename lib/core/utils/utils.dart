import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) return;

    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = 
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Lógica quando o usuário clica na notificação
      },
    );

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Salva o token do dispositivo para o usuário logado
      _saveDeviceToken();

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', 
        'Notificações Importantes',
        description: 'Este canal é usado para notificações cruciais do sistema.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: android.smallIcon,
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });
    }
  }

  static Future<void> _saveDeviceToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      String? uid = FirebaseAuth.instance.currentUser?.uid;

      if (token != null && uid != null) {
        await FirebaseFirestore.instance.collection('tecnicos').doc(uid).set({
          'fcm_token': token,
          'ultima_interacao': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("FCM Token salvo com sucesso.");
      }
    } catch (e) {
      debugPrint("Erro ao salvar FCM Token: $e");
    }
  }

  static Future<void> showLocalNotification({required String title, required String body}) async {
    if (kIsWeb) return;
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel', 
      'Notificações Importantes',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotifications.show(id: 0, title: title, body: body, notificationDetails: platformChannelSpecifics);
  }

  static Future<void> clearNotifications() async {
    await _localNotifications.cancelAll();
  }
}

class DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    // Se o usuário estiver apagando, não faz nada
    if (newValue.selection.baseOffset == 0 || text.length < oldValue.text.length) {
      return newValue;
    }

    var buffer = StringBuffer();
    // Limpa qualquer barra que já exista para evitar duplicação (o bug das mil barras)
    var cleanText = text.replaceAll('/', '');
    
    for (int i = 0; i < cleanText.length; i++) {
      buffer.write(cleanText[i]);
      var index = i + 1;
      
      // Limita a 8 dígitos (DDMMAAAA)
      if (index >= 8) break;

      // Adiciona a barra nas posições 2 e 4
      if (index == 2 || index == 4) {
        if (index < cleanText.length) {
          buffer.write('/');
        }
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}
