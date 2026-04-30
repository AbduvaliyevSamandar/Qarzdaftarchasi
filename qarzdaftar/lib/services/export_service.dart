import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/customer_balance.dart';
import '../models/shop_profile.dart';
import '../utils/input_formatters.dart';

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  Future<File> exportToExcel({
    required ShopProfile shop,
    required List<CustomerBalance> customers,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Mijozlar'];
    excel.setDefaultSheet('Mijozlar');
    excel.delete('Sheet1');

    final headers = [
      '№',
      'Ism',
      'Telefon',
      'Manzil',
      'Jami qarz',
      'Qaytarilgan',
      'Qoldiq',
      'Holati',
    ];
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }

    for (var i = 0; i < customers.length; i++) {
      final cb = customers[i];
      final c = cb.customer;
      final row = i + 1;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = IntCellValue(i + 1);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(c.name);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(
        c.phone != null ? UzbPhoneInputFormatter.fromE164(c.phone) : '',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(c.address ?? '');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = DoubleCellValue(cb.totalDebt);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = DoubleCellValue(cb.totalPaid);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = DoubleCellValue(cb.remaining);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
          .value = TextCellValue(
        cb.hasOverdue
            ? 'Muddati o\'tdi'
            : cb.remaining <= 0
                ? 'Qarzi yo\'q'
                : 'Qarzdor',
      );
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Excel yaratishda xatolik');
    }
    final path = await _filePath('mijozlar', 'xlsx');
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<File> exportToPdf({
    required ShopProfile shop,
    required List<CustomerBalance> customers,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              shop.name,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            if (shop.ownerName != null) pw.Text('Egasi: ${shop.ownerName}'),
            if (shop.ownerPhone != null)
              pw.Text('Tel: ${UzbPhoneInputFormatter.fromE164(shop.ownerPhone)}'),
            pw.SizedBox(height: 10),
            pw.Text(
              'Qarz daftari — ${now.day}.${now.month}.${now.year}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(),
          ],
        ),
        build: (_) => [
          pw.Table.fromTextArray(
            headers: ['#', 'Ism', 'Telefon', 'Manzil', 'Qoldiq', 'Holat'],
            data: [
              for (var i = 0; i < customers.length; i++)
                _buildRow(i + 1, customers[i]),
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignments: const {
              0: pw.Alignment.center,
              4: pw.Alignment.centerRight,
            },
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Jami qoldiq: ${MoneyInputFormatter.formatAmount(customers.fold<double>(0, (a, b) => a + b.remaining).toInt())} so\'m',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final path = await _filePath('mijozlar', 'pdf');
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }

  List<String> _buildRow(int n, CustomerBalance cb) {
    return [
      '$n',
      cb.customer.name,
      cb.customer.phone != null
          ? UzbPhoneInputFormatter.fromE164(cb.customer.phone)
          : '',
      cb.customer.address ?? '',
      '${MoneyInputFormatter.formatAmount(cb.remaining.toInt())} so\'m',
      cb.hasOverdue
          ? 'Muddati o\'tdi'
          : cb.remaining <= 0
              ? 'Qarzi yo\'q'
              : 'Qarzdor',
    ];
  }

  Future<void> shareFile(File file, {String? text}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: text,
    );
  }

  Future<String> _filePath(String name, String ext) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(dir.path, '${name}_$stamp.$ext');
  }
}
