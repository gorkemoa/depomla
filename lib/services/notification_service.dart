// lib/services/notification_service.dart

import 'package:flutter/material.dart'; // MaterialPageRoute için gerekli
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../main.dart'; // navigatorKey'i içe aktar
import '../pages/comment_page/chat_page.dart'; // ChatPage'i içe aktar
import '../models/listing_model.dart'; // Listing modelini içe aktar
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> init() async {
    // Zaman dilimlerini başlat
    tz.initializeTimeZones();
    final String? timeZoneName = await tz.local.name;
    if (timeZoneName != null) {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    }

    // Android için bildirim ayarları
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS (Darwin) için bildirim ayarları
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification kaldırıldı
    );

    // Genel bildirim ayarları
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // Bildirim eklentisini başlat
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final String? payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          // Firestore'dan chatId'ye göre veriyi çek ve ChatPage'e yönlendir
          try {
            final chatDoc = await FirebaseFirestore.instance
                .collection('chats')
                .doc(payload)
                .get();

            if (chatDoc.exists) {
              final listingId = chatDoc.data()?['listingId'] as String?;
              if (listingId != null && listingId.isNotEmpty) {
                final listingDoc = await FirebaseFirestore.instance
                    .collection('listings')
                    .doc(listingId)
                    .get();

                if (listingDoc.exists) {
                  final listing = Listing.fromDocument(listingDoc);
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatId: payload,
                        listing: listing,
                      ),
                    ),
                  );
                } else {
                  // İlan bulunamadığında yapılacak işlemler
                  print('İlan bulunamadı: $listingId');
                }
              } else {
                // listingId eksikse yapılacak işlemler
                print('Chat belgesinde listingId bulunamadı.');
              }
            } else {
              // Chat bulunamadığında yapılacak işlemler
              print('Chat bulunamadı: $payload');
            }
          } catch (e) {
            print('ChatPage\'e yönlendirilirken hata: $e');
          }
        }
      },
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'chat_channel', // Kanal ID'si
      'Chat Notifications', // Kanal adı
      channelDescription: 'Yeni mesaj bildirimleri', // Kanal açıklaması
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    final DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails();

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}