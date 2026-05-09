import 'package:flutter/material.dart';
import 'package:stok_anandam/data/models/memo.dart';

class StatusBadge extends StatelessWidget {
  final MemoStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case MemoStatus.DRAFT:
        color = Colors.grey;
        text = 'Draft (Marketing)';
        break;
      case MemoStatus.MENUNGGU_PERSETUJUAN:
      case MemoStatus.PENDING:
        color = Colors.amber;
        text = 'Menunggu ACC';
        break;
      case MemoStatus.DISETUJUI:
        color = Colors.green;
        text = 'Disetujui';
        break;
      case MemoStatus.DITOLAK:
        color = Colors.red;
        text = 'Ditolak';
        break;
      case MemoStatus.MENUNGGU_GUDANG:
        color = Colors.orange;
        text = 'Menunggu Gudang';
        break;
      case MemoStatus.MENUNGGU_NOTA:
        color = Colors.blue;
        text = 'Menunggu Nota';
        break;
      case MemoStatus.MENUNGGU_TEKNISI:
        color = Colors.orange;
        text = 'Menunggu Teknisi';
        break;
      case MemoStatus.PROSES_TEKNISI:
        color = Colors.cyan;
        text = 'Proses Teknisi';
        break;
      case MemoStatus.BUFFER_ZONE:
        color = Colors.teal;
        text = 'Buffer Zone';
        break;
      case MemoStatus.MENUNGGU_PENGIRIMAN:
        color = Colors.orange;
        text = 'Menunggu Pengiriman';
        break;
      case MemoStatus.DALAM_PENGIRIMAN:
        color = Colors.blue;
        text = 'Dalam Pengiriman';
        break;
      case MemoStatus.DITERIMA_USER:
        color = Colors.indigo;
        text = 'Diterima User';
        break;
      case MemoStatus.TERKIRIM_SEBAGIAN:
        color = Colors.blueGrey;
        text = 'Terkirim Sebagian';
        break;
      case MemoStatus.KENDALA_BARANG:
        color = Colors.red;
        text = 'Kendala Barang';
        break;
      case MemoStatus.MENUNGGU_KONFIRMASI_PICKUP:
        color = Colors.deepPurple;
        text = 'Menunggu Konfirmasi (Pkt)';
        break;
      case MemoStatus.SELESAI:
        color = const Color(0xFF1E40AF); // Blue bold
        text = 'Selesai';
        break;
      case MemoStatus.DIBATALKAN:
        color = Colors.grey.shade700;
        text = 'Dibatalkan';
        break;
      default:
        color = Colors.grey;
        text = status.name;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
