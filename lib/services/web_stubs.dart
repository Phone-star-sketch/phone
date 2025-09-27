// Web stub implementations for non-web platforms

class Blob {
  Blob(List<dynamic> data);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) {
    throw UnsupportedError('Web operations not supported on this platform');
  }

  static void revokeObjectUrl(String url) {
    throw UnsupportedError('Web operations not supported on this platform');
  }
}

class AnchorElement {
  AnchorElement({String? href});

  void setAttribute(String name, String value) {
    throw UnsupportedError('Web operations not supported on this platform');
  }

  void click() {
    throw UnsupportedError('Web operations not supported on this platform');
  }

  void remove() {
    throw UnsupportedError('Web operations not supported on this platform');
  }
}

class Document {
  Body? get body => null;
}

class Body {
  void appendChild(dynamic element) {
    throw UnsupportedError('Web operations not supported on this platform');
  }
}

final document = Document();
