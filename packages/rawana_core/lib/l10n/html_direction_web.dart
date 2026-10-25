import 'dart:html' as html;

/// Keeps the host document in sync with Dari/Pashto so web overlays,
/// text fields, and CSS logical properties follow RTL.
void syncDocumentDirection({required String languageCode, required bool rtl}) {
  final dir = rtl ? 'rtl' : 'ltr';
  final root = html.document.documentElement;
  if (root != null) {
    root.dir = dir;
    root.lang = languageCode;
    root.setAttribute('dir', dir);
    root.setAttribute('lang', languageCode);
  }
  final body = html.document.body;
  if (body != null) {
    body.dir = dir;
    body.setAttribute('dir', dir);
  }
}
