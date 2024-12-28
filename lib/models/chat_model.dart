// lib/models/chat_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants;
  final String listingId;
  final int createdAt;
  final bool isHidden;
  final int lastMessageTime;

  Chat({
    required this.id,
    required this.participants,
    required this.listingId,
    required this.createdAt,
    required this.isHidden,
    required this.lastMessageTime,
  });

  // Firestore için
  factory Chat.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Chat(
      id: doc.id,
      participants: List<String>.from(data['participants']),
      listingId: data['listingId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
      isHidden: data['isHidden'] ?? false,
      lastMessageTime: (data['lastMessageTime'] as Timestamp).millisecondsSinceEpoch,
    );
  }

  // Realtime Database için
  factory Chat.fromMap(Map<dynamic, dynamic> map, String id) {
    return Chat(
      id: id,
      participants: List<String>.from(map['participants'].keys),
      listingId: map['listingId'] ?? '',
      createdAt: map['createdAt'] ?? 0,
      isHidden: map['isHidden'] ?? false,
      lastMessageTime: map['lastMessageTime'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants.asMap().map((index, value) => MapEntry(value, true)),
      'listingId': listingId,
      'createdAt': createdAt,
      'isHidden': isHidden,
      'lastMessageTime': lastMessageTime,
    };
  }
}