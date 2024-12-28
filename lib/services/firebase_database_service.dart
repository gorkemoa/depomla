// lib/services/firebase_database_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../models/listing_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class FirebaseDatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase database = FirebaseDatabase.instance;

  // Chat verisini alma
  Future<Map<String, dynamic>?> getChatData(String chatId) async {
    try {
      final chatRef = database.ref("chats/$chatId");
      final snapshot = await chatRef.get();
      if (snapshot.exists) {
        final data = snapshot.value;
        print('Chat data exists for chatId $chatId: $data');
        if (data is Map<dynamic, dynamic>) {
          return data.map((key, value) => MapEntry(key.toString(), value));
        } else {
          throw Exception('Chat verisi beklenen formatta değil.');
        }
      } else {
        print('Chat verisi bulunamadı for chatId: $chatId');
        throw Exception('Chat verisi bulunamadı.');
      }
    } catch (e) {
      print('Hata getChatData: $e');
      throw e;
    }
  }

  // Kullanıcı verisini alma
  Future<UserModel?> getUserById(String userId) async {
    try {
      final userRef = database.ref("users/$userId");
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        final data = snapshot.value;
        print('User data exists for userId $userId: $data');
        if (data is Map<dynamic, dynamic>) {
          return UserModel.fromMap(data.map((key, value) => MapEntry(key.toString(), value)), userId);
        } else {
          throw Exception('Kullanıcı verisi beklenen formatta değil.');
        }
      } else {
        throw Exception('Kullanıcı verisi bulunamadı.');
      }
    } catch (e) {
      print('Hata getUserById: $e');
      throw e;
    }
  }

  // Mesaj gönderme
  Future<void> sendMessage(String chatId, Map<String, dynamic> messageData) async {
    try {
      final messagesRef = database.ref("chats/$chatId/messages");
      await messagesRef.push().set(messageData);
      print('Mesaj başarıyla gönderildi.');
    } catch (e) {
      print('Hata sendMessage: $e');
      throw e;
    }
  }

  // İlan verisini alma
  Future<Listing?> getListingById(String listingId) async {
    try {
      final listingRef = database.ref("listings/$listingId");
      final snapshot = await listingRef.get();
      if (snapshot.exists) {
        print('Listing data exists for listingId $listingId: ${snapshot.value}');
        return Listing.fromMap(snapshot.value as Map<dynamic, dynamic>, listingId);
      } else {
        throw Exception('İlan verisi bulunamadı.');
      }
    } catch (e) {
      print('Hata getListingById: $e');
      throw e;
    }
  }

  // Mesaj güncelleme (isRead gibi)
  Future<void> updateMessage(String chatId, String messageId, Map<String, dynamic> updateData) async {
    try {
      final messageRef = database.ref("chats/$chatId/messages/$messageId");
      await messageRef.update(updateData);
      print('Mesaj başarıyla güncellendi.');
    } catch (e) {
      print('Hata updateMessage: $e');
      throw e;
    }
  }

  // Chat güncelleme (lastMessageTime vb.)
  Future<void> updateChat(String chatId, Map<String, dynamic> chatData) async {
    try {
      final chatRef = database.ref("chats/$chatId");
      await chatRef.update(chatData);
      print('Chat başarıyla güncellendi.');
    } catch (e) {
      print('Hata updateChat: $e');
      throw e;
    }
  }

  // Mesajları dinleme
  Stream<List<Message>> getMessages(String chatId) {
    final messagesRef = database.ref("chats/$chatId/messages").orderByChild("createdAt");
    return messagesRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.entries.map((entry) {
        final message = Message.fromMap(entry.value as Map<dynamic, dynamic>, entry.key.toString());
        return message;
      }).toList();
    });
  }

  // Chat verisini dinleme
  Stream<Chat?> getChat(String chatId) {
    final chatRef = database.ref("chats/$chatId");
    return chatRef.onValue.map((event) {
      if (event.snapshot.exists) {
        return Chat.fromMap(event.snapshot.value as Map<dynamic, dynamic>, chatId);
      } else {
        return null;
      }
    });
  }

  // İki kullanıcı arasındaki chatId'yi bulma
  Future<String?> findChatId(String currentUserId, String otherUserId) async {
    try {
      final chatsRef = database.ref("chats");
      final snapshot = await chatsRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        data.forEach((chatId, chatData) {
          final participants = chatData['participants'] as Map<dynamic, dynamic>?;

          if (participants != null &&
              participants.containsKey(currentUserId) &&
              participants.containsKey(otherUserId)) {
            // Chat bulunursa chatId'yi döndür
            print('Chat found for currentUserId $currentUserId and otherUserId $otherUserId: $chatId');}
        });
      }

      // Chat bulunamazsa null döndür
      return null;
    } catch (e) {
      print('Hata findChatId: $e');
      return null;
    }
  }
}