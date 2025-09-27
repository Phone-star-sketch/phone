// Stubs for web-specific APIs when not on web platform

class Blob {
  Blob(List data);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class Element {
  void appendChild(Element child) {}
  void remove() {}
}

class AnchorElement extends Element {
  String? href;
  AnchorElement({this.href});
  void setAttribute(String name, String value) {}
  void click() {}
}

class Document {
  Element? body;
}

Document document = Document();
