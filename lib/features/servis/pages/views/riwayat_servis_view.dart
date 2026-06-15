import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stok_anandam/core/errors/app_errors.dart';
import 'package:stok_anandam/features/servis/models/riwayat_servis.dart';
import 'package:stok_anandam/features/servis/repositories/servis_repository.dart';
import 'package:stok_anandam/injection.dart';

class RiwayatServisDialog extends StatefulWidget {
  final String pelangganId;
  final String? namaPelanggan;

  const RiwayatServisDialog({
    super.key,
    required this.pelangganId,
    this.namaPelanggan,
  });

  /// Helper untuk menampilkan dialog riwayat.
  static Future<void> show(BuildContext context, {
    required String pelangganId,
    String? namaPelanggan,
  }) {
    return showDialog(
      context: context,
      useSafeArea: false,
      builder: (_) => RiwayatServisDialog(
        pelangganId: pelangganId,
        namaPelanggan: namaPelanggan,
      ),
    );
  }

  @override
  State<RiwayatServisDialog> createState() => _RiwayatServisDialogState();
}

class _RiwayatServisDialogState extends State<RiwayatServisDialog> {
  final ServisRepository _repository = getIt<ServisRepository>();

  RiwayatServisPelanggan? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _repository.getRiwayatPelanggan(widget.pelangganId);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppErrors.userMessageFromException(
            e,
            fallback: 'Gagal memuat riwayat servis pelanggan.',
          );
          _isLoading = false;
        });
      }
    }
  }

  static String _fmtRupiah(double? value) {
    if (value == null) return 'Rp0';
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp${formatter.format(value)}';
  }

  static String _fmtDate(String? d) {
    if (d == null) return '-';
    try {
      final dt = DateTime.tryParse(d);
      if (dt == null) return d;
      return DateFormat('dd/MM/yy HH:mm').format(dt);
    } catch (_) {
      return d;
    }
  }

  static String _labelStatus(String? status) {
    if (status == null) return '-';
    switch (status) {
      case 'BELUM_CEK':
        return 'Belum Cek';
      case 'SEDANG_CEK':
        return 'Sedang Cek';
      case 'SEDANG_DIKERJAKAN':
        return 'Dikerjakan';
      case 'SEDANG_TES':
        return 'Tes';
      case 'TUNGGU_KONFIRMASI':
        return 'Konfirmasi';
      case 'TUNGGU_SPAREPART':
        return 'Tunggu Sparepart';
      case 'BISA_DIAMBIL':
        return 'Bisa Diambil';
      case 'BATAL':
        return 'Batal';
      case 'SUDAH_DIAMBIL':
        return 'Sudah Diambil';
      default:
        return status;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'SUDAH_DIAMBIL':
        return Colors.green;
      case 'BATAL':
        return Colors.red;
      case 'BISA_DIAMBIL':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 40,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.history_rounded,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Servis',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.namaPelanggan != null)
                          Text(
                            widget.namaPelanggan!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!_isLoading && _data != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${_data!.totalServis} servis',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: _buildBody(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _fetchRiwayat,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ringkasan card
          _buildRingkasanCard(theme, data),
          const SizedBox(height: 20),

          // Daftar servis header
          Text(
            'Daftar Servis',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          if (data.daftarServis.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada transaksi servis',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...data.daftarServis.map(
              (item) => _buildServisItem(theme, item),
            ),
        ],
      ),
    );
  }

  Widget _buildRingkasanCard(ThemeData theme, RiwayatServisPelanggan data) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info pelanggan
            Row(
              children: [
                Icon(Icons.person_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.namaPelanggan ?? '-',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (data.noTelepon != null && data.noTelepon!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 26, top: 4),
                child: Text(
                  'Telp: ${data.noTelepon}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (data.noWhatsapp != null && data.noWhatsapp!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 26, top: 2),
                child: Text(
                  'WA: ${data.noWhatsapp}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (data.alamat != null && data.alamat!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 26, top: 2),
                child: Text(
                  data.alamat!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Statistik
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: 'Total Servis',
                      value: data.totalServis.toString(),
                      valueStyle: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Total Biaya',
                      value: _fmtRupiah(data.totalBiayaFinal),
                      valueStyle: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Pendapatan Bersih',
                      value: _fmtRupiah(data.totalPendapatanBersih),
                      valueStyle: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServisItem(ThemeData theme, ItemRiwayatServis item) {
    final color = _statusColor(item.statusTerkini);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris atas: noServis + status
              Row(
                children: [
                  Icon(Icons.build_rounded,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.noServis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _labelStatus(item.statusTerkini),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Detail barang
              Row(
                children: [
                  Expanded(
                    child: _detailRow(
                      Icons.devices_rounded,
                      item.jenisBarang ?? '-',
                      item.merek != null ? '${item.merek}${item.modelSeri != null ? ' ${item.modelSeri}' : ''}' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Kerusakan
              if (item.kerusakan != null && item.kerusakan!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _detailRow(
                    Icons.warning_amber_rounded,
                    'Kerusakan: ${item.kerusakan}',
                    null,
                  ),
                ),

              // Biaya & tanggal
              Row(
                children: [
                  if (item.biayaFinal != null)
                    Text(
                      _fmtRupiah(item.biayaFinal),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  const Spacer(),
                  Icon(Icons.calendar_today_rounded,
                      size: 13, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDate(item.tglTerima),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (item.tglAmbil != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle_outline,
                        size: 13, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _fmtDate(item.tglAmbil),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String main, String? sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                main,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (sub != null)
                Text(
                  sub,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: valueStyle ??
                theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}