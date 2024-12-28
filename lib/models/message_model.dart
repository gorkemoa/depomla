// lib/models/message_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final int createdAt;
  final String? type;
  final String? listingId;
  final bool isRead;
  final String? receiverId;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.type,
    this.listingId,
    this.isRead = false,
    this.receiverId,
  });

  // Firestore için
  factory Message.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
      type: data['type'],
      listingId: data['listingId'],
      isRead: data['isRead'] ?? false,
      receiverId: data['receiverId'],
    );
  }

  // Realtime Database için
  factory Message.fromMap(Map<dynamic, dynamic> map, String id) {
    return Message(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] ?? 0,
      type: map['type'],
      listingId: map['listingId'],
      isRead: map['isRead'] ?? false,
      receiverId: map['receiverId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': createdAt,
      'type': type,
      'listingId': listingId,
      'isRead': isRead,
      'receiverId': receiverId,
    };
  }
}