// lib/services/chat_service.dart

String generateChatId(String userId1, String userId2) {
  return userId1.compareTo(userId2) < 0 ? '$userId1\_$userId2' : '$userId2\_$userId1';
}