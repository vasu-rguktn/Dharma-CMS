import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ConsentPdfViewer extends StatefulWidget {
  final String assetPath;
  final String title;

  const ConsentPdfViewer({
    super.key,
    required this.assetPath,
    required this.title,
  });

  @override
  State<ConsentPdfViewer> createState() => _ConsentPdfViewerState();
}

class _ConsentPdfViewerState extends State<ConsentPdfViewer> {
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: const Color(0xFFFC633C),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                const Text('Try stopping and re-running the app (Cold Restart).'),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFFFC633C),
        foregroundColor: Colors.white,
      ),
      body: SfPdfViewer.asset(
        widget.assetPath,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          debugPrint('❌ Syncfusion PDF Error: ${details.error}');
          debugPrint('❌ Description: ${details.description}');
          setState(() {
            _errorMessage = 'PDF File Corrupted or Invalid.\n${details.description}';
          });
        },
      ),
    );
  }
}
