import 'package:hive/hive.dart';

part 'chat.g.dart';

@HiveType(typeId: 0)
class ChatSession {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final List<ChatMessageData> messages;
  
  @HiveField(3)
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
  });
}

@HiveType(typeId: 1)
class ChatMessageData {
  @HiveField(0)
  final String text;
  
  @HiveField(1)
  final bool isUser;
  
  @HiveField(2)
  final DateTime timestamp;

  ChatMessageData({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}