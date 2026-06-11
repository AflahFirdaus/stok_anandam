import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stok_anandam/features/servis/models/laporan_keuangan.dart';
import 'package:stok_anandam/features/servis/repositories/servis_repository.dart';
import 'package:stok_anandam/injection.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  LaporanKeuangan? _dataLaporan;
  bool _isLoading = false;

  final _currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    // Default load bulan ini
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0); // Hari terakhir bulan ini
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = getIt<ServisRepository>();
      final data = await repo.getLaporanKeuangan(_startDate, _endDate);
      setState(() => _dataLaporan = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat laporan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final initialRange = DateTimeRange(
      start: _startDate ?? DateTime.now(),
      end: _endDate ?? DateTime.now(),
    );
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  Future<void> _exportData() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih rentang tanggal terlebih dahulu')));
      return;
    }
    
    // Panggil fungsi export di repository
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mempersiapkan Export...')));
    try {
      final filePath = await getIt<ServisRepository>().exportLaporanKeuangan(_startDate!, _endDate!);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan berhasil diexport ke:\n$filePath'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Export: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = (_startDate != null && _endDate != null)
        ? '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}'
        : 'Pilih Rentang Tanggal';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Laporan Keuangan', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: Filter & Actions ---
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(dateStr),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export Laporan'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- CONTENT: Dashboard Cards ---
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_dataLaporan == null)
              const Expanded(child: Center(child: Text('Tidak ada data.')))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Grid responsif: 1 kolom di mobile, 2/4 kolom di layar lebar
                      final crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
                      
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.8, // Mengatur rasio lebar:tinggi card
                        children: [
                          _buildStatCard(
                            theme,
                            title: 'Total Transaksi',
                            value: _dataLaporan!.totalTransaksiServis.toString(),
                            icon: Icons.receipt_long_rounded,
                            color: Colors.blue,
                          ),
                          _buildStatCard(
                            theme,
                            title: 'Total Omzet Servis',
                            value: _currencyFormat.format(_dataLaporan!.totalOmzetServis),
                            icon: Icons.account_balance_wallet_rounded,
                            color: Colors.indigo,
                          ),
                          _buildStatCard(
                            theme,
                            title: 'Modal Sparepart',
                            value: _currencyFormat.format(_dataLaporan!.totalModalSparepart),
                            icon: Icons.inventory_2_rounded,
                            color: Colors.orange,
                          ),
                          _buildStatCard(
                            theme,
                            title: 'Laba Bersih',
                            value: _currencyFormat.format(_dataLaporan!.labaBersihServis),
                            icon: Icons.trending_up_rounded,
                            color: Colors.green,
                            isHighlight: true,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, {required String title, required String value, required IconData icon, required MaterialColor color, bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighlight ? color.shade50 : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? color.shade200 : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isHighlight ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlight ? color.shade800 : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}