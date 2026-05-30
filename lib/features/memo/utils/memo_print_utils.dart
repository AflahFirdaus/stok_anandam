import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
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
      PdfColor primaryColor;
      PdfColor accentColor;

      bool isAmbilDiToko = false;
      if (memo.opsiPengiriman != null && memo.opsiPengiriman!.toUpperCase() == 'AMBIL DI TOKO') {
        isAmbilDiToko = true;
      } else if (!memo.isDeliveryRequired && (memo.opsiPengiriman == null || memo.opsiPengiriman!.isEmpty)) {
        isAmbilDiToko = true;
      }

      switch (memo.memoType) {
        case 'DISTRIBUSI':
          primaryColor = PdfColor.fromHex('#147D52');
          accentColor = PdfColors.teal100;
          break;
        case 'PROJECT':
          primaryColor = PdfColors.blue900;
          accentColor = PdfColors.blue100;
          break;
        case 'ONLINE':
          primaryColor = PdfColors.orange900;
          accentColor = PdfColors.orange100;
          break;
        case 'BIASA':
          primaryColor = PdfColors.pink900;
          accentColor = PdfColors.pink100;
          break;
        case 'PENDING':
          primaryColor = PdfColors.yellow900;
          accentColor = PdfColors.yellow100;
          break;
        default:
          primaryColor = PdfColors.blue900;
          accentColor = PdfColors.blue100;
      }

      pdf.addPage(
        pw.Page(
          pageFormat:
              const PdfPageFormat(80 * PdfPageFormat.mm, 80 * PdfPageFormat.mm),
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
                  if (memo.memoType == 'ONLINE' &&
                      memo.orderIdMarketplace != null) ...[
                    pw.SizedBox(height: 2),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: accentColor,
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(2)),
                      ),
                      child: pw.Text(
                        'ID MARKETPLACE: ${memo.orderIdMarketplace}',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 9,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
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
                  if (isAmbilDiToko) ...[
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.deepOrange100,
                        border: pw.Border.all(color: PdfColors.deepOrange900),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        'AMBIL DI TOKO',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 10,
                          color: PdfColors.deepOrange900,
                        ),
                      ),
                    ),
                  ],
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
      PdfColor primaryColor;
      PdfColor secondaryColor;
      PdfColor accentColor;

      switch (memo.memoType) {
        case 'DISTRIBUSI':
          primaryColor = PdfColor.fromHex('#147D52');
          secondaryColor = PdfColors.teal50;
          accentColor = PdfColors.teal100;
          break;
        case 'PROJECT':
          primaryColor = PdfColors.blue900;
          secondaryColor = PdfColors.blue50;
          accentColor = PdfColors.blue100;
          break;
        case 'ONLINE':
          primaryColor = PdfColors.orange900;
          secondaryColor = PdfColors.orange50;
          accentColor = PdfColors.orange100;
          break;
        case 'BIASA':
          primaryColor = PdfColors.pink900;
          secondaryColor = PdfColors.pink50;
          accentColor = PdfColors.pink100;
          break;
        case 'PENDING':
          primaryColor = PdfColors.yellow900;
          secondaryColor = PdfColors.yellow50;
          accentColor = PdfColors.yellow100;
          break;
        default:
          primaryColor = PdfColors.blue900;
          secondaryColor = PdfColors.blue50;
          accentColor = PdfColors.blue100;
      }

      final String formattedDate = memo.tanggalMemo != null
          ? formatter.format(memo.tanggalMemo!)
          : formatter.format(DateTime.now());

      bool isAmbilDiToko = false;
      if (memo.opsiPengiriman != null &&
          memo.opsiPengiriman!.toUpperCase() == 'AMBIL DI TOKO') {
        isAmbilDiToko = true;
      } else if (!memo.isDeliveryRequired &&
          (memo.opsiPengiriman == null || memo.opsiPengiriman!.isEmpty)) {
        isAmbilDiToko = true;
      }

      String displayTipeOngkir = memo.tipeOngkir ?? '';
      String displayEkspedisi = memo.ekspedisi ?? '';

      if (isAmbilDiToko) {
        displayEkspedisi = '';
        displayTipeOngkir = 'AMBIL DI TOKO';
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
                              color: primaryColor)),
                      pw.Text(memo.nomorMemo ?? '-',
                          style: pw.TextStyle(font: fontBold, fontSize: 14)),
                      if (memo.memoType == 'ONLINE' &&
                          memo.orderIdMarketplace != null)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 4),
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: accentColor,
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            'ORDER ID MARKETPLACE: ${memo.orderIdMarketplace}',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 11,
                              color: primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1, color: primaryColor),
              pw.SizedBox(height: 5),

              // Info Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // 1. HEADER ROW: Menggabungkan Label "PELANGGAN" dan Badge "PLATFORM"
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              'PELANGGAN',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 9,
                                color: PdfColors
                                    .grey600, // Sedikit lebih soft agar tidak kaku
                              ),
                            ),
                            if (memo.platform != null) ...[
                              pw.SizedBox(
                                  width:
                                      6), // Jarak horizontal ke badge platform
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: pw.BoxDecoration(
                                  color: accentColor,
                                  borderRadius: const pw.BorderRadius.all(
                                      pw.Radius.circular(3)),
                                ),
                                child: pw.Text(
                                  memo.platform!.toUpperCase(),
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize:
                                        8, // Sedikit diperkecil agar proporsional sebagai badge
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        pw.SizedBox(
                            height: 4), // Jarak konsisten ke nama pelanggan

                        // 2. MAIN INFO: Nama Pelanggan (Bold & Tegas) + Nomor HP (Disampingnya/Di bawahnya dengan rapi)
                        pw.Text(
                          (memo.customerName ?? 'Umum').toUpperCase(),
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize:
                                13, // 13 sudah sangat cukup terbaca tanpa merusak space
                            color: PdfColors.black,
                          ),
                        ),

                        if (memo.customerPhone != null &&
                            memo.customerPhone!.isNotEmpty) ...[
                          pw.SizedBox(
                              height:
                                  1), // Jarak super tipis agar nomor HP menempel rapi di bawah nama
                          pw.Text(
                            memo.customerPhone!,
                            style: pw.TextStyle(
                              font: fontNormal,
                              fontSize: 10.5,
                              color: PdfColors
                                  .grey700, // Warna abu-abu gelap agar tidak balapan dengan nama
                            ),
                          ),
                        ],

                        // 3. SHIPPING & PAYMENT INFO BAR (Ekspedisi & Tipe Ongkir)
                        if (displayEkspedisi.isNotEmpty ||
                            displayTipeOngkir.isNotEmpty) ...[
                          pw.SizedBox(
                              height: 5), // Jarak pemisah ke block pengiriman
                          pw.Container(
                            // Membungkus info pengiriman dengan background abu-abu super tipis (opsional, memberikan kesan rapi)
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey100,
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(4)),
                            ),
                            child: pw.Row(
                              mainAxisSize: pw.MainAxisSize
                                  .min, // Agar container tidak melebar paksa ke kanan jika text pendek
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                // Bagian Ekspedisi
                                if (displayEkspedisi.isNotEmpty)
                                  pw.Text(
                                    '${displayEkspedisi}${memo.subEkspedisi != null && memo.subEkspedisi!.isNotEmpty ? ' - ${memo.subEkspedisi}' : ''}'
                                        .toUpperCase(),
                                    style: pw.TextStyle(
                                      font: fontNormal,
                                      fontSize: 9.5,
                                      color: PdfColors.grey900,
                                    ),
                                  ),

                                // Separator Ringan
                                if (displayEkspedisi.isNotEmpty &&
                                    displayTipeOngkir.isNotEmpty)
                                  pw.Text(
                                    '  |  ',
                                    style: pw.TextStyle(
                                      font: fontNormal,
                                      fontSize: 9.5,
                                      color: PdfColors.grey400,
                                    ),
                                  ),

                                // Bagian Tipe Ongkir (Sorotan Utama)
                                if (displayTipeOngkir.isNotEmpty)
                                  pw.Text(
                                    displayTipeOngkir.toUpperCase(),
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 11,
                                      color: PdfColors.black,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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
                            style:
                                pw.TextStyle(font: fontNormal, fontSize: 12)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                            ' ${memo.marketingName ?? memo.creatorName ?? '-'}',
                            style: pw.TextStyle(font: fontBold, fontSize: 12)),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.teal100,
                            border: pw.Border.all(
                                color: PdfColors.teal700, width: 1),
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            '${memo.metodePembayaran ?? '-'} ${memo.tempo != null && memo.tempo!.isNotEmpty ? memo.tempo! : ''}'
                                .toUpperCase(),
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 12,
                                color: PdfColors.teal900),
                          ),
                        ),
                        if (memo.metodePembayaran == 'TEMPO' &&
                            memo.tempo != null) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Tempo: ${memo.tempo!}',
                            style: pw.TextStyle(font: fontBold, fontSize: 12),
                          ),
                        ],
                        if (memo.badanUsaha != null &&
                            memo.memoType == 'PROJECT') ...[
                          pw.SizedBox(height: 2),
                          pw.Text(' ${memo.badanUsaha}',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 12,
                                  color: primaryColor)),
                        ],
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
                headerDecoration: pw.BoxDecoration(color: secondaryColor),
                headerHeight: 25,
                cellHeight: 20,
                headerStyle: pw.TextStyle(
                    font: fontBold, fontSize: 9, color: primaryColor),
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
                              color: primaryColor,
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

  static Future<Uint8List> generatePostInvoicePdf(
      MemoDetail memo, PdfPageFormat format) async {
    final pdf = pw.Document();
    final fontNormal = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final DateFormat formatter = DateFormat('dd MMMM yyyy');

    String formatRp(num value) {
      return "Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
    }

    final String formattedDate = memo.tanggalMemo != null
        ? formatter.format(memo.tanggalMemo!)
        : formatter.format(DateTime.now());

    bool isAmbilDiToko = false;
    if (memo.opsiPengiriman != null &&
        memo.opsiPengiriman!.toUpperCase() == 'AMBIL DI TOKO') {
      isAmbilDiToko = true;
    } else if (!memo.isDeliveryRequired &&
        (memo.opsiPengiriman == null || memo.opsiPengiriman!.isEmpty)) {
      isAmbilDiToko = true;
    }

    String displayTipeOngkir = memo.tipeOngkir ?? '';
    String displayEkspedisi = memo.ekspedisi ?? '';

    if (isAmbilDiToko) {
      displayEkspedisi = '';
      displayTipeOngkir = 'AMBIL DI TOKO';
    }

    String capitalizeStatus(String? status) {
      if (status == null || status.isEmpty) return 'AKTIVITAS';
      return status.split('_').map((word) {
        if (word.isEmpty) return "";
        return word;
      }).join(' ');
    }

    pw.MemoryImage? pngLogo;
    try {
      final ByteData data =
          await rootBundle.load('assets/images/Movva by Anandam.png');
      pngLogo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      pngLogo = null;
    }

    final double calculatedHeight =
        18 * PdfPageFormat.cm + (memo.items.length * 1.5 * PdfPageFormat.cm);

    pdf.addPage(
      pw.Page(
        // Change to pw.Page since we want a single long page
        pageFormat: PdfPageFormat(18 * PdfPageFormat.cm, calculatedHeight),
        margin: const pw.EdgeInsets.all(1.2 * PdfPageFormat.cm),
        build: (pw.Context context) {
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (pngLogo != null)
                          pw.Container(
                            width: 45,
                            child: pw.Image(pngLogo),
                          )
                        else
                          pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.teal,
                              borderRadius:
                                  pw.BorderRadius.all(pw.Radius.circular(8)),
                            ),
                            child: pw.Text('A',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 24,
                                  color: PdfColors.white,
                                )),
                          ),
                        pw.SizedBox(width: 12),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('ANANDAM COMPUTER',
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 18,
                                    color: PdfColors.teal900)),
                            pw.SizedBox(height: 2),
                            pw.Text('Penuhi Kebutuhan IT Anda',
                                style: pw.TextStyle(
                                    font: fontNormal,
                                    fontSize: 10,
                                    color: PdfColors.grey700)),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('POST INVOICE',
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 22,
                                color: PdfColors.teal)),
                        pw.SizedBox(height: 4),
                        pw.Text(memo.nomorMemo ?? '-',
                            style: pw.TextStyle(
                                font: fontBold, fontSize: 8)), // Shrink ID
                        pw.SizedBox(height: 6),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.teal100,
                            borderRadius:
                                pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            'STATUS: ${capitalizeStatus(memo.statusAkhir?.name).toUpperCase()}',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 10,
                              color: PdfColors.teal900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Divider(thickness: 1, color: PdfColors.teal),
                pw.SizedBox(height: 15),

                // Info Section
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DITUJUKAN KEPADA:',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 9,
                                  color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            (memo.customerName ?? 'Umum').toUpperCase(),
                            style: pw.TextStyle(font: fontBold, fontSize: 13),
                          ),
                          pw.SizedBox(height: 2),
                          if (memo.customerPhone != null &&
                              memo.customerPhone!.isNotEmpty)
                            pw.Text(
                              memo.customerPhone!,
                              style:
                                  pw.TextStyle(font: fontNormal, fontSize: 10),
                            ),
                          pw.SizedBox(height: 4),
                          if (displayEkspedisi.isNotEmpty)
                            pw.Text(
                              'Ekspedisi: $displayEkspedisi${memo.subEkspedisi != null && memo.subEkspedisi!.isNotEmpty ? ' - ${memo.subEkspedisi}' : ''}',
                              style: pw.TextStyle(
                                  font: fontNormal,
                                  fontSize: 10,
                                  color: PdfColors.grey700),
                            ),
                          if (displayTipeOngkir.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              displayTipeOngkir,
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 10,
                                  color: PdfColors.grey900),
                            ),
                          ],
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('DETAIL TRANSAKSI:',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 9,
                                  color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text('Tanggal: $formattedDate',
                              style:
                                  pw.TextStyle(font: fontBold, fontSize: 10)),
                          pw.Text(
                            'Pembayaran: ${memo.metodePembayaran?.toUpperCase() == 'TEMPO' && memo.tempo != null ? '${memo.metodePembayaran} ${memo.tempo!.trim()} Hari' : (memo.metodePembayaran ?? '-')}',
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 10,
                                color: PdfColors.teal900),
                          ),
                          pw.Text(
                            'PIC: ${memo.marketingName ?? memo.creatorName ?? '-'}',
                            style: pw.TextStyle(
                                font: fontNormal,
                                fontSize: 10,
                                color: PdfColors.grey600),
                          ),
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
                      const pw.BoxDecoration(color: PdfColors.teal50),
                  headerHeight: 25,
                  cellHeight: 20,
                  headerStyle: pw.TextStyle(
                      font: fontBold, fontSize: 9, color: PdfColors.teal900),
                  cellStyle: pw.TextStyle(font: fontNormal, fontSize: 9),
                  headers: ['No', 'Deskripsi Barang', 'Qty', 'Satuan', 'Total'],
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
                    2: const pw.FixedColumnWidth(40),
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
                            pw.Text('CATATAN:',
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 8,
                                    color: PdfColors.grey700)),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              memo.deskripsi ?? '-',
                              style:
                                  pw.TextStyle(font: fontNormal, fontSize: 9),
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
                            pw.Text('TOTAL PEMBAYARAN',
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
                                color: PdfColors.teal900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                pw.Center(
                    child: pw.Text(
                  'Terima kasih telah berbelanja di Anandam Computer.',
                  style: pw.TextStyle(
                      font: fontNormal, fontSize: 10, color: PdfColors.grey600),
                )),
              ]);
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printShippingAddresses(List<MemoDetail> memos) async {
    final pdf = pw.Document();
    final fontNormal = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    for (final memo in memos) {
      final String alamat = (memo.desaKelurahan != null &&
              memo.desaKelurahan!.isNotEmpty)
          ? "${memo.desaKelurahan}, ${memo.kecamatan}, ${memo.kabupatenKota}${memo.kodePos != null ? ' (${memo.kodePos})' : ''}"
          : (memo.penjadwalanHistory.any(
                  (j) => j.alamatLengkap != null && j.alamatLengkap!.isNotEmpty)
              ? memo.penjadwalanHistory
                  .lastWhere((j) =>
                      j.alamatLengkap != null && j.alamatLengkap!.isNotEmpty)
                  .alamatLengkap!
              : (memo.kodePos != null && memo.kodePos!.isNotEmpty
                  ? memo.kodePos!
                  : '-'));

      final String ekspedisi =
          memo.ekspedisi != null && memo.ekspedisi!.isNotEmpty
              ? (memo.memoType == 'ONLINE' &&
                      memo.subEkspedisi != null &&
                      memo.subEkspedisi!.isNotEmpty
                  ? '${memo.ekspedisi} - ${memo.subEkspedisi}'
                  : memo.ekspedisi!)
              : '-';

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        // Margin halaman A4 (jarak dari ujung kertas ke area konten)
        margin: const pw.EdgeInsets.all(1 * PdfPageFormat.cm),
        build: (pw.Context context) {
          return pw.Align(
            alignment: pw.Alignment.topLeft,
            child: pw.Container(
              // 1. Dibuat KOTAK PERSEGI dengan menyamakan width dan height (contoh: 12x12 cm)
              width: 10 * PdfPageFormat.cm,
              height: 10 * PdfPageFormat.cm,
              // Padding internal untuk konten
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(
                  // 2. Garis pinggir (border) DIHILANGKAN sesuai permintaan
                  ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'LABEL PENGIRIMAN',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                          color: PdfColors.teal900,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Divider(thickness: 2, color: PdfColors.teal900),
                  pw.SizedBox(height: 8),

                  // Sender & Expedition Row
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'PENGIRIM',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 10,
                                  color: PdfColors.grey700),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Anandam Computer',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 12,
                                  color: PdfColors.black),
                            ),
                            pw.Text(
                              '082242818870',
                              style: pw.TextStyle(
                                  font: fontNormal,
                                  fontSize: 10,
                                  color: PdfColors.black),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Jl. Affandi No.17, Soropadan, Condongcatur, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55283',
                              style: pw.TextStyle(
                                  font: fontNormal,
                                  fontSize: 9,
                                  color: PdfColors.black),
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      // Expedition Badge
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.teal50,
                          borderRadius:
                              pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'EKSPEDISI',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 8,
                                  color: PdfColors.teal900),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              ekspedisi.toUpperCase(),
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 12,
                                  color: PdfColors.teal900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 8),
                  pw.Divider(
                      thickness: 1,
                      color: PdfColors.grey400,
                      borderStyle: pw.BorderStyle.dashed),
                  pw.SizedBox(height: 8),

                  // Receiver Info
                  pw.Text(
                    'PENERIMA',
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    (memo.customerName ?? '-').toUpperCase(),
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 12, color: PdfColors.black),
                  ),
                  pw.Text(
                    memo.customerPhone ?? '-',
                    style: pw.TextStyle(
                        font: fontNormal, fontSize: 10, color: PdfColors.black),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    alamat,
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 11, color: PdfColors.black),
                    maxLines: 4,
                  ),

                  if (memo.tipeOngkir != null &&
                      memo.tipeOngkir!.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.teal100,
                        border:
                            pw.Border.all(color: PdfColors.teal700, width: 1),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        memo.tipeOngkir!.toUpperCase(),
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                            color: PdfColors.teal900),
                        maxLines: 3,
                      ),
                    ),
                  ],

                  // Menggunakan Spacer agar Barcode terdorong ke bagian paling bawah persegi
                  pw.Spacer(),

                  // Barcode / QR Code for Scanning
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Scan QR to search Memo',
                            style: pw.TextStyle(
                                font: fontNormal,
                                fontSize: 8,
                                color: PdfColors.grey600),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            memo.nomorMemo ?? memo.id ?? '-',
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 12,
                                color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: memo.id ?? 'N/A',
                        width: 40,
                        height: 40,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ));
    }

    final String fileName = memos.length == 1
        ? 'Label_Alamat_${memos.first.nomorMemo ?? memos.first.id ?? 'Doc'}.pdf'
        : 'Bulk_Label_Alamat.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
      format: PdfPageFormat.a4,
    );
  }
}
