import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:stok_anandam/features/shbj/shbj_response.dart';
// Sesuaikan import model Anda
// import '../../models/shbj_response.dart'; 

class ShbjGridHelper {
  static List<PlutoColumn> getColumns(BuildContext context) {
    return [
      PlutoColumn(
        title: 'ID',
        field: 'id',
        type: PlutoColumnType.number(),
        width: 80,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'Kelompok Barang',
        field: 'kelompok',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Uraian Barang',
        field: 'uraian',
        type: PlutoColumnType.text(),
        width: 250,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Spesifikasi',
        field: 'spesifikasi',
        type: PlutoColumnType.text(),
        width: 300,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Satuan',
        field: 'satuan',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'Harga Satuan',
        field: 'harga',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.right,
        titleTextAlign: PlutoColumnTextAlign.right,
      ),
    ];
  }

  static List<PlutoRow> mapToRows(List<ShbjResponse> data) {
    return data.map((item) {
      return PlutoRow(
        cells: {
          'id': PlutoCell(value: item.id ?? 0),
          'kelompok': PlutoCell(value: item.uraianKelompokBarang ?? '—'),
          'uraian': PlutoCell(value: item.uraianBarang ?? '—'),
          'spesifikasi': PlutoCell(value: item.spesifikasi ?? '—'),
          'satuan': PlutoCell(value: item.satuan ?? '—'),
          'harga': PlutoCell(value: item.hargaSatuan ?? '—'),
        },
      );
    }).toList();
  }
}