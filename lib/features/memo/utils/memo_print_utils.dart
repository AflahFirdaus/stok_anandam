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
                        pw.SizedBox(height: 2),
                        pw.Text(
                          memo.customerName ?? 'Umum',
                          style: pw.TextStyle(font: fontBold, fontSize: 13),
                        ),
                        pw.Text(
                          (memo.customerPhone == null ||
                                  memo.customerPhone!.isEmpty)
                              ? 'Ekspedisi: ${memo.ekspedisi ?? '-'}'
                              : 'Telp: ${memo.customerPhone}',
                          style: pw.TextStyle(font: fontNormal, fontSize: 10),
                        ),
                        pw.Text(
                          'Pembayaran: ${memo.metodePembayaran ?? '-'} ${memo.tempo ?? ''}',
                          style: pw.TextStyle(font: fontNormal, fontSize: 10),
                        ),
                        if (memo.metodePembayaran == 'TEMPO' &&
                            memo.tempo != null)
                          pw.Text(
                            'Tempo: ${memo.tempo}',
                            style: pw.TextStyle(font: fontBold, fontSize: 10),
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
                        pw.SizedBox(height: 2),
                        pw.Text(' $formattedDate',
                            style: pw.TextStyle(font: fontBold, fontSize: 11)),
                        pw.Text(
                            ' ${memo.marketingName ?? memo.creatorName ?? '-'}',
                            style:
                                pw.TextStyle(font: fontNormal, fontSize: 10)),
                        pw.Text(' ${memo.platform ?? '-'}',
                            style:
                                pw.TextStyle(font: fontNormal, fontSize: 10)),
                        if (memo.badanUsaha != null)
                          pw.Text(' BU: ${memo.badanUsaha}',
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
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerAlignment: pw.Alignment.centerLeft,
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blue50),
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
        ? 'Memo_${memos.first.id ?? 'document'}.pdf'
        : 'Bulk_Memos_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
      format: PdfPageFormat.a4,
    );
  }

  static Future<void> printFullMemo(MemoDetail memo) async {
    final pdf = pw.Document();
    final fontNormal = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final DateFormat formatter = DateFormat('dd MMMM yyyy');
    final String formattedDate = memo.tanggalMemo != null
        ? formatter.format(memo.tanggalMemo!)
        : formatter.format(DateTime.now());

    String formatRp(num value) {
      return "Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
    }

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
                      pw.SizedBox(height: 2),
                      pw.Text(
                        memo.customerName ?? 'Umum',
                        style: pw.TextStyle(font: fontBold, fontSize: 13),
                      ),
                      pw.Text(
                        (memo.customerPhone == null ||
                                memo.customerPhone!.isEmpty)
                            ? 'Ekspedisi: ${memo.ekspedisi ?? '-'}'
                            : 'Telp: ${memo.customerPhone}',
                        style: pw.TextStyle(font: fontNormal, fontSize: 10),
                      ),
                      pw.Text(
                        'Pembayaran: ${memo.metodePembayaran ?? '-'} ${memo.tempo ?? ''}',
                        style: pw.TextStyle(font: fontNormal, fontSize: 10),
                      ),
                      if (memo.metodePembayaran == 'TEMPO' &&
                          memo.tempo != null)
                        pw.Text(
                          'Tempo: ${memo.tempo}',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
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
                      pw.SizedBox(height: 2),
                      pw.Text(' $formattedDate',
                          style: pw.TextStyle(font: fontBold, fontSize: 11)),
                      pw.Text(
                          ' ${memo.marketingName ?? memo.creatorName ?? '-'}',
                          style: pw.TextStyle(font: fontNormal, fontSize: 10)),
                      pw.Text(
                        (memo.platform == null || memo.platform!.isEmpty)
                            ? ' ${memo.ekspedisi ?? '-'}'
                            : ' ${memo.platform}',
                        style: pw.TextStyle(font: fontNormal, fontSize: 10),
                      ),
                      if (memo.badanUsaha != null)
                        pw.Text(' BU: ${memo.badanUsaha}',
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Memo_${memo.nomorMemo ?? memo.id ?? 'Doc'}.pdf',
      format: PdfPageFormat.a4,
    );
  }
}
