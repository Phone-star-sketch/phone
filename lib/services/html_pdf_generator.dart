// HTML to PDF Generator - Alternative faster solution
// Uncomment and use if you want to try HTML to PDF approach

/*
import 'dart:io';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class HtmlPdfGenerator {
  /// Generate PDF from HTML for dues report
  static Future<File> generateDuesPdf({
    required List<Map<String, dynamic>> dues,
    required String monthName,
    String? customFileName,
  }) async {
    // Calculate totals
    final totalAmount = dues.fold<double>(0.0, (sum, due) {
      final amount = due['amount'];
      if (amount is num) {
        return sum + amount.toDouble();
      }
      return sum;
    });
    
    final totalCount = dues.length;

    // Build HTML content
    final htmlContent = '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>كشف المستحقات - $monthName</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: 'Cairo', 'Arial', sans-serif;
      direction: rtl;
      padding: 20px;
      background: #fff;
    }
    
    .header {
      text-align: center;
      margin-bottom: 30px;
      padding: 20px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border-radius: 10px;
    }
    
    .header h1 {
      font-size: 28px;
      margin-bottom: 10px;
    }
    
    .header .date {
      font-size: 16px;
      opacity: 0.9;
    }
    
    .summary {
      display: flex;
      justify-content: space-around;
      margin-bottom: 30px;
      padding: 20px;
      background: #f8f9fa;
      border-radius: 10px;
      border: 2px solid #667eea;
    }
    
    .summary-item {
      text-align: center;
    }
    
    .summary-label {
      font-size: 14px;
      color: #666;
      margin-bottom: 5px;
    }
    
    .summary-value {
      font-size: 24px;
      font-weight: bold;
      color: #667eea;
    }
    
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 20px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    
    thead {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
    }
    
    th {
      padding: 15px;
      text-align: center;
      font-weight: bold;
      font-size: 16px;
    }
    
    tbody tr {
      border-bottom: 1px solid #e0e0e0;
    }
    
    tbody tr:nth-child(even) {
      background-color: #f8f9fa;
    }
    
    tbody tr:hover {
      background-color: #e3f2fd;
    }
    
    td {
      padding: 12px;
      text-align: center;
      font-size: 14px;
    }
    
    .amount {
      font-weight: bold;
      color: #d32f2f;
      font-size: 16px;
    }
    
    .footer {
      margin-top: 30px;
      padding: 20px;
      background: #f8f9fa;
      border-radius: 10px;
      text-align: center;
      border: 1px solid #e0e0e0;
    }
    
    .footer-title {
      font-size: 16px;
      font-weight: bold;
      color: #667eea;
      margin-bottom: 15px;
    }
    
    .payment-methods {
      display: flex;
      justify-content: space-around;
      margin-bottom: 15px;
    }
    
    .payment-item {
      text-align: center;
    }
    
    .payment-label {
      font-size: 12px;
      color: #666;
      margin-bottom: 5px;
    }
    
    .payment-number {
      font-size: 14px;
      font-weight: bold;
      color: #d32f2f;
    }
    
    .contact {
      margin-top: 15px;
      padding-top: 15px;
      border-top: 1px solid #e0e0e0;
      font-size: 14px;
      color: #666;
    }
    
    @media print {
      body {
        padding: 10px;
      }
      
      .header {
        page-break-after: avoid;
      }
      
      table {
        page-break-inside: auto;
      }
      
      tr {
        page-break-inside: avoid;
        page-break-after: auto;
      }
    }
  </style>
</head>
<body>
  <!-- Header -->
  <div class="header">
    <h1>كشف المستحقات المالية</h1>
    <div class="date">شهر $monthName</div>
  </div>

  <!-- Summary -->
  <div class="summary">
    <div class="summary-item">
      <div class="summary-label">إجمالي المبلغ</div>
      <div class="summary-value">${_formatAmount(totalAmount)}</div>
    </div>
    <div class="summary-item">
      <div class="summary-label">عدد العملاء</div>
      <div class="summary-value">$totalCount</div>
    </div>
  </div>

  <!-- Table -->
  <table>
    <thead>
      <tr>
        <th>المبلغ</th>
        <th>رقم الهاتف</th>
        <th>الاسم</th>
      </tr>
    </thead>
    <tbody>
      ${dues.map((due) => '''
        <tr>
          <td class="amount">${_formatAmount(due['amount'])}</td>
          <td>${_formatPhone(due['phone'])}</td>
          <td>${_safeString(due['name'])}</td>
        </tr>
      ''').join()}
    </tbody>
  </table>

  <!-- Footer -->
  <div class="footer">
    <div class="footer-title">وسائل الدفع المتاحة</div>
    
    <div class="payment-methods">
      <div class="payment-item">
        <div class="payment-label">فودافون كاش</div>
        <div class="payment-number">01022690901</div>
      </div>
      <div class="payment-item">
        <div class="payment-label">إنستاباي</div>
        <div class="payment-number">01017174149</div>
      </div>
    </div>
    
    <div class="contact">
      <strong>للاستفسار:</strong> واتساب 01017174149
    </div>
  </div>
</body>
</html>
    ''';

    // Generate PDF from HTML
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final fileName = customFileName ?? 'كشف_المستحقات_$monthName\_$timestamp.pdf';

    final generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
      htmlContent,
      fileName.replaceAll('.pdf', ''),
      targetDirectory: directory.path,
      targetName: fileName,
    );

    return File(generatedPdfFile.path);
  }

  /// Format amount with Arabic currency
  static String _formatAmount(dynamic amount) {
    if (amount == null) return "0 ج.م";

    double numAmount = 0.0;
    if (amount is num) {
      numAmount = amount.toDouble();
    } else if (amount is String) {
      numAmount = double.tryParse(amount) ?? 0.0;
    }

    final formatter = NumberFormat('#,##0', 'ar_EG');
    return '${formatter.format(numAmount)} ج.م';
  }

  /// Format phone number
  static String _formatPhone(dynamic phone) {
    if (phone == null) return "غير محدد";

    String phoneStr = phone.toString().trim();
    if (phoneStr.isEmpty) return "غير محدد";

    // Add leading zero if needed
    if (phoneStr.length == 10 && !phoneStr.startsWith('0')) {
      phoneStr = '0$phoneStr';
    }

    return phoneStr;
  }

  /// Safe string extraction
  static String _safeString(dynamic value, {String defaultValue = "غير محدد"}) {
    if (value == null) return defaultValue;
    if (value is String) {
      return value.trim().isEmpty ? defaultValue : value.trim();
    }
    return value.toString().trim().isEmpty
        ? defaultValue
        : value.toString().trim();
  }
}
*/

// NOTE: To use this HTML to PDF generator:
// 1. Add to pubspec.yaml: flutter_html_to_pdf: ^0.7.0
// 2. Run: flutter pub get
// 3. Uncomment this file
// 4. Replace the call in dues_show.dart:
//    From: await _filteredDues.generateAndSave(...)
//    To: await HtmlPdfGenerator.generateDuesPdf(dues: _filteredDues, monthName: monthName)
