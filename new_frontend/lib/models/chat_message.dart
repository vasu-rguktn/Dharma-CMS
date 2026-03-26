class ChatMessage {
  final String sender; // "user" or "ai"
  final String text;
  final DateTime timestamp;
  final String? fileName;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.fileName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['role'] ?? json['sender'] ?? 'user',
      text: json['content'] ?? json['text'] ?? '',
      timestamp: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      fileName: json['fileName'],
    );
  }
}
