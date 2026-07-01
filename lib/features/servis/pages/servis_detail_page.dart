import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/transaksi_servis.dart';
import '../models/klaim_distributor.dart';
import '../models/servis_audit_log.dart';
import '../repositories/servis_repository.dart';
import '../widgets/klaim_distributor_dialog.dart';
import '../widgets/servis_edit_dialog.dart';
import '../widgets/update_status_dialog.dart';
import 'package:stok_anandam/injection.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/token_storage.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/features/servis/utils/servis_print_utils.dart';
import 'package:stok_anandam/features/servis/widgets/pembayaran_dialog.dart';
import 'package:stok_anandam/core/errors/app_errors.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/core/widgets/app_feedback.dart';

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
      // 🔥 PERBAIKAN: Gunakan endpoint getTransaksiById langsung, bukan loop
      // semua status dengan pagination yang riskan miss.
      final transaksi = await _repository.getTransaksiById(widget.id);

      final logs = await _repository.getAuditLogs(widget.id);

      KlaimDistributor? klaim;
      try {
        klaim = await _repository.getKlaimByTransaksiId(widget.id);
      } catch (_) {
        klaim = null;
      }

      if (mounted) {
        setState(() {
          _transaksi = transaksi;
          _auditLogs = logs;
          _klaimData = klaim;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
            context,
            AppErrors.userMessageFromException(e,
                fallback: 'Gagal memuat data servis.'));
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
    final targetStatus = payload['statusBaru']?.toString() ?? '';
    debugPrint('===== _updateStatusPayload =====');
    debugPrint('targetStatus: $targetStatus');
    debugPrint('payload: $payload');
    debugPrint('================================');
    setState(() => _isActioning = true);
    try {
      if (targetStatus.startsWith('KLAIM') && _klaimData?.id != null) {
        await _repository.updateStatusKlaim(_klaimData!.id!, payload);
      } else {
        await _repository.updateStatusTransaksi(widget.id, payload);
      }

      if (mounted) {
        AppFeedback.showSuccess(context, 'Status berhasil diperbarui');
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
        AppFeedback.showError(
            context,
            AppErrors.userMessageFromException(e,
                fallback: 'Gagal memperbarui status servis.'));
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
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Konfirmasi Pengambilan')),
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
        // Selalu sertakan tglAmbil (tanggal sekarang) jika belum ada
        result.putIfAbsent(
            'tglAmbil', () => DateFormat('yyyy-MM-dd').format(DateTime.now()));
        // Gunakan penyerahId (integer) dari user yang sedang login
        final userStore = getIt<CurrentUserStore>();
        final penyerahId = userStore.userId;
        final penyerahNama = userStore.displayName;
        if (penyerahId != null) {
          result['penyerahId'] = penyerahId;
        }
        // Kirim juga nama sebagai fallback jika server mendukung
        if (penyerahNama.isNotEmpty) {
          result['penyerahNama'] = penyerahNama;
        }
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
        'penyerahId',
        'penyerahNama',
        'durasiGaransi',
        'statusBayar',
        'estimasiBiaya',
        'modelSeriBaru',
        'tglJatuhTempo',
        'tglAmbil',
        'metodePembayaran',
      ]) {
        if (result.containsKey(key) && result[key] != null) {
          payload[key] = result[key];
        }
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
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Link WA tidak tersedia dari server';
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
            context,
            AppErrors.userMessageFromException(e,
                fallback: 'Gagal mengirim notifikasi WhatsApp.'));
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
                    // Edit button - only enabled when status is before SEDANG_DIKERJAKAN
                    Builder(
                      builder: (context) {
                        final status = _transaksi?.statusTerkini ?? '';
                        final cannotEditStatuses = [
                          'SEDANG_DIKERJAKAN',
                          'SEDANG_TES',
                          'BISA_DIAMBIL',
                          'SUDAH_DIAMBIL',
                          'BATAL',
                          'KLAIM_DIKIRIM',
                          'KLAIM_SUDAH_DIKIRIM',
                          'KLAIM_SUDAH_DIAMBIL',
                        ];
                        final canEdit = !cannotEditStatuses.contains(status);
                        return IconButton(
                          icon: Icon(
                            Icons.edit_rounded,
                            color: canEdit
                                ? null
                                : Theme.of(context).colorScheme.outline,
                          ),
                          tooltip: canEdit
                              ? 'Edit Nota Servis'
                              : 'Tidak bisa diedit (status: ${status.replaceAll('_', ' ') ?? '-'})',
                          onPressed: canEdit && _transaksi?.id != null
                              ? () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => ServisEditDialog(
                                      transaksi: _transaksi!,
                                    ),
                                  );
                                  if (result == true) {
                                    _loadData();
                                  }
                                }
                              : null,
                        );
                      },
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
                              AppFeedback.showError(
                                  context,
                                  AppErrors.userMessageFromException(
                                    e,
                                    fallback:
                                        'Gagal mencetak nota pengantar klaim.',
                                  ));
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

  Widget _buildInfoUtamaTab(
      TransaksiServis t, ThemeData theme, bool isDesktop) {
    if (isDesktop) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            t.statusTerkini?.startsWith('KLAIM') == true
                ? _KlaimTimelineCard(
                    transaksi: t,
                    onStatusTap: (status) => _openUpdateStatusDialog(status),
                  )
                : _StatusTimelineCard(
                    transaksi: t,
                    auditLogs: _auditLogs,
                    onStatusTap: (status) => _openUpdateStatusDialog(status),
                  ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          t.statusTerkini?.startsWith('KLAIM') == true
              ? _KlaimTimelineCard(
                  transaksi: t,
                  onStatusTap: (status) => _openUpdateStatusDialog(status),
                )
              : _StatusTimelineCard(
                  transaksi: t,
                  auditLogs: _auditLogs,
                  onStatusTap: (status) => _openUpdateStatusDialog(status),
                ),
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
              // ═══ Klaim Status Timeline ═════════════════════════════
              _KlaimTimelineCard(
                transaksi: t,
                onStatusTap: (status) => _openUpdateStatusDialog(status),
              ),
              const SizedBox(height: 16),

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
                if (klaim != null && status == 'KLAIM_MENUNGGU_PENGIRIMAN') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit Data Klaim'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepOrange,
                        side: const BorderSide(color: Colors.deepOrange),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (_) => KlaimDistributorDialog(
                            transaksiId: widget.id,
                            existingKlaim: klaim,
                          ),
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                    ),
                  ),
                ],
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
                          AppFeedback.showError(
                              context,
                              AppErrors.userMessageFromException(
                                e,
                                fallback:
                                    'Gagal mencetak nota pengantar klaim.',
                              ));
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

  Widget _buildAuditLogTab(ThemeData theme) {
    if (_auditLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('Belum ada riwayat aktivitas.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Riwayat perubahan akan muncul di sini.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: _auditLogs.length + 1, // +1 untuk header
      itemBuilder: (context, index) {
        // Header statistik
        if (index == 0) {
          final totalLogs = _auditLogs.length;
          final uniqueActors = _auditLogs
              .map((e) => e.karyawanNama)
              .where((n) => n != null && n.isNotEmpty)
              .toSet()
              .length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                _StatBadge(
                  icon: Icons.history_rounded,
                  label: '$totalLogs Log',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _StatBadge(
                  icon: Icons.person_rounded,
                  label: '$uniqueActors Aktor',
                  color: theme.colorScheme.tertiary,
                ),
                const Spacer(),
                Text(
                  'Terbaru',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }

        final log = _auditLogs[index - 1];
        final dt = DateTime.tryParse(log.createdAt ?? '');
        final timeStr =
            dt != null ? DateFormat('dd MMM yyyy HH:mm').format(dt) : '-';
        // Tentukan warna dan ikon berdasarkan tipe aksi
        IconData actionIcon;
        Color actionColor;
        Color badgeBgColor;
        Color badgeTextColor;

        switch (log.aksi) {
          case 'PEMBUATAN NOTA':
            actionIcon = Icons.add_circle_rounded;
            actionColor = Colors.green.shade700;
            badgeBgColor = Colors.green.shade50;
            badgeTextColor = Colors.green.shade800;
            break;
          case 'PERUBAHAN STATUS':
            actionIcon = Icons.swap_horiz_rounded;
            actionColor = Colors.blue.shade700;
            badgeBgColor = Colors.blue.shade50;
            badgeTextColor = Colors.blue.shade800;
            break;
          case 'PERUBAHAN SN':
            actionIcon = Icons.qr_code_rounded;
            actionColor = Colors.purple.shade700;
            badgeBgColor = Colors.purple.shade50;
            badgeTextColor = Colors.purple.shade800;
            break;
          case 'PENGAJUAN KLAIM':
            actionIcon = Icons.local_shipping_rounded;
            actionColor = Colors.deepOrange.shade700;
            badgeBgColor = Colors.deepOrange.shade50;
            badgeTextColor = Colors.deepOrange.shade800;
            break;
          case 'STATUS KLAIM':
            actionIcon = Icons.sync_alt_rounded;
            actionColor = Colors.teal.shade700;
            badgeBgColor = Colors.teal.shade50;
            badgeTextColor = Colors.teal.shade800;
            break;
          case 'EDIT NOTA':
            actionIcon = Icons.edit_rounded;
            actionColor = Colors.indigo.shade700;
            badgeBgColor = Colors.indigo.shade50;
            badgeTextColor = Colors.indigo.shade800;
            break;
          default:
            actionIcon = Icons.edit_note_rounded;
            actionColor = Colors.orange.shade700;
            badgeBgColor = Colors.orange.shade50;
            badgeTextColor = Colors.orange.shade800;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline dot / icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(actionIcon, color: actionColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row: badge + time
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBgColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                log.aksi ?? 'AKSI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: badgeTextColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeStr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Keterangan
                        Text(
                          log.keterangan ?? '-',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Actor info
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_rounded,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(
                                log.karyawanNama ?? 'Sistem',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (log.karyawanRole != null &&
                                  log.karyawanRole!.isNotEmpty &&
                                  log.karyawanRole != '-') ...[
                                const SizedBox(width: 4),
                                Text(
                                  '• ${log.karyawanRole}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _StatBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel(TransaksiServis t, ThemeData theme) {
    final status = t.statusTerkini ?? '';
    final isKlaim =
        status.startsWith('KLAIM') && status != 'KLAIM_SUDAH_DIAMBIL';
    final isDone = status == 'BATAL';

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
                            AppFeedback.showError(context,
                                'Lunasi pembayaran terlebih dahulu sebelum mengambil barang!');
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
                    // Batalkan hanya muncul setelah SUDAH_DIAMBIL
                    if (status == 'SUDAH_DIAMBIL')
                      _ActionButton(
                        label: 'Batalkan Servis',
                        icon: Icons.cancel_rounded,
                        color: Colors.red,
                        outlined: true,
                        onTap: () => _openUpdateStatusDialog('BATAL'),
                      ),
                  ],
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

/// Horizontal timeline with BIG dots for 3 main proses, SMALL dots for sub-statuses.
/// Every dot shows its status label below. Current dot is highlighted with glow animation.
class _StatusTimelineCard extends StatefulWidget {
  final TransaksiServis transaksi;
  final List<ServisAuditLog> auditLogs;
  final void Function(String status)? onStatusTap;

  const _StatusTimelineCard({
    required this.transaksi,
    required this.auditLogs,
    this.onStatusTap,
  });

  @override
  State<_StatusTimelineCard> createState() => _StatusTimelineCardState();
}

class _StatusTimelineCardState extends State<_StatusTimelineCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;

  static const List<_GroupDef> _groups = [
    _GroupDef('PROSES PENERIMAAN', [
      'BELUM_CEK',
      'SEDANG_CEK',
      'TUNGGU_KONFIRMASI',
      'TUNGGU_SPAREPART',
    ]),
    _GroupDef('PROSES PENGERJAAN', [
      'SEDANG_DIKERJAKAN',
      'SEDANG_TES',
    ]),
    _GroupDef('SELESAI PROSES', [
      'BISA_DIAMBIL',
      'SUDAH_DIAMBIL',
      'BATAL',
    ]),
  ];

  static const List<String> _masterOrder = [
    'BELUM_CEK',
    'SEDANG_CEK',
    'TUNGGU_KONFIRMASI',
    'TUNGGU_SPAREPART',
    'SEDANG_DIKERJAKAN',
    'SEDANG_TES',
    'BISA_DIAMBIL',
    'SUDAH_DIAMBIL',
    'BATAL',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _mapToDisplay(String status) {
    if (status.startsWith('KLAIM')) return 'SEDANG_DIKERJAKAN';
    return status;
  }

  bool get _hasBeenKlaim {
    final current = widget.transaksi.statusTerkini ?? '';
    if (current.startsWith('KLAIM')) return true;
    for (final log in widget.auditLogs) {
      final ket = (log.keterangan ?? '').trim();
      if (ket.contains('KLAIM')) return true;
    }
    return false;
  }

  void _onStatusTap(String status) {
    final rawStatus = widget.transaksi.statusTerkini ?? '';
    final isKlaimStatus = rawStatus.startsWith('KLAIM');
    if (isKlaimStatus && status == 'SEDANG_DIKERJAKAN') return;
    final currentIndex = _masterOrder.indexOf(_mapToDisplay(rawStatus));
    final targetIndex = _masterOrder.indexOf(status);
    if (targetIndex < currentIndex) return;
    if (status == _mapToDisplay(rawStatus)) return;
    widget.onStatusTap?.call(status);
  }

  String _formatStatusLabel(String status) {
    return status.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawStatus = widget.transaksi.statusTerkini ?? 'MENUNGGU';
    final displayCurrent = _mapToDisplay(rawStatus);
    final currentIndex = _masterOrder.indexOf(displayCurrent);
    final isKlaimNow = rawStatus.startsWith('KLAIM');

    return Card(
      elevation: 0,
      color: _statusColor(displayCurrent).withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: _statusColor(displayCurrent).withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(displayCurrent),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _statusColor(displayCurrent)
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          displayCurrent.replaceAll('_', ' '),
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
            const SizedBox(height: 8),

            // ═══ Combined: Proses Utama label + dots per grup ═══════════
            Container(
              height: 110,
              width: double.infinity,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: _groups.asMap().entries.map((entry) {
                    final groupIdx = entry.key;
                    final group = entry.value;
                    final isLastGroup = groupIdx == _groups.length - 1;
                    final isGroupCurrent =
                        group.statuses.contains(displayCurrent);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ── Proses Utama Label ──
                          Container(
                            height: 20,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              group.name,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isGroupCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isGroupCurrent
                                    ? _statusColor(displayCurrent)
                                    : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // ── Dots row (BIG + SMALL) ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // BIG DOT (first sub-status)
                              _buildTimelineDot(
                                status: group.statuses.first,
                                isBig: true,
                                isCurrent:
                                    group.statuses.contains(displayCurrent),
                                currentIndex: currentIndex,
                                theme: theme,
                              ),
                              // Remaining sub-statuses (small dots)
                              ...group.statuses.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final subStatus = entry.value;
                                if (idx == 0) return const SizedBox.shrink();

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Connector line
                                    SizedBox(
                                      width: 48,
                                      height: 42,
                                      child: Center(
                                        child: Container(
                                          height: 2.5,
                                          decoration: BoxDecoration(
                                            color: _statusColor(subStatus)
                                                .withValues(alpha: 0.35),
                                            borderRadius:
                                                BorderRadius.circular(1.25),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Small dot with label
                                    _buildTimelineDot(
                                      status: subStatus,
                                      isBig: false,
                                      isCurrent: subStatus == displayCurrent,
                                      currentIndex: currentIndex,
                                      theme: theme,
                                    ),
                                  ],
                                );
                              }),
                              // Connector line to next group
                              if (!isLastGroup)
                                SizedBox(
                                  width: 56,
                                  height: 42,
                                  child: Center(
                                    child: Container(
                                      height: 2.5,
                                      decoration: const BoxDecoration(
                                        color: Color(0x55AAAAAA),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(1.25)),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ═══ Klaim indicator ═════════════════════════════════════
            if (isKlaimNow) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepOrange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_rounded,
                        size: 16, color: Colors.deepOrange.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Sedang dalam proses Klaim Distributor',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build a single timeline dot (BIG or SMALL) with its status label below.
  Widget _buildTimelineDot({
    required String status,
    required bool isBig,
    required bool isCurrent,
    required int currentIndex,
    required ThemeData theme,
  }) {
    final subIndex = _masterOrder.indexOf(status);
    final isPast = subIndex >= 0 && subIndex < currentIndex;
    final color = _statusColor(status);
    final isClickable = !isPast && !isCurrent && widget.onStatusTap != null;
    final dotSize =
        isBig ? (isCurrent ? 42.0 : 34.0) : (isCurrent ? 24.0 : 18.0);
    final borderWidth = isCurrent ? 3.0 : (isBig ? 2.5 : 2.0);

    return GestureDetector(
      onTap: isClickable ? () => _onStatusTap(status) : null,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) {
          return SizedBox(
            width: isBig ? 95 : 75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Center the dot in a 42px height area
                SizedBox(
                  height: 42,
                  child: Center(
                    child: Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? color
                            : isPast
                                ? color.withValues(alpha: 0.6)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent
                              ? color
                              : isPast
                                  ? color.withValues(alpha: 0.6)
                                  : isClickable
                                      ? color.withValues(alpha: 0.5)
                                      : theme.colorScheme.outlineVariant,
                          width: borderWidth,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color:
                                      color.withValues(alpha: _glowAnim.value),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: isCurrent
                          ? Icon(_statusIcons(status),
                              size: isBig ? 20 : 14, color: Colors.white)
                          : isPast
                              ? Icon(Icons.check_circle_rounded,
                                  size: isBig ? 18 : 12, color: Colors.white)
                              : null,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Status label below dot
                Text(
                  _formatStatusLabel(status),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isCurrent ? 10 : 9,
                    height: 1.1,
                    fontWeight: isCurrent
                        ? FontWeight.bold
                        : isPast
                            ? FontWeight.w500
                            : FontWeight.normal,
                    color: isCurrent
                        ? color
                        : isPast
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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

class _GroupDef {
  final String name;
  final List<String> statuses;
  const _GroupDef(this.name, this.statuses);
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

// ═══════════════════════════════════════════════════════════════════════════════
//  KLAIM TIMELINE CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _KlaimTimelineCard extends StatelessWidget {
  final TransaksiServis transaksi;
  final void Function(String status)? onStatusTap;

  const _KlaimTimelineCard({
    required this.transaksi,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = transaksi.statusTerkini ?? '';

    const klaimStatuses = [
      'KLAIM_MENUNGGU_PENGIRIMAN',
      'KLAIM_DIKIRIM',
      'KLAIM_SUDAH_DIKIRIM',
      'KLAIM_SUDAH_DIAMBIL',
    ];

    final currentKlaimIndex = klaimStatuses.indexOf(status);

    IconData klaimIcon(String s) {
      switch (s) {
        case 'KLAIM_MENUNGGU_PENGIRIMAN':
          return Icons.hourglass_bottom_rounded;
        case 'KLAIM_DIKIRIM':
          return Icons.local_shipping_rounded;
        case 'KLAIM_SUDAH_DIKIRIM':
          return Icons.check_rounded;
        case 'KLAIM_SUDAH_DIAMBIL':
          return Icons.done_all_rounded;
        default:
          return Icons.help_outline_rounded;
      }
    }

    String klaimLabel(String s) {
      switch (s) {
        case 'KLAIM_MENUNGGU_PENGIRIMAN':
          return 'MENUNGGU PENGIRIMAN';
        case 'KLAIM_DIKIRIM':
          return 'DIKIRIM';
        case 'KLAIM_SUDAH_DIKIRIM':
          return 'SUDAH DIKIRIM';
        case 'KLAIM_SUDAH_DIAMBIL':
          return 'SUDAH DIAMBIL';
        default:
          return s.replaceAll('KLAIM_', '').replaceAll('_', ' ');
      }
    }

    return Card(
      elevation: 0,
      color: Colors.deepOrange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepOrange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_rounded,
                    size: 16, color: Colors.deepOrange.shade700),
                const SizedBox(width: 6),
                Text('Riwayat Status Klaim',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange.shade700)),
                const Spacer(),
                if (currentKlaimIndex >= 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      klaimLabel(status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 80,
              child: Row(
                children: klaimStatuses.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final isLast = idx == klaimStatuses.length - 1;
                  final isPast =
                      currentKlaimIndex >= 0 && idx < currentKlaimIndex;
                  final isCurrent = s == status;

                  // Tap only allowed for subsequent states in order
                  final isTapable = onStatusTap != null &&
                      currentKlaimIndex >= 0 &&
                      idx > currentKlaimIndex;

                  return Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: isTapable ? () => onStatusTap!(s) : null,
                          child: Row(
                            children: [
                              Expanded(
                                child: idx == 0
                                    ? const SizedBox()
                                    : Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: (currentKlaimIndex >= idx)
                                              ? Colors.deepOrange
                                              : Colors.deepOrange
                                                  .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(1.5),
                                        ),
                                      ),
                              ),
                              Container(
                                width: isCurrent ? 32 : 26,
                                height: isCurrent ? 32 : 26,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.deepOrange
                                      : isPast
                                          ? Colors.deepOrange
                                              .withValues(alpha: 0.15)
                                          : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCurrent
                                        ? Colors.deepOrange
                                        : isPast
                                            ? Colors.deepOrange
                                            : Colors.deepOrange
                                                .withValues(alpha: 0.35),
                                    width: isCurrent ? 3 : 2,
                                  ),
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: Colors.deepOrange
                                                .withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    klaimIcon(s),
                                    size: isCurrent ? 16 : 13,
                                    color: isCurrent
                                        ? Colors.white
                                        : isPast
                                            ? Colors.deepOrange
                                            : Colors.deepOrange
                                                .withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: isLast
                                    ? const SizedBox()
                                    : Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: (currentKlaimIndex > idx)
                                              ? Colors.deepOrange
                                              : Colors.deepOrange
                                                  .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(1.5),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          klaimLabel(s),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.1,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : isPast
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                            color: isCurrent
                                ? Colors.deepOrange
                                : isPast
                                    ? Colors.deepOrange.shade700
                                    : Colors.deepOrange.shade300,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
