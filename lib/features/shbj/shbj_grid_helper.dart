import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:stok_anandam/features/shbj/shbj_response.dart';

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
        width: 400,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final rowData = rendererContext.row.cells;
          final uraian = rowData['uraian']?.value?.toString() ?? '—';
          final spesifikasi = rowData['spesifikasi']?.value?.toString() ?? '';
          return _buildUraianBarangCell(uraian, spesifikasi);
        },
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

  static Widget _buildUraianBarangCell(String uraian, String spesifikasi) {
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
                  uraian,
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
                if (uraian.isNotEmpty && uraian != '—') uraian,
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
