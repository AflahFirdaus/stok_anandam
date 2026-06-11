import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/transaksi_servis.dart';
import '../models/klaim_distributor.dart';
import '../models/servis_audit_log.dart';
import '../repositories/servis_repository.dart';
import '../widgets/klaim_distributor_dialog.dart';
import '../widgets/update_status_dialog.dart';
import 'package:stok_anandam/injection.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/token_storage.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/features/servis/utils/servis_print_utils.dart';
import 'package:stok_anandam/features/servis/widgets/pembayaran_dialog.dart';
import 'package:stok_anandam/core/routing/app_router.dart';

class ServisDetailPage extends StatefulWidget {
  final String id;
  const ServisDetailPage({super.key, required this.id});

  @override
  State<ServisDetailPage> createState() => _ServisDetailPageState();
}

class _ServisDetailPageState extends State<ServisDetailPage>
    with SingleTickerProviderStateMixin {
  final ServisRepository _repository = getIt<ServisRepository>();
  TransaksiServis? _transaksi;
  List<ServisAuditLog> _auditLogs = [];
  bool _isLoading = true;
  bool _isActioning = false;
  KlaimDistributor? _klaimData;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final allStatuses = [
        'BELUM_CEK',
        'SEDANG_CEK',
        'SEDANG_DIKERJAKAN',
        'SEDANG_TES',
        'TUNGGU_KONFIRMASI',
        'TUNGGU_SPAREPART',
        'BISA_DIAMBIL',
        'SUDAH_DIAMBIL',
        'BATAL',
        'KLAIM_MENUNGGU_PENGIRIMAN',
        'KLAIM_DIKIRIM',
        'KLAIM_SUDAH_DIKIRIM',
        'KLAIM_SUDAH_DIAMBIL',
      ];
      TransaksiServis? found;
      for (final status in allStatuses) {
        final pageable = await _repository.getTransaksiServisByStatus(
          status: status,
          size: 50,
        );
        for (final t in pageable.content) {
          if (t.id == widget.id) {
            found = t;
            break;
          }
        }
        if (found != null) break;
      }
      if (found == null) throw Exception('Data tidak ditemukan');

      final logs = await _repository.getAuditLogs(widget.id);

      KlaimDistributor? klaim;
      try {
        klaim = await _repository.getKlaimByTransaksiId(widget.id);
      } catch (_) {
        klaim = null;
      }

      if (mounted) {
        setState(() {
          _transaksi = found;
          _auditLogs = logs;
          _klaimData = klaim;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus,
      {String? kondisiServis,
      String? ketTindakan,
      int? teknisiId,
      String? tglDitangani,
      double? biayaFinal,
      double? modalSparepart,
      String? pengambilNama,
      String? durasiGaransi,
      String? statusBayar,
      String? modelSeriBaru}) async {
    await _updateStatusPayload({
      'statusBaru': newStatus,
      if (kondisiServis != null) 'kondisiServis': kondisiServis,
      if (ketTindakan != null) 'ketTindakan': ketTindakan,
      if (teknisiId != null) 'teknisiId': teknisiId,
      if (tglDitangani != null && tglDitangani.isNotEmpty) ...{
        'tglDitangani': tglDitangani,
        'tanggalDitangani': tglDitangani,
      },
      if (biayaFinal != null) 'biayaFinal': biayaFinal,
      if (modalSparepart != null) 'modalSparepart': modalSparepart,
      if (pengambilNama != null && pengambilNama.isNotEmpty)
        'pengambilNama': pengambilNama,
      if (durasiGaransi != null) 'durasiGaransi': durasiGaransi,
      if (statusBayar != null) 'statusBayar': statusBayar,
      if (modelSeriBaru != null && modelSeriBaru.isNotEmpty)
        'modelSeriBaru': modelSeriBaru,
    });
  }

  Future<void> _updateStatusPayload(Map<String, dynamic> payload) async {
    final targetStatus = payload['statusBaru']?.toString();
    setState(() => _isActioning = true);
    try {
      await _repository.updateStatusTransaksi(widget.id, payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
        if (targetStatus == 'SUDAH_DIAMBIL') {
          final shouldPrint = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cetak Nota Lunas'),
              content:
                  const Text('Apakah Anda ingin mencetak Nota Lunas sekarang?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Nanti Saja'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Ya, Cetak'),
                ),
              ],
            ),
          );
          if (mounted && shouldPrint == true && _transaksi != null) {
            ServisPrintUtils.printNotaServis(_transaksi!);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memperbarui status: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Future<void> _openUpdateStatusDialog(String targetStatus) async {
    if (targetStatus == 'SUDAH_DIAMBIL') {
      final current = _transaksi;
      final statusBayarSaatIni = current?.statusBayar ?? '';
      final isLunas = statusBayarSaatIni.toUpperCase() == 'LUNAS';

      if (!isLunas) {
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                const Expanded(child: Text('Konfirmasi Pengambilan')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status pembayaran saat ini:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    statusBayarSaatIni.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Barang akan ditandai SUDAH DIAMBIL meskipun status bayar belum LUNAS.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Harap pastikan Anda telah mencatat pembayaran secara manual. Dianjurkan untuk mengisi catatan alasan pengambilan barang sebelum lunas.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batalkan'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () => Navigator.of(context).pop(true),
                label: const Text('Lanjutkan Ambil'),
              ),
            ],
          ),
        );
        if (shouldProceed != true) return;
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => UpdateStatusDialog(
        targetStatus: targetStatus,
        transaksi: _transaksi,
      ),
    );
    if (result != null) {
      final current = _transaksi;
      if (targetStatus == 'SUDAH_DIAMBIL' && current != null) {
        result.putIfAbsent('kondisiServis', () => current.kondisiServis);
        result.putIfAbsent('ketTindakan', () => current.ketTindakan);
        result.putIfAbsent('durasiGaransi', () => current.durasiGaransi);
        result.putIfAbsent('biayaFinal', () => current.biayaFinal);
        result.putIfAbsent('modalSparepart', () => current.modalSparepart);
        result.putIfAbsent('statusBayar', () => current.statusBayar);
      }
      final payload = <String, dynamic>{'statusBaru': targetStatus};
      for (final key in [
        'kondisiServis',
        'ketTindakan',
        'teknisiId',
        'tglDitangani',
        'tanggalDitangani',
        'biayaFinal',
        'modalSparepart',
        'pengambilNama',
        'durasiGaransi',
        'statusBayar',
        'estimasiBiaya',
        'modelSeriBaru',
        'tglJatuhTempo',
        'tglAmbil',
        'metodePembayaran',
      ]) {
        if (result.containsKey(key)) payload[key] = result[key];
      }
      final tglDitangani = result['tglDitangani']?.toString();
      if (tglDitangani != null && tglDitangani.isNotEmpty) {
        payload['tanggalDitangani'] = tglDitangani;
      }
      await _updateStatusPayload(payload);
    }
  }

  Future<void> _openKlaimDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => KlaimDistributorDialog(transaksiId: widget.id),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _openPembayaranDialog() async {
    final t = _transaksi;
    if (t == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => PembayaranDialog(
        statusBayarSaatIni: t.statusBayar,
        biayaFinal: t.biayaFinal ?? t.estimasiBiaya,
        dp: t.dp,
        noServis: t.noServis,
      ),
    );
    if (result != null) {
      final jumlahBayar = result['jumlahBayar'] as double?;
      await _updateStatusPayload({
        'statusBaru': t.statusTerkini,
        'statusBayar': result['statusBayar'],
        'metodePembayaran': result['metodePembayaran'],
        if (jumlahBayar != null) 'biayaFinal': jumlahBayar,
        'catatanPublikLog':
            result['catatan']?.toString() ?? 'Pembayaran update',
      });
    }
  }

  Future<void> _sendWaNotification(String tipePesan) async {
    try {
      final link = await _repository.getWaLink(widget.id, tipePesan);
      if (link != null && link.isNotEmpty) {
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Tidak bisa membuka link WA';
        }
      } else {
        throw 'Link WA tidak tersedia dari server';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_transaksi == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Servis')),
        body: const Center(child: Text('Data tidak ditemukan.')),
      );
    }

    final t = _transaksi!;
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    final userStore = getIt<CurrentUserStore>();

    return DashboardShell(
      currentRoute: AppRoutes.servisDetail,
      userName: userStore.displayName,
      userRole: userStore.userRole,
      title: 'Detail Servis',
      onNavigate: (route) {
        if (route != AppRoutes.servisDetail) context.go(route);
      },
      onLogout: () {
        getIt<TokenStorage>().clear();
        getIt<CurrentUserStore>().clear();
        context.go(AppRoutes.login);
      },
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            // ── HEADER BAR ──────────────────────────────────────────────────
            FadeTransition(
              opacity: _fadeIn,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    BackButton(onPressed: () => context.pop()),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.noServis ?? 'Detail Servis',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            t.namaPelanggan ?? '',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (_isActioning)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    IconButton(
                      icon: const Icon(Icons.print_rounded),
                      tooltip: _transaksi?.statusTerkini == 'SUDAH_DIAMBIL'
                          ? 'Cetak Nota Lunas'
                          : 'Cetak Nota Servis',
                      onPressed: () {
                        if (_transaksi != null) {
                          ServisPrintUtils.printNotaServis(_transaksi!);
                        }
                      },
                    ),
                    if (_klaimData != null ||
                        (_transaksi?.statusTerkini?.startsWith('KLAIM') ==
                            true))
                      IconButton(
                        icon: const Icon(Icons.local_shipping_rounded),
                        tooltip: 'Cetak Nota Pengantar Klaim',
                        onPressed: () async {
                          try {
                            await ServisPrintUtils.printNotaPengantarKlaim(
                                widget.id);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal cetak: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.message_rounded),
                      tooltip: 'Kirim Notifikasi WA',
                      onSelected: _sendWaNotification,
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'DITERIMA',
                          child: ListTile(
                            dense: true,
                            leading:
                                Icon(Icons.inbox_rounded, color: Colors.blue),
                            title: Text('WA Barang Diterima'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'KENDALA',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.warning_rounded,
                                color: Colors.orange),
                            title: Text('WA Ada Kendala'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'SELESAI',
                          child: ListTile(
                            dense: true,
                            leading:
                                Icon(Icons.check_circle, color: Colors.green),
                            title: Text('WA Servis Selesai'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Info Utama', icon: Icon(Icons.info_outline)),
                Tab(
                    text: 'Tindakan & Biaya',
                    icon: Icon(Icons.build_circle_outlined)),
                Tab(
                    text: 'Klaim Distributor',
                    icon: Icon(Icons.local_shipping_outlined)),
                Tab(text: 'Audit Log', icon: Icon(Icons.history)),
              ],
            ),
            Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            Expanded(
              child: FadeTransition(
                opacity: _fadeIn,
                child: TabBarView(
                  children: [
                    _buildInfoUtamaTab(t, theme, isDesktop),
                    _buildTindakanBiayaTab(t, theme, isDesktop),
                    _buildKlaimTab(t, theme),
                    _buildAuditLogTab(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 1 : INFO UTAMA (DESKTOP: 2 kolom sama lebar + no white space)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInfoUtamaTab(
      TransaksiServis t, ThemeData theme, bool isDesktop) {
    if (isDesktop) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Full-width status badge
            _StatusTimelineCard(transaksi: t, auditLogs: _auditLogs),
            const SizedBox(height: 20),
            // 2 equal columns — no SizedBox wrappers
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── KOLOM KIRI ─────────────────────────────────────────
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildActionPanel(t, theme),
                      const SizedBox(height: 16),
                      _DetailCard(
                        title: 'Personel',
                        icon: Icons.badge_rounded,
                        rows: [
                          _InfoRow('Penerima', t.namaPenerima),
                          _InfoRow('Penyerah', t.namaPenyerah),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DetailCard(
                        title: 'Tanggal',
                        icon: Icons.calendar_today_rounded,
                        rows: [
                          _InfoRow('Tgl Terima', _formatDate(t.tglTerima)),
                          _InfoRow('Tgl Ambil', _formatDate(t.tglAmbil)),
                          _InfoRow('Pengambil', t.pengambilNama),
                        ],
                      ),
                      if (_klaimData != null) ...[
                        const SizedBox(height: 16),
                        _DetailCard(
                          title: 'Klaim Distributor',
                          icon: Icons.local_shipping_rounded,
                          rows: [
                            _InfoRow('Nama Distributor',
                                _klaimData!.namaDistributor ?? '-'),
                            _InfoRow(
                                'Alamat', _klaimData!.alamatDistributor ?? '-'),
                            _InfoRow('Resi', _klaimData!.resiPengiriman ?? '-'),
                            _InfoRow('Biaya Klaim',
                                _formatRupiah(_klaimData!.biayaKlaim)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // ── KOLOM KANAN ────────────────────────────────────────
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _DetailCard(
                        title: 'Data Pelanggan',
                        icon: Icons.person_rounded,
                        rows: [
                          _InfoRow('Nama', t.namaPelanggan),
                          _InfoRow('No Telepon', t.noTelepon),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DetailCard(
                        title: 'Data Barang',
                        icon: Icons.devices_rounded,
                        rows: [
                          _InfoRow('Jenis Barang', t.jenisBarang),
                          _InfoRow('Merek', t.merek),
                          if (t.modelSeriLama != null &&
                              t.modelSeriLama!.isNotEmpty)
                            _InfoRow('SN Lama', t.modelSeriLama),
                          _InfoRow('Serial Number', t.modelSeri),
                          _InfoRow('Kelengkapan', t.kelengkapan),
                          _InfoRow('Keluhan', t.kerusakan),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DetailCard(
                        title: 'Estimasi Biaya',
                        icon: Icons.payments_rounded,
                        rows: [
                          _InfoRow('Estimasi', _formatRupiah(t.estimasiBiaya)),
                          _InfoRow('DP', _formatRupiah(t.dp)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ── Mobile ────────────────────────────────────────────────────────────
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatusTimelineCard(transaksi: t, auditLogs: _auditLogs),
          const SizedBox(height: 12),
          _buildActionPanel(t, theme),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Data Pelanggan',
            icon: Icons.person_rounded,
            rows: [
              _InfoRow('Nama', t.namaPelanggan),
              _InfoRow('No Telepon', t.noTelepon),
            ],
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Data Barang',
            icon: Icons.devices_rounded,
            rows: [
              _InfoRow('Jenis Barang', t.jenisBarang),
              _InfoRow('Merek', t.merek),
              if (t.modelSeriLama != null && t.modelSeriLama!.isNotEmpty)
                _InfoRow('SN Lama', t.modelSeriLama),
              _InfoRow('Serial Number', t.modelSeri),
              _InfoRow('Kelengkapan', t.kelengkapan),
              _InfoRow('Keluhan', t.kerusakan),
            ],
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Estimasi Biaya',
            icon: Icons.payments_rounded,
            rows: [
              _InfoRow('Estimasi', _formatRupiah(t.estimasiBiaya)),
              _InfoRow('DP', _formatRupiah(t.dp)),
            ],
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Personel',
            icon: Icons.badge_rounded,
            rows: [
              _InfoRow('Penerima', t.namaPenerima),
              _InfoRow('Penyerah', t.namaPenyerah),
            ],
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Tanggal',
            icon: Icons.calendar_today_rounded,
            rows: [
              _InfoRow('Tgl Terima', _formatDate(t.tglTerima)),
              _InfoRow('Tgl Ambil', _formatDate(t.tglAmbil)),
              _InfoRow('Pengambil', t.pengambilNama),
            ],
          ),
          if (_klaimData != null) ...[
            const SizedBox(height: 12),
            _DetailCard(
              title: 'Klaim Distributor',
              icon: Icons.local_shipping_rounded,
              rows: [
                _InfoRow(
                    'Nama Distributor', _klaimData!.namaDistributor ?? '-'),
                _InfoRow('Alamat', _klaimData!.alamatDistributor ?? '-'),
                _InfoRow('Resi', _klaimData!.resiPengiriman ?? '-'),
                _InfoRow('Biaya Klaim', _formatRupiah(_klaimData!.biayaKlaim)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 2 : TINDAKAN & BIAYA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTindakanBiayaTab(
      TransaksiServis t, ThemeData theme, bool isDesktop) {
    String formatValue(String? value, {String suffix = ''}) {
      return (value != null && value.isNotEmpty && value != 'null')
          ? '$value $suffix'.trim()
          : '-';
    }

    final content = Column(
      children: [
        _DetailCard(
          title: 'Tindakan Teknisi',
          icon: Icons.build_circle_rounded,
          rows: [
            _InfoRow('Teknisi', formatValue(t.namaTeknisi)),
            _InfoRow('Tgl Ditangani', _formatDate(t.tglDitangani)),
            _InfoRow('Kondisi Servis', formatValue(t.kondisiServis)),
            _InfoRow('Keterangan', formatValue(t.ketTindakan)),
          ],
        ),
        const SizedBox(height: 16),
        _DetailCard(
          title: 'Informasi Biaya & Garansi',
          icon: Icons.payments_rounded,
          rows: [
            _InfoRow('Estimasi', _formatRupiah(t.estimasiBiaya)),
            _InfoRow('DP', _formatRupiah(t.dp)),
            _InfoRow('Biaya Final', _formatRupiah(t.biayaFinal)),
            _InfoRow('Modal Sparepart', _formatRupiah(t.modalSparepart)),
            _InfoRow('Status Bayar', formatValue(t.statusBayar)),
            _InfoRow('Garansi', t.durasiGaransi ?? '-'),
          ],
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: isDesktop
          ? Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: content))
          : content,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 3 : KLAIM DISTRIBUTOR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildKlaimTab(TransaksiServis t, ThemeData theme) {
    final status = t.statusTerkini ?? '';
    final klaim = _klaimData;
    final isStatusKlaim = status.startsWith('KLAIM');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              if (klaim != null)
                _DetailCard(
                  title: 'Data Klaim Distributor',
                  icon: Icons.local_shipping,
                  rows: [
                    _InfoRow('Status', status.replaceAll('_', ' ')),
                    _InfoRow('Nama Distributor', klaim.namaDistributor ?? '-'),
                    _InfoRow(
                        'Alamat Distributor', klaim.alamatDistributor ?? '-'),
                    _InfoRow('Resi Pengiriman', klaim.resiPengiriman ?? '-'),
                    _InfoRow('Biaya Klaim', _formatRupiah(klaim.biayaKlaim)),
                    _InfoRow('Tgl Kirim', _formatDate(klaim.tanggalKirim)),
                    _InfoRow('Tgl Kembali', _formatDate(klaim.tanggalKembali)),
                  ],
                ),
              if (isStatusKlaim && klaim == null)
                const Card(
                  color: Color(0xFFFFF3E0),
                  elevation: 0,
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('Memuat data klaim...'),
                    ),
                  ),
                ),
              if (!isStatusKlaim && klaim == null)
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  elevation: 0,
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                          'Belum ada data klaim distributor untuk transaksi ini.'),
                    ),
                  ),
                ),
              if (klaim != null || isStatusKlaim) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.local_shipping_rounded),
                    label: const Text('🖨️ Cetak Nota Pengantar Klaim'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      try {
                        await ServisPrintUtils.printNotaPengantarKlaim(
                            widget.id);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal cetak: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
              if (!isStatusKlaim && klaim == null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Buat Klaim Distributor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (_) =>
                            KlaimDistributorDialog(transaksiId: widget.id),
                      );
                      if (result == true) {
                        _loadData();
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 4 : AUDIT LOG
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAuditLogTab(ThemeData theme) {
    if (_auditLogs.isEmpty) {
      return const Center(child: Text('Belum ada riwayat aktivitas.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _auditLogs.length,
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        final dt = DateTime.tryParse(log.createdAt ?? '');
        final timeStr =
            dt != null ? DateFormat('dd MMM yyyy HH:mm').format(dt) : '-';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(timeStr,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        log.aksi ?? 'UNKNOWN',
                        style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(log.keterangan ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                        '${log.karyawanNama ?? "Sistem"} (${log.karyawanRole ?? "-"})',
                        style: theme.textTheme.bodySmall),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionPanel(TransaksiServis t, ThemeData theme) {
    final status = t.statusTerkini ?? '';
    final isKlaim =
        status.startsWith('KLAIM') && status != 'KLAIM_SUDAH_DIAMBIL';
    final isDone = status == 'SUDAH_DIAMBIL' || status == 'BATAL';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.flash_on_rounded,
                      size: 16, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 8),
                Text('Aksi Cepat',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (isDone)
              _buildLockedStatus(theme)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (status == 'KLAIM_MENUNGGU_PENGIRIMAN')
                    _ActionButton(
                      label: 'Tandai Dikirim',
                      icon: Icons.local_shipping_rounded,
                      color: Colors.deepOrange,
                      onTap: () => _openUpdateStatusDialog('KLAIM_DIKIRIM'),
                    ),
                  if (status == 'KLAIM_DIKIRIM')
                    _ActionButton(
                      label: 'Tandai Diterima Distributor',
                      icon: Icons.check_circle_rounded,
                      color: Colors.blue,
                      onTap: () =>
                          _openUpdateStatusDialog('KLAIM_SUDAH_DIKIRIM'),
                    ),
                  if (status == 'KLAIM_SUDAH_DIKIRIM')
                    _ActionButton(
                      label: 'Selesaikan Klaim',
                      icon: Icons.done_all_rounded,
                      color: Colors.teal,
                      onTap: () =>
                          _openUpdateStatusDialog('KLAIM_SUDAH_DIAMBIL'),
                    ),
                  if (!isDone &&
                      !isKlaim &&
                      status != 'BATAL' &&
                      status != 'KLAIM_SUDAH_DIAMBIL' &&
                      status != 'BELUM_CEK' &&
                      status != 'SEDANG_CEK')
                    _ActionButton(
                      label: t.statusBayar == 'LUNAS'
                          ? 'Status Bayar: LUNAS'
                          : 'Bayar / Lunas',
                      icon: Icons.payments_rounded,
                      color: t.statusBayar == 'LUNAS'
                          ? Colors.green
                          : Colors.orange,
                      onTap: _openPembayaranDialog,
                    ),
                  if (!isKlaim) ...[
                    if (status == 'BELUM_CEK')
                      _ActionButton(
                        label: 'Mulai Cek',
                        icon: Icons.search_rounded,
                        color: Colors.blue,
                        onTap: () => _updateStatusPayload({
                          'statusBaru': 'SEDANG_CEK',
                        }),
                      ),
                    if (status == 'SEDANG_CEK')
                      _ActionButton(
                        label: 'Mulai Kerjakan',
                        icon: Icons.build_rounded,
                        color: Colors.indigo,
                        onTap: () =>
                            _openUpdateStatusDialog('SEDANG_DIKERJAKAN'),
                      ),
                    if (status == 'SEDANG_DIKERJAKAN')
                      _ActionButton(
                        label: 'Mulai Tes',
                        icon: Icons.play_circle_rounded,
                        color: Colors.purple,
                        onTap: () => _openUpdateStatusDialog('SEDANG_TES'),
                      ),
                    if (status == 'KLAIM_SUDAH_DIAMBIL')
                      _ActionButton(
                        label: 'Barang Kembali dari Klaim',
                        icon: Icons.assignment_return_rounded,
                        color: Colors.purple,
                        onTap: () => _openUpdateStatusDialog('SEDANG_TES'),
                      ),
                    if (status == 'SEDANG_TES')
                      _ActionButton(
                        label: 'Bisa Diambil',
                        icon: Icons.check_circle_rounded,
                        color: Colors.green,
                        onTap: () => _openUpdateStatusDialog('BISA_DIAMBIL'),
                      ),
                    if (status == 'BISA_DIAMBIL')
                      _ActionButton(
                        label: t.statusBayar == 'LUNAS'
                            ? 'Barang Diambil / Selesai'
                            : 'Barang Diambil / Selesai',
                        icon: Icons.done_all_rounded,
                        color: t.statusBayar == 'LUNAS'
                            ? Colors.teal
                            : Colors.grey,
                        onTap: () {
                          if (t.statusBayar == 'LUNAS') {
                            _openUpdateStatusDialog('SUDAH_DIAMBIL');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Lunasi pembayaran terlebih dahulu sebelum mengambil barang!'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      ),
                    if (status == 'TUNGGU_KONFIRMASI')
                      _ActionButton(
                        label: 'Mulai Kerjakan',
                        icon: Icons.build_rounded,
                        color: Colors.indigo,
                        onTap: () =>
                            _openUpdateStatusDialog('SEDANG_DIKERJAKAN'),
                      ),
                    if (status == 'SEDANG_CEK' ||
                        status == 'SEDANG_DIKERJAKAN' ||
                        status == 'SEDANG_TES') ...[
                      _ActionButton(
                        label: 'Tunggu Konfirmasi',
                        icon: Icons.pending_rounded,
                        color: Colors.amber.shade700,
                        onTap: () =>
                            _openUpdateStatusDialog('TUNGGU_KONFIRMASI'),
                      ),
                      _ActionButton(
                        label: 'Tunggu Sparepart',
                        icon: Icons.inventory_2_rounded,
                        color: Colors.orange,
                        onTap: () =>
                            _openUpdateStatusDialog('TUNGGU_SPAREPART'),
                      ),
                    ],
                    _ActionButton(
                      label: 'Klaim Distributor',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.deepOrange,
                      outlined: true,
                      onTap: _openKlaimDialog,
                    ),
                  ],
                  _ActionButton(
                    label: 'Batalkan',
                    icon: Icons.cancel_rounded,
                    color: Colors.red,
                    outlined: true,
                    onTap: () => _openUpdateStatusDialog('BATAL'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded,
              size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text('Transaksi sudah selesai / dikunci',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  String _formatRupiah(double? value) {
    if (value == null || value == 0) return '-';
    final fmt = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
    return fmt.format(value);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return dateStr;
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Timeline status yang menampilkan history status dari audit log.
/// - Status sebelumnya ditampilkan sebagai dot kecil dengan garis penghubung.
/// - Status terkini di paling kanan dengan animasi pulse dan warna menonjol.
class _StatusTimelineCard extends StatefulWidget {
  final TransaksiServis transaksi;
  final List<ServisAuditLog> auditLogs;

  const _StatusTimelineCard({
    required this.transaksi,
    required this.auditLogs,
  });

  @override
  State<_StatusTimelineCard> createState() => _StatusTimelineCardState();
}

class _StatusTimelineCardState extends State<_StatusTimelineCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Ambil semua status unik dari audit log dengan urutan kronologis
    final statusFlow = _extractStatusFlow(widget.transaksi, widget.auditLogs);
    final currentStatus = widget.transaksi.statusTerkini ?? 'MENUNGGU';

    return Card(
      elevation: 0,
      color: _statusColor(currentStatus).withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: _statusColor(currentStatus).withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline_rounded,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('Riwayat Status',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                // Status terkini badge
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(currentStatus),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _statusColor(currentStatus)
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          currentStatus.replaceAll('_', ' '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Timeline horizontal
            SizedBox(
              height:
                  80, // [PERBAIKAN 1] Diperbesar dari 60 ke 80 agar teks multiline tidak terpotong
              child: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: statusFlow.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final s = statusFlow[index];
                        final isLast = index == statusFlow.length - 1;
                        final color = _statusColor(s);
                        final icon = _statusIcons(s);

                        // [PERBAIKAN 2] Gunakan SizedBox dengan lebar tetap alih-alih IntrinsicWidth
                        return SizedBox(
                          width: isLast
                              ? 80
                              : 130, // Perlebar jarak antar dot menjadi 130px
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // [PERBAIKAN 3] Rata kiri sejajar dengan dot
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Dot dan line
                              SizedBox(
                                height: 28,
                                child: Row(
                                  children: [
                                    // Dot
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isLast
                                            ? color
                                            : color.withValues(alpha: 0.3),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: color,
                                          width: isLast ? 2.5 : 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        icon,
                                        size: 14,
                                        color: isLast
                                            ? Colors.white
                                            : color.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    // Connecting line
                                    if (!isLast)
                                      Expanded(
                                        // [PERBAIKAN 4] Gunakan Expanded agar garis otomatis mengisi sisa ruang
                                        child: Container(
                                          height: 2,
                                          color: color.withValues(alpha: 0.35),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Status label
                              Padding(
                                padding: const EdgeInsets.only(
                                    right:
                                        12.0), // [PERBAIKAN 5] Beri jarak kanan agar tak tumpang tindih
                                child: Text(
                                  s.replaceAll('_', ' '),
                                  maxLines:
                                      2, // Izinkan teks turun ke baris ke-2 jika panjang
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize:
                                        10, // Sedikit dinaikkan dari 9 agar lebih mudah dibaca
                                    height: 1.2, // Jarak line-height agar rapi
                                    fontWeight: isLast
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isLast
                                        ? color
                                        : theme.colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (widget.transaksi.kondisiServis != null &&
                      widget.transaksi.kondisiServis!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.transaksi.kondisiServis!,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ekstrak daftar status dalam urutan kronologis berdasarkan:
  /// 1. Data dari audit log (oldValue → newValue)
  /// 2. Fallback: urutan dari status awal sampai status terkini
  List<String> _extractStatusFlow(
      TransaksiServis t, List<ServisAuditLog> logs) {
    final current = t.statusTerkini ?? 'MENUNGGU';

    // Kumpulan semua status yang valid (untuk menyaring data kotor dari log)
    const validStatuses = [
      'BELUM_CEK',
      'SEDANG_CEK',
      'SEDANG_DIKERJAKAN',
      'SEDANG_TES',
      'TUNGGU_KONFIRMASI',
      'TUNGGU_SPAREPART',
      'BISA_DIAMBIL',
      'SUDAH_DIAMBIL',
      'BATAL',
      'KLAIM_MENUNGGU_PENGIRIMAN',
      'KLAIM_DIKIRIM',
      'KLAIM_SUDAH_DIKIRIM',
      'KLAIM_SUDAH_DIAMBIL',
      'MENUNGGU'
    ];

    // =========================================================================
    // SKENARIO 1: Bangun alur historis nyata dari Audit Log
    // Ini menyelesaikan masalah transisi (misal: Servis -> tiba-tiba Klaim)
    // =========================================================================
    final List<String> flow = [];
    for (final log in logs) {
      final ket = (log.keterangan ?? '').trim();

      // Asumsi format di log: "STATUS_LAMA → STATUS_BARU"
      final parts = ket.split('→');

      for (final raw in parts) {
        final s = raw.trim().toUpperCase();
        if (validStatuses.contains(s)) {
          // Hindari duplikasi berurutan (misal: A -> B, B -> C, jangan sampai B masuk 2x)
          if (flow.isEmpty || flow.last != s) {
            flow.add(s);
          }
        }
      }
    }

    // Jika log berhasil membentuk alur, pastikan status terkini ada di ujung
    if (flow.isNotEmpty) {
      if (!flow.contains(current)) {
        flow.add(current);
      } else if (flow.last != current) {
        // Jika current ada tapi nyelip di tengah (jarang terjadi), pindahkan ke akhir
        flow.remove(current);
        flow.add(current);
      }
      return flow;
    }

    // =========================================================================
    // SKENARIO 2: FALLBACK JIKA AUDIT LOG KOSONG (Misal: Data baru dibuat)
    // Pisahkan master flow agar Klaim dan Servis tidak dipaksa nyambung!
    // =========================================================================
    const serviceFlow = [
      'BELUM_CEK',
      'SEDANG_CEK',
      'SEDANG_DIKERJAKAN',
      'SEDANG_TES',
      'TUNGGU_KONFIRMASI',
      'TUNGGU_SPAREPART',
      'BISA_DIAMBIL',
      'SUDAH_DIAMBIL'
    ];

    const claimFlow = [
      'KLAIM_MENUNGGU_PENGIRIMAN',
      'KLAIM_DIKIRIM',
      'KLAIM_SUDAH_DIKIRIM',
      'KLAIM_SUDAH_DIAMBIL'
    ];

    final List<String> fallbackFlow = [];

    if (current.startsWith('KLAIM_')) {
      // Kasus A: Jika ini status Klaim (langsung klaim dari awal)
      for (final s in claimFlow) {
        fallbackFlow.add(s);
        if (s == current) break;
      }
    } else if (current == 'BATAL') {
      // Kasus B: Langsung Batal
      fallbackFlow.addAll(['BELUM_CEK', 'BATAL']);
    } else {
      // Kasus C: Servis Reguler
      for (final s in serviceFlow) {
        fallbackFlow.add(s);
        if (s == current) break;
      }
    }

    // Safeguard: Jika current status tidak dikenali ('MENUNGGU' dsb)
    if (fallbackFlow.isEmpty || !fallbackFlow.contains(current)) {
      fallbackFlow.add(current);
    }

    debugPrint(
        '[_StatusTimelineCard] flow=$fallbackFlow current=$current logs=${logs.length}');

    return fallbackFlow;
  }

  Color _statusColor(String status) {
    if (status.startsWith('KLAIM')) return Colors.deepOrange;
    switch (status) {
      case 'BELUM_CEK':
        return Colors.grey;
      case 'SEDANG_CEK':
        return Colors.blue;
      case 'SEDANG_DIKERJAKAN':
        return Colors.indigo;
      case 'SEDANG_TES':
        return Colors.purple;
      case 'TUNGGU_KONFIRMASI':
        return Colors.amber;
      case 'TUNGGU_SPAREPART':
        return Colors.orange;
      case 'BISA_DIAMBIL':
        return Colors.green;
      case 'SUDAH_DIAMBIL':
        return Colors.teal;
      case 'BATAL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcons(String status) {
    if (status.startsWith('KLAIM')) return Icons.send_rounded;
    switch (status) {
      case 'BELUM_CEK':
        return Icons.hourglass_empty_rounded;
      case 'SEDANG_CEK':
        return Icons.search_rounded;
      case 'SEDANG_DIKERJAKAN':
        return Icons.build_rounded;
      case 'SEDANG_TES':
        return Icons.play_circle_rounded;
      case 'TUNGGU_KONFIRMASI':
        return Icons.pending_rounded;
      case 'TUNGGU_SPAREPART':
        return Icons.inventory_2_rounded;
      case 'BISA_DIAMBIL':
        return Icons.check_circle_rounded;
      case 'SUDAH_DIAMBIL':
        return Icons.done_all_rounded;
      case 'BATAL':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

/// Reusable info card — all cards identical shape, padding, border.
class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...rows.map((r) => r.buildWidget(context)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String? value;
  const _InfoRow(this.label, this.value);

  Widget buildWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          const Text(' : '),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : '-',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        icon: Icon(icon, size: 16, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 12)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
      );
    }
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
    );
  }
}
