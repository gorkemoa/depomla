// lib/pages/notifications_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatelessWidget {
  NotificationsPage({Key? key}) : super(key: key);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        backgroundColor: Colors.blueAccent,
      ),
      body: const NotificationList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Bildirim göndermek için fonksiyonu çağırın
          _showLocalNotification(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showLocalNotification(BuildContext context) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channelId',
      'channelName',
      channelDescription: 'channelDescription',
      importance: Importance.max,
      priority: Priority.high,
    );

    // DarwinNotificationDetails kullanıyoruz
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    // NotificationDetails oluşturuyoruz
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Depomla',
      'Sen beklersin de eşyalar bekler mi?',
      notificationDetails,
      payload: 'Depomla Bildirimi',
    );

    // Firestore'a bildirim ekleme
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Depomla',
      'content': 'Sen beklersin de eşyalar bekler mi?',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

class NotificationList extends StatelessWidget {
  const NotificationList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Henüz bir bildirim yok.'));
        }

        final notifications = snapshot.data!.docs;

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final title = notification['title'] as String? ?? 'Başlık Yok';
            final content = notification['content'] as String? ?? 'İçerik Yok';
            final timestamp = notification['timestamp'] as Timestamp?;

            DateTime displayTimestamp;
            if (timestamp != null) {
              displayTimestamp = timestamp.toDate();
            } else {
              // Eğer timestamp null ise, şu anki zamanı kullanabilir veya başka bir işlem yapabilirsiniz.
              displayTimestamp = DateTime.now();
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content),
                    const SizedBox(height: 5),
                    Text(
                      'Gönderildi: ${displayTimestamp.toLocal()}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}