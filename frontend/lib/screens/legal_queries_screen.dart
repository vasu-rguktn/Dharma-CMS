import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // for Uint8List but usually part of core or typed_data
import 'dart:io' as io; // Prefix to avoid conflict if needed, or check platform
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/legal_queries_provider.dart';
import '../models/chat_message.dart';
import '../screens/geo_camera_screen.dart';

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
  // List of {bytes: Uint8List, name: String}
  final List<Map<String, dynamic>> _attachments = [];

  @override
  void initState() {
    super.initState();
    print('🎬 [LEGAL_QUERIES] Screen initialized (initState)');
  }

  @override
  void dispose() {
    print('🗑️ [LEGAL_QUERIES] Screen disposed (navigating away)');
    super.dispose();
  }

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
    if (text.isEmpty && _attachments.isEmpty) return;

    final lang = Localizations.localeOf(context).languageCode;

    context.read<LegalQueriesProvider>().sendMessage(text,
        attachments: List.from(_attachments), language: lang);

    _controller.clear();
    setState(() {
      _attachments.clear();
    });
  }

  /* ---------------- ATTACHMENTS ---------------- */
  void _pickImages(ImageSource source) async {
    if (source == ImageSource.camera) {
      // Use Geo-Camera for evidence capture
      final XFile? geoTaggedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const GeoCameraScreen(
            captureMode: CaptureMode.image,
          ),
        ),
      );
      
      if (geoTaggedImage != null) {
        final bytes = await geoTaggedImage.readAsBytes();
        setState(() {
          _attachments.add({'bytes': bytes, 'name': geoTaggedImage.name});
        });
      }
    } else {
      // Internal gallery allows multiple
      final List<XFile> pickedList = await _imagePicker.pickMultiImage();
      if (pickedList.isNotEmpty) {
        for (var picked in pickedList) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _attachments.add({'bytes': bytes, 'name': picked.name});
          });
        }
      }
    }
  }

  void _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Crucial for Web
      allowMultiple: true,
    );
    if (result != null) {
      for (var file in result.files) {
        Uint8List? bytes;

        if (kIsWeb) {
          bytes = file.bytes;
        } else if (file.path != null) {
          // For larger files on mobile, stream might be better, but reading all bytes is ok for small docs
          bytes = await io.File(file.path!).readAsBytes();
        }

        if (bytes != null) {
          setState(() {
            _attachments.add({'bytes': bytes, 'name': file.name});
          });
        }
      }
    }
  }

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
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: orange),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: orange),
                title: const Text("Upload PDF"),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /* ---------------- FILES PREVIEW ---------------- */
  Widget _buildFilePreview() {
    if (_attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _attachments.length,
        itemBuilder: (context, index) {
          final item = _attachments[index];
          final name = item['name'] as String;
          final isImage = name.toLowerCase().endsWith('.jpg') ||
              name.toLowerCase().endsWith('.jpeg') ||
              name.toLowerCase().endsWith('.png');

          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isImage ? Icons.image : Icons.picture_as_pdf,
                  size: 20,
                  color: orange,
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: Colors.orange.shade800, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => setState(() {
                    _attachments.removeAt(index);
                  }),
                  child: Icon(Icons.close,
                      size: 16, color: Colors.orange.shade800),
                )
              ],
            ),
          );
        },
      ),
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
        constraints:
            const BoxConstraints(maxWidth: 600), // Wider for desktop feel
        decoration: BoxDecoration(
          color: isUser ? orange : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUser)
              Text(
                msg.text,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              )
            else
              MarkdownBody(
                data: msg.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 15, color: Colors.black87),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                  code: TextStyle(
                      backgroundColor: Colors.grey.shade100,
                      fontFamily: 'monospace'),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              DateFormat('hh:mm a').format(msg.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: isUser ? Colors.white70 : Colors.grey.shade500,
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

    // Log navigation stack state when screen is built
    print('📱 [LEGAL_QUERIES] Screen built');
    print('📚 [LEGAL_QUERIES] Can pop: ${Navigator.of(context).canPop()}');
    print('📍 [LEGAL_QUERIES] Current route: ${ModalRoute.of(context)?.settings.name ?? "unnamed"}');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: orange,
        title: const Text("Legal Assistant"),
        automaticallyImplyLeading: false, // Disable automatic hamburger menu
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
          onPressed: () {
            print('⬅️ [LEGAL_QUERIES] Back button pressed - navigating to dashboard');
            Navigator.of(context).pop(); // Navigate back to dashboard
          },
        ),
        actions: [
          // History drawer button - opens chat history
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Chat History',
              onPressed: () {
                print('📜 [LEGAL_QUERIES] History button tapped - opening drawer');
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
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
                    print('🗂️ [LEGAL_QUERIES] History StreamBuilder state:');
                    print('   - hasData: ${snapshot.hasData}');
                    print('   - hasError: ${snapshot.hasError}');
                    print('   - error: ${snapshot.error}');
                    print('   - connectionState: ${snapshot.connectionState}');
                    
                    if (snapshot.hasError) {
                      print('❌ [LEGAL_QUERIES] History error: ${snapshot.error}');
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final sessions = snapshot.data!;
                    print('   - sessions count: ${sessions.length}');
                    
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

                // Add reverse: true here
                return ListView.builder(
                  reverse: true, // New messages appear at bottom, existing stay
                  padding: const EdgeInsets.all(16),
                  itemCount: snap.data!.length,
                  itemBuilder: (_, i) => _bubble(snap.data![i]),
                );
              },
            ),
          ),

          // PREVIEW WIDGET
          _buildFilePreview(),

          /* ---------------- INPUT BAR ---------------- */
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ➕ ATTACHMENTS
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.grey.shade600,
                  onPressed: _showAttachmentOptions,
                ),

                // TEXT FIELD
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: RawKeyboardListener(
                      focusNode: FocusNode(), // Simple node for listener
                      onKey: (event) {
                        if (event is RawKeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.enter &&
                              !event.isShiftPressed) {
                            // Prevent default new line? It complicates things.
                            // Better: Users just use the send button or we use onSubmitted
                          }
                        }
                      },
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send, // TRY THIS
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: "Ask a legal question...",
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // MIC
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.grey.shade600,
                  ),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),

                // SEND
                Container(
                  decoration: const BoxDecoration(
                    color: orange,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    color: Colors.white,
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
