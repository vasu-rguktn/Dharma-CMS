import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'sender': 'user',
      });
      _messages.add({
        'text':
            'This is a simulated AI response. Full AI integration requires backend setup.',
        'sender': 'ai',
      });
    });

    _messageController.clear();

    // Auto-scroll to newest message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Placeholder for voice input
  void _startVoiceInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice input coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── 1. SVG BACKGROUND (fixed) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/DashboardFrame.svg',
              width: screenWidth,
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              allowDrawingOutsideViewBox: true,
            ),
          ),

          // ── 2. HEADER TEXT (on SVG) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'AI Legal Assistant',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ask me anything about legal matters',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        height: 1.5,
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black26,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. MESSAGES LIST (scroll under SVG) ──
          Positioned(
            top: 180, // Adjust based on your SVG + header height
            left: 0,
            right: 0,
            bottom: 90, // Space for input bar
            child: ClipRect(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        "Start a conversation...",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final reversedIndex = _messages.length - 1 - index;
                        final message = _messages[reversedIndex];
                        final isUser = message['sender'] == 'user';

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFFFC633C) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              message['text']!,
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // ── 4. INPUT BAR WITH MIC ICON ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Text Field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Color(0xFFFC633C), width: 2),
                        ),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // MIC ICON (Speech Input)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _startVoiceInput,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC633C),
                        shape: const CircleBorder(),
                        elevation: 6,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 24),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // SEND BUTTON
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC633C),
                        shape: const CircleBorder(),
                        elevation: 6,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}