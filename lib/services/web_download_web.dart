// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation — triggers a browser file download.
void downloadFile(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes], 'text/plain');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
