import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/services/pdf_assets_cache.dart';

class MonthlyInvoicePdf extends StatefulWidget {
  final List<Client> clients;
  const MonthlyInvoicePdf({super.key, required this.clients});

  @override
  State<MonthlyInvoicePdf> createState() => _MonthlyInvoicePdfState();
}

class _MonthlyInvoicePdfState extends State<MonthlyInvoicePdf> {
  final ctrl = Get.find<AccountClientInfo>();

  bool _assetsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final cache = PdfAssetsCache.instance;
    if (!cache.isLoaded) await cache.preload();
    if (mounted) setState(() => _assetsLoaded = true);
  }

  Future<Uint8List> _buildPdf() async {
    final cache = PdfAssetsCache.instance;
    final pdf = pw.Document();

    const pageWidth = 210.0;
    const pageHeight = 297.0;

    final now = DateTime.now();
    const months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'إبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];

    final total = widget.clients
        .fold<double>(0, (s, c) => s + c.totalCash.abs().toDouble());

    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    // text, x_mm, y_mm, fontSize, bold
    final items = <Map<String, dynamic>>[
      {
        'text': 'شهر ${months[now.month]} لسنة ${now.year}',
        'x': 93.5,
        'y': 35.6,
        'fs': 16.0,
        'bold': true
      },
      {
        'text': '${now.year}/$month/$day',
        'x': 175.0,
        'y': 35.2,
        'fs': 15.0,
        'bold': true
      },
      {
        'text': '${total.toStringAsFixed(0)} جنيه',
        'x': 107.1,
        'y': 114.4,
        'fs': 33.0,
        'bold': true
      },
      {
        'text': '${widget.clients.length}',
        'x': 37.4,
        'y': 113.2,
        'fs': 27.0,
        'bold': true
      },
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.Image(cache.bgInvoiceImage!, fit: pw.BoxFit.fill),
            ),
            ...items.map((e) => pw.Positioned(
                  left: (e['x'] as double) / pageWidth * PdfPageFormat.a4.width,
                  top:
                      (e['y'] as double) / pageHeight * PdfPageFormat.a4.height,
                  child: pw.Text(
                    e['text'] as String,
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(
                      font: (e['bold'] as bool)
                          ? cache.cairoBold
                          : cache.cairoRegular,
                      fontSize: e['fs'] as double,
                      color: PdfColor.fromHex('CBA175'),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    if (!_assetsLoaded) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('طباعة الفاتورة الشهرية',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('طباعة الفاتورة الشهرية',
            style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: (_) => _buildPdf(),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        pdfFileName: 'فاتورة_شهرية.pdf',
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
