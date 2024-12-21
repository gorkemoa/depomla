// lib/main.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:depomla/models/listing_model.dart';
import 'package:depomla/models/user_model.dart';
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
import 'package:provider/provider.dart';
import 'services/notification_service.dart'; // Bildirim servisini içe aktar

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  // Bildirim servisini başlat
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        StreamProvider<User?>.value(
          value: AuthService().authStateChanges(),
          initialData: null,
          catchError: (context, error) => null,
        ),
        // Diğer sağlayıcılar...
      ],
      child: const DepomlaApp(),
    ),
  );
}

// Bildirim seçildiğinde çalışacak fonksiyon
Future selectNotification(NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  if (payload != null) {
    // ChatPage'e yönlendirme işlemi burada hallediliyor.
    // Ancak bu işlev NotificationService içinde zaten ele alınıyor.
    // Dolayısıyla burada ekstra bir işlem yapmanıza gerek yok.
  }
}

class DepomlaApp extends StatefulWidget {
  const DepomlaApp({Key? key}) : super(key: key);

  @override
  State<DepomlaApp> createState() => _DepomlaAppState();
}

class _DepomlaAppState extends State<DepomlaApp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatsSubscription;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _messagesSubscriptions = {};

  @override
  void initState() {
    super.initState();
    // Kullanıcı oturum açtığında mesajları dinlemeye başla
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToNewMessages(user.uid);
      } else {
        // Kullanıcı çıkış yaptığında tüm dinleyicileri iptal et
        _messagesSubscriptions.forEach((chatId, subscription) {
          subscription.cancel();
        });
        _messagesSubscriptions.clear();
      }
    });
  }

  void _listenToNewMessages(String userId) {
    // Kullanıcının dahil olduğu tüm sohbetleri dinle
    _chatsSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((chatSnapshot) {
      for (var chatDoc in chatSnapshot.docs) {
        final chatId = chatDoc.id;

        // Eğer daha önce dinlenmeyen bir sohbetse, dinleyici ekle
        if (!_messagesSubscriptions.containsKey(chatId)) {
          _messagesSubscriptions[chatId] = _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .snapshots()
              .listen((messageSnapshot) {
            if (messageSnapshot.docs.isNotEmpty) {
              final messageData = messageSnapshot.docs.first.data();
              final senderId = messageData['senderId'] as String?;
              final receiverId = messageData['receiverId'] as String?;
              final isRead = messageData['isRead'] as bool? ?? false;
              final text = messageData['text'] as String? ?? '';

              // Kendi gönderdiğiniz mesajları bildirimde göstermeyin
              if (senderId != userId && receiverId == userId && !isRead) {
                // Kullanıcı bilgilerini al
                _firestore.collection('users').doc(senderId).get().then((userDoc) {
                  if (userDoc.exists) {
                    final user = UserModel.fromDocument(userDoc);
                    final senderName = user.displayName ?? 'Yeni Mesaj';
                    final senderPhotoUrl = user.photoURL ?? '';

                    // Bildirim göster
                    NotificationService().showNotification(
                      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      title: senderName,
                      body: text,
                      payload: chatId, // Chat ID payload olarak gönderiliyor
                    );
                  }
                }).catchError((e) {
                  print('Kullanıcı verisi alınırken hata: $e');
                });
              }
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _messagesSubscriptions.forEach((chatId, subscription) {
      subscription.cancel();
    });
    _messagesSubscriptions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcının oturum durumunu dinleyin
    Provider.of<User?>(context);

    return MaterialApp(
      navigatorKey: navigatorKey, // Global navigator key'i ata
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