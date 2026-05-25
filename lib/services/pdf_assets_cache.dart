import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Singleton — يتحمل مرة واحدة عند بداية الـ app ويفضل في الميموري
class PdfAssetsCache {
  PdfAssetsCache._();
  static final PdfAssetsCache instance = PdfAssetsCache._();

  pw.MemoryImage? bgInvoiceImage;
  pw.Font? cairoRegular;
  pw.Font? cairoBold;

  bool get isLoaded =>
      bgInvoiceImage != null && cairoRegular != null && cairoBold != null;

  Future<void> preload() async {
    if (isLoaded) return; // مش هيتحمل تاني لو موجود

    final results = await Future.wait([
      rootBundle.load('assets/images/to-pdf.png'),
      rootBundle.load('assets/fonts/cairo/Cairo-Regular.ttf'),
      rootBundle.load('assets/fonts/cairo/Cairo-Bold.ttf'),
    ]);

    bgInvoiceImage = pw.MemoryImage(results[0].buffer.asUint8List());
    cairoRegular = pw.Font.ttf(results[1]);
    cairoBold = pw.Font.ttf(results[2]);
  }
}
