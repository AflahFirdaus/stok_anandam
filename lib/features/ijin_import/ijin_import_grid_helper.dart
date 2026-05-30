import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/features/ijin_import/ijin_import_response.dart';

class IjinImportGridHelper {
  static List<PlutoColumn> getColumns(BuildContext context) {
    return [
      PlutoColumn(
        title: 'No',
        field: 'no',
        type: PlutoColumnType.number(),
        width: 80,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'Nama Barang',
        field: 'nama_barang',
        type: PlutoColumnType.text(),
        width: 250,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Spesifikasi',
        field: 'spesifikasi',
        type: PlutoColumnType.text(),
        width: 350,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Keterangan',
        field: 'keterangan',
        type: PlutoColumnType.text(),
        width: 400,
        enableEditingMode: false,
      ),
    ];
  }

  static List<PlutoRow> mapToRows(List<IjinImportResponse> data) {
    return data.map((item) {
      return PlutoRow(
        cells: {
          'no': PlutoCell(value: item.no ?? 0),
          'nama_barang': PlutoCell(value: item.namaBarang ?? '—'),
          'spesifikasi': PlutoCell(value: item.spesifikasi ?? '—'),
          'keterangan': PlutoCell(value: item.keterangan ?? '—'),
        },
      );
    }).toList();
  }
}
