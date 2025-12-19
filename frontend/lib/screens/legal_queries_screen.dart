import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/legal_queries_provider.dart';
import '../models/chat_message.dart';

const Color orange = Color(0xFFFC633C);

class LegalQueriesScreen extends StatefulWidget {
  const LegalQueriesScreen({super.key});

  @override
  State<LegalQueriesScreen> createState() => _LegalQueriesScreenState();
}

class _LegalQueriesScreenState extends State<LegalQueriesScreen> {
  final TextEditingController _controller = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isListening = false;

  /* ---------------- VOICE ---------------- */
  Future<void> _startListening() async {
    final available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (r) {
        setState(() => _controller.text = r.recognizedWords);
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  /* ---------------- SEND ---------------- */
  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    context.read<LegalQueriesProvider>().sendMessage(text);
    _controller.clear();
  }

  /* ---------------- ATTACHMENTS ---------------- */
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: orange),
                title: const Text("Take Photo"),
                onTap: () async {
                  Navigator.pop(context);
                  final image =
                      await _imagePicker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    debugPrint("Camera image path: ${image.path}");
                    // TODO: upload image
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: orange),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _imagePicker.pickImage(
                      source: ImageSource.gallery);
                  if (image != null) {
                    debugPrint("Gallery image path: ${image.path}");
                    // TODO: upload image
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file, color: orange),
                title: const Text("Upload File"),
                onTap: () async {
                  Navigator.pop(context);
                  final result =
                      await FilePicker.platform.pickFiles(allowMultiple: false);
                  if (result != null) {
                    debugPrint(
                        "File selected: ${result.files.single.name}");
                    // TODO: upload file
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /* ---------------- CHAT BUBBLE ---------------- */
  Widget _bubble(ChatMessage msg) {
    final isUser = msg.sender == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? orange : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(msg.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: isUser ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LegalQueriesProvider>();

    return Scaffold(
      appBar: AppBar(
  backgroundColor: orange,
  title: const Text("Legal Assistant"),

  leading: Builder(
    builder: (context) => IconButton(
      icon: const Icon(Icons.history), // 👈 CHANGE ICON HERE
      onPressed: () => Scaffold.of(context).openDrawer(),
    ),
  ),
),

      /* ---------------- DRAWER : CHAT HISTORY ---------------- */
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Chat History",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        await context
                            .read<LegalQueriesProvider>()
                            .createNewSession();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: provider.chatSessionsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final sessions = snapshot.data!;
                    if (sessions.isEmpty) {
                      return const Center(
                        child: Text("No previous chats"),
                      );
                    }

                    return ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (_, index) {
                        final session = sessions[index];
                        return ListTile(
                          leading: const Icon(Icons.chat),
                          title: Text(session['title']),
                          onTap: () {
                            context
                                .read<LegalQueriesProvider>()
                                .openSession(session['id']);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      /* ---------------- BODY ---------------- */
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: provider.messagesStream(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: Text("Ask your legal question"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snap.data!.length,
                  itemBuilder: (_, i) => _bubble(snap.data![i]),
                );
              },
            ),
          ),

          /* ---------------- INPUT BAR ---------------- */
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: [
                // ➕ ATTACHMENTS
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: orange,
                  onPressed: _showAttachmentOptions,
                ),

                // TEXT FIELD
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Ask a legal question...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                // MIC
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: orange,
                  ),
                  onPressed:
                      _isListening ? _stopListening : _startListening,
                ),

                // SEND
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  color: Colors.white,
                  style:
                      IconButton.styleFrom(backgroundColor: orange),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
