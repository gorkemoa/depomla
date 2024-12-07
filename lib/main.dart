// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:depomla/models/listing_model.dart';
import 'package:depomla/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:depomla/pages/auth_page/auth_page.dart';
import 'package:depomla/pages/auth_page/post_login_page.dart';
import 'package:depomla/pages/auth_page/login_page.dart';
import 'package:depomla/pages/profil_page/profile_page.dart';
import 'package:depomla/pages/listing_page/listings_page.dart'; // İlanları gösteren sayfa
import 'package:depomla/services/auth_service.dart';
import 'dart:io' show Platform;

import 'providers/user_provider.dart'; // Platform kontrolü için ekleme

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase başlatılıyor

  // Firestore ayarları
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Yerel bildirimleri başlat
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS Initialization Settings (DarwinInitializationSettings olarak güncellendi)
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  // Tüm platformlar için Initialization Settings
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: selectNotification, // onSelectNotification yerine
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        StreamProvider<User?>.value(
          value: AuthService().authStateChanges(),
          initialData: null,
          catchError: (context, error) => null,
        ),
      ],
      child: const DepomlaApp(),
    ),
  );
}

// iOS'ta yerel bildirim alındığında çalışacak fonksiyon
Future onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) async {
  // iOS için yerel bildirim alındığında yapılacak işlemler
  // Örneğin, kullanıcıya bir dialog gösterilebilir
  // Bu fonksiyon async olarak tanımlanmıştır
}

// Bildirim seçildiğinde çalışacak fonksiyon
Future selectNotification(NotificationResponse notificationResponse) async {
  // Bildirim seçildiğinde yapılacak işlemler
  // Örneğin, belirli bir sayfaya yönlendirme yapılabilir
  final String? payload = notificationResponse.payload;
  if (payload != null) {
    // Payload'a göre yönlendirme işlemleri
  }
}

class DepomlaApp extends StatelessWidget {
  const DepomlaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Depomla',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PostLoginPage(), // Direkt PostLoginPage açılıyor
      onGenerateRoute: (settings) {
        if (settings.name == '/listings') {
          final args = settings.arguments as ListingType;
          return MaterialPageRoute(
            builder: (context) {
              return ListingsPage(category: args);
            },
          );
        }
        // Diğer route tanımlamaları
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginPage());
          case '/profile':
            return MaterialPageRoute(builder: (context) => const ProfilePage());
          case '/home':
            return MaterialPageRoute(builder: (context) => const PostLoginPage());
          case '/notifications':
            return MaterialPageRoute(builder: (context) => NotificationsPage());
          default:
            return MaterialPageRoute(builder: (context) => const ListingsPage(category: ListingType.deposit));
        }
      },
    );
  }
}