import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../models/transaksi_servis.dart';

class ServisGridHelper {
  static List<PlutoColumn> getColumns(BuildContext context) {
    return [
      PlutoColumn(
        title: 'Tgl Terima',
        field: 'tglTerima',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'No Servis',
        field: 'noServis',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Pelanggan',
        field: 'namaPelanggan',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Barang',
        field: 'jenisBarang',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Kerusakan',
        field: 'kerusakan',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'statusTerkini',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Teknisi',
        field: 'namaTeknisi',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Estimasi Biaya',
        field: 'estimasiBiaya',
        type: PlutoColumnType.currency(symbol: 'Rp', decimalDigits: 0),
        width: 150,
        enableEditingMode: false,
        enableColumnDrag: false,
        textAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'Aksi',
        field: 'aksi',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
        enableColumnDrag: false,
        textAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return IconButton(
            icon: const Icon(Icons.remove_red_eye, color: Colors.blue, size: 18),
            onPressed: () {
              // Aksi ini akan ditangani dari UI page dengan mengirim event.
              // Kita passing data ID ke cell value atau bisa ditangani di event listener PlutoGrid.
            },
          );
        },
      ),
    ];
  }

  static List<PlutoRow> mapToRows(List<TransaksiServis> items) {
    return items.map((t) {
      return PlutoRow(
        cells: {
          'tglTerima': PlutoCell(value: _fmtDate(t.tglTerima)),
          'noServis': PlutoCell(value: t.noServis ?? '—'),
          'namaPelanggan': PlutoCell(value: t.namaPelanggan ?? '—'),
          'jenisBarang': PlutoCell(value: '${t.jenisBarang ?? ''} ${t.merek ?? ''}'.trim()),
          'kerusakan': PlutoCell(value: t.kerusakan ?? '—'),
          'statusTerkini': PlutoCell(value: t.statusTerkini?.replaceAll('_', ' ') ?? '—'),
          'namaTeknisi': PlutoCell(value: t.namaTeknisi ?? '—'),
          'estimasiBiaya': PlutoCell(value: t.estimasiBiaya ?? 0),
          'aksi': PlutoCell(value: t.id ?? ''),
        },
      );
    }).toList();
  }

  static String _fmtDate(String? d) {
    if (d == null) return '—';
    try {
      final date = DateTime.tryParse(d);
      if (date != null) {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (_) {}
    return d;
  }
}
