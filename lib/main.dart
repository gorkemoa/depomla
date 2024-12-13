// lib/main.dart
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:depomla/models/listing_model.dart';
import 'package:depomla/notifications_page.dart';
import 'package:depomla/pages/auth_page/login_page.dart';
import 'package:depomla/pages/auth_page/post_login_page.dart';
import 'package:depomla/pages/listing_page/listings_page.dart';
import 'package:depomla/pages/profil_page/profile_page.dart';
import 'package:depomla/pages/splash_page.dart';
import 'package:depomla/services/auth_service.dart';
import 'package:depomla/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'ads/banner_ad_example.dart';


// Route isimlerini sabitler olarak tanımlayın
class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String home = '/home';
  static const String notifications = '/notifications';
  static const String listings = '/listings';
  static const String unknown = '/unknown';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalAdsService().initialize(); // Ads SDK'yı başlat

  // Firebase başlatılması
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase başlatma hatasını ele alın
    print('Firebase başlatma hatası: $e');
  }

  // Firestore ayarları
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Google Mobile Ads SDK'yi başlat

  // Flutter Local Notifications başlatılması
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  // Android için Bildirim Kanalı oluşturma
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'Yüksek Öncelikli Bildirimler', // title
    description:
        'Bu kanal önemli bildirimler için kullanılır.', // description
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: selectNotification,
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
  // Örneğin, bir dialog gösterilebilir
  // Ancak bu örnekte boş bırakılmıştır
}

// Bildirim seçildiğinde çalışacak fonksiyon
Future selectNotification(NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  if (payload != null) {
    // Payload'a göre yönlendirme işlemleri
    // Örneğin:
    // Navigator.of(context).pushNamed('/notifications');
  }
}

class DepomlaApp extends StatelessWidget {
  const DepomlaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Kullanıcının oturum durumunu dinleyin
    final user = Provider.of<User?>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Depomla',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (context) => const SplashScreen(),
        Routes.login: (context) => const LoginPage(),
        Routes.profile: (context) => const ProfilePage(),
        Routes.home: (context) => const PostLoginPage(),
        Routes.notifications: (context) => NotificationsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == Routes.listings) {
          final args = settings.arguments as ListingType;
          return MaterialPageRoute(
            builder: (context) {
              return ListingsPage(category: args);
            },
          );
        }
        // Diğer özel route tanımlamaları
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Bilinmeyen Sayfa'),
            ),
            body: const Center(
              child: Text('Bu sayfa bulunamadı.'),
            ),
          ),
        );
      },
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            // Örneğin, banner reklam eklemek için aşağıdaki widget'ı kullanabilirsiniz
          ],
        );
      },
    );
  }
}