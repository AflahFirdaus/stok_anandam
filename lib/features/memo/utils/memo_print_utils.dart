import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:stok_anandam/data/models/memo.dart';

class MemoPrintUtils {
  static Future<void> printMemoLabels(List<MemoDetail> memos) async {
    final pdf = pw.Document();
    final fontNormal = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final DateFormat formatter = DateFormat('dd MMMM yyyy');

    String formatRp(num value) {
      return "Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
    }

    for (final memo in memos) {
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, 80 * PdfPageFormat.mm),
          margin: const pw.EdgeInsets.all(5),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: memo.id ?? 'N/A',
                    width: 120,
                    height: 120,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    memo.nomorMemo ?? memo.id ?? '-',
                    style: pw.TextStyle(
                      font: fontBold, 
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    (memo.customerName ?? 'Umum').toUpperCase(),
                    style: pw.TextStyle(
                      font: fontBold, 
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                    maxLines: 3,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    final String fileName = memos.length == 1
        ? 'Label_${memos.first.nomorMemo ?? memos.first.id ?? 'document'}.pdf'
        : 'Bulk_Labels_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }

  static Future<void> printFullMemo(MemoDetail memo) async {
    await printFullMemos([memo]);
  }

  static Future<void> printFullMemos(List<MemoDetail> memos) async {
    if (memos.isEmpty) return;

    final pdf = pw.Document();
    final fontNormal = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final DateFormat formatter = DateFormat('dd MMMM yyyy');

    String formatRp(num value) {
      return "Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
    }

    for (final memo in memos) {
      final String formattedDate = memo.tanggalMemo != null
          ? formatter.format(memo.tanggalMemo!)
          : formatter.format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(2 * PdfPageFormat.cm),
          build: (pw.Context context) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: memo.id ?? 'N/A',
                        width: 60,
                        height: 60,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Scan for Detail',
                          style: pw.TextStyle(
                              font: fontNormal,
                              fontSize: 7,
                              color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('MEMO ${memo.memoType ?? ''}',
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 24,
                              color: PdfColors.blue900)),
                      pw.Text(memo.nomorMemo ?? '-',
                          style: pw.TextStyle(font: fontBold, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1, color: PdfColors.blue900),
              pw.SizedBox(height: 5),

              // Info Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PELANGGAN:',
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 9,
                                color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        if (memo.platform != null) ...[
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.blue100,
                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              memo.platform!.toUpperCase(),
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 10,
                                  color: PdfColors.blue900),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                        ],
                        pw.Text(
                          (memo.customerName ?? 'Umum').toUpperCase(),
                          style: pw.TextStyle(font: fontBold, fontSize: 13),
                        ),
                        pw.SizedBox(height: 2),
                        if (memo.customerPhone != null && memo.customerPhone!.isNotEmpty)
                          pw.Text(
                            memo.customerPhone!,
                            style: pw.TextStyle(font: fontNormal, fontSize: 10),
                          ),
                        if (memo.memoType == 'ONLINE')
                          pw.Text(
                            '${memo.ekspedisi ?? '-'}${memo.subEkspedisi != null ? ' - ${memo.subEkspedisi}' : ''}',
                            style: pw.TextStyle(font: fontNormal, fontSize: 10, color: PdfColors.grey700),
                          ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INFORMASI PESANAN:',
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 9,
                                color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(' $formattedDate',
                            style: pw.TextStyle(font: fontBold, fontSize: 11)),
                        pw.Text(
                            ' ${memo.marketingName ?? memo.creatorName ?? '-'}',
                            style: pw.TextStyle(font: fontNormal, fontSize: 10)),
                        pw.Text(
                          ' ${memo.metodePembayaran ?? '-'} ${memo.tempo ?? ''}',
                          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900),
                        ),
                        if (memo.metodePembayaran == 'TEMPO' &&
                            memo.tempo != null)
                          pw.Text(
                            'Tempo: ${memo.tempo!}',
                            style: pw.TextStyle(font: fontBold, fontSize: 10),
                          ),
                        if (memo.badanUsaha != null && memo.memoType == 'PROJECT')
                          pw.Text(' ${memo.badanUsaha}',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 10,
                                  color: PdfColors.blue900)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Items Table
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerAlignment: pw.Alignment.centerLeft,
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
                headerHeight: 25,
                cellHeight: 20,
                headerStyle: pw.TextStyle(
                    font: fontBold, fontSize: 9, color: PdfColors.blue900),
                cellStyle: pw.TextStyle(font: fontNormal, fontSize: 9),
                headers: [
                  'No',
                  'Nama Barang',
                  'Jumlah',
                  'Harga Satuan',
                  'Subtotal'
                ],
                data: List<List<String>>.generate(
                  memo.items.length,
                  (index) {
                    final item = memo.items[index];
                    return [
                      '${index + 1}',
                      item.namaBarang ?? '-',
                      '${item.qty}',
                      formatRp(item.hargaSatuan),
                      formatRp(item.subtotal),
                    ];
                  },
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(25),
                  1: const pw.FlexColumnWidth(),
                  2: const pw.FixedColumnWidth(50),
                  3: const pw.FixedColumnWidth(90),
                  4: const pw.FixedColumnWidth(90),
                },
              ),
              pw.SizedBox(height: 15),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Catatan / Deskripsi (Left side)
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey200),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                        color: PdfColors.grey50,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CATATAN / DESKRIPSI:',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 8,
                                  color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            memo.deskripsi ?? '-',
                            style: pw.TextStyle(font: fontNormal, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('TOTAL',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 10,
                                  color: PdfColors.grey700)),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            formatRp(memo.totalHarga),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 18,
                              color: PdfColors.blue900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
            ];
          },
        ),
      );
    }

    final String fileName = memos.length == 1
        ? 'Memo_${memos.first.nomorMemo ?? memos.first.id ?? 'Doc'}.pdf'
        : 'Bulk_Memos_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
      format: PdfPageFormat.a4,
    );
  }
}
