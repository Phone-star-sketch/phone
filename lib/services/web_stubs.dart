// This file provides stub implementations for dart:html members.
// It is used for conditional imports on non-web platforms.

// A dummy class to stand in for html.Blob
class Blob {
  Blob(List<Object> parts, [String? type, String? endings]);
}

// A dummy class to stand in for html.Url
class Url {
  static String createObjectUrlFromBlob(Blob blob) => throw UnsupportedError(
      'createObjectUrlFromBlob is only available on the web.');
  static void revokeObjectUrl(String url) =>
      throw UnsupportedError('revokeObjectUrl is only available on the web.');
}

// A dummy class to stand in for html.AnchorElement
class AnchorElement {
  String? href;

  AnchorElement({this.href});

  void setAttribute(String name, String value) {}
  void click() {}
  void remove() {}
}

// A dummy class to stand in for html.document
class _Document {
  _Body? body;
  _Document() {
    body = _Body();
  }
}

class _Body {
  void append(AnchorElement element) {}
}

final _Document document = _Document();

// Removed duplicate 'document' declaration to resolve the error.
