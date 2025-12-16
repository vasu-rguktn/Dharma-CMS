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
}
