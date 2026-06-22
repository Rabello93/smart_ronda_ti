import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) return;

    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = 
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications.initialize(
      initializationSettings,
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
      String? token = await messaging.getToken();
      debugPrint("FCM Token: $token");

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
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
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
    await _localNotifications.show(0, title, body, platformChannelSpecifics);
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
