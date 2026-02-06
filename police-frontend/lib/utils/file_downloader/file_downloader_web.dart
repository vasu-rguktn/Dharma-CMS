import 'dart:html' as html;

Future<String?> downloadFile(List<int> bytes, String fileName) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);

  // Web downloads don't have a file path, return null
  return null;
}
