import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';
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
        width: 350,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final rowData = rendererContext.row.cells;
          final namaBarang = rowData['nama_barang']?.value?.toString() ?? '—';
          final spesifikasi = rowData['spesifikasi']?.value?.toString() ?? '';
          return _buildNamaBarangCell(namaBarang, spesifikasi);
        },
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

  static Widget _buildNamaBarangCell(String namaBarang, String spesifikasi) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  namaBarang,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (spesifikasi.isNotEmpty && spesifikasi != '—') ...[
                  const SizedBox(height: 2),
                  Text(
                    spesifikasi,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              final textToCopy = [
                if (namaBarang.isNotEmpty && namaBarang != '—') namaBarang,
                if (spesifikasi.isNotEmpty && spesifikasi != '—') spesifikasi,
              ].join('\n');
              if (textToCopy.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: textToCopy));
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.content_copy_rounded,
                size: 14,
                color: Colors.blue.shade600,
              ),
            ),
          ),
        ],
      ),
    );
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
