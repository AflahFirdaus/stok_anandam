import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stok_anandam/features/shared/widgets/camera_screen.dart';
import 'package:stok_anandam/core/widgets/action_slider.dart';
import 'package:stok_anandam/data/models/memo.dart';
import 'package:stok_anandam/data/models/penjadwalan.dart';
import 'package:stok_anandam/features/memo/bloc/memo_bloc.dart';
import 'package:stok_anandam/injection.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryDetailPage extends StatefulWidget {
  final String id;
  const DeliveryDetailPage({super.key, required this.id});

  @override
  State<DeliveryDetailPage> createState() => _DeliveryDetailPageState();
}

class _DeliveryDetailPageState extends State<DeliveryDetailPage> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MemoBloc(getIt())..add(LoadMemoDetail(widget.id)),
      child: BlocConsumer<MemoBloc, MemoState>(
        listener: (context, state) {
          if (state is MemoOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.green),
            );
          } else if (state is MemoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is MemoLoading || state is MemoInitial) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          if (state is MemoDetailLoaded) {
            final memo = state.detail;
            return Scaffold(
              backgroundColor: const Color(
                  0xFFF8FAFC), // Slight bluish gray for enterprise feel
              appBar: AppBar(
                title: const Text('Detail Pengantaran',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.only(
                    bottom: 100), // Space for sticky footer
                child: Builder(builder: (context) {
                  final jadwal = memo.penjadwalanHistory.isNotEmpty
                      ? memo.penjadwalanHistory.last
                      : null;
                  return Column(
                    children: [
                      _buildStatusHeader(memo),
                      _buildCustomerCard(memo),
                      if (jadwal?.tipeTugas == 'DROP_OFF_EKSPEDISI')
                        _buildManifestCard(jadwal!),
                      _buildLogisticsCard(memo),
                      _buildLocationCard(memo),
                      _buildItemsCard(memo),
                    ],
                  );
                }),
              ),
              bottomSheet: _buildStickyFooter(context, memo),
            );
          }

          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: TextButton(
                onPressed: () =>
                    context.read<MemoBloc>().add(LoadMemoDetail(widget.id)),
                child: const Text('Gagal memuat. Ketuk untuk coba lagi.'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(MemoDetail memo) {
    final status = memo.statusAkhir;
    int currentStep = 0;
    if (status == MemoStatus.MENUNGGU_PENGIRIMAN) currentStep = 1;
    if (status == MemoStatus.DALAM_PENGIRIMAN) currentStep = 2;
    if (status == MemoStatus.DITERIMA_USER) currentStep = 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIcon(
                  1, Icons.inventory_2_rounded, currentStep >= 1, 'Siap'),
              _buildStepDivider(currentStep >= 2),
              _buildStepIcon(
                  2, Icons.local_shipping_rounded, currentStep >= 2, 'Jalan'),
              _buildStepDivider(currentStep >= 3),
              _buildStepIcon(
                  3, Icons.check_circle_rounded, currentStep >= 3, 'Sampai'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIcon(int step, IconData icon, bool isActive, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? Colors.indigo : Colors.grey.shade100,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ]
                : [],
          ),
          child: Icon(icon,
              color: isActive ? Colors.white : Colors.grey.shade400, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
            color: isActive ? Colors.indigo : Colors.grey.shade400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(left: 8, right: 8, bottom: 20),
        decoration: BoxDecoration(
          color: isActive ? Colors.indigo : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(MemoDetail memo) {
    return _buildCard(
      icon: Icons.person_rounded,
      title: 'Informasi Pelanggan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memo.customerName ?? 'Tanpa Nama',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  memo.customerPhone ?? '-',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () {
                  if (memo.customerPhone != null) {
                    Clipboard.setData(ClipboardData(text: memo.customerPhone!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nomor HP disalin')),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildCommunicationTools(memo.customerPhone),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationTools(String? phone) {
    if (phone == null || phone.isEmpty) return const SizedBox();

    // Cleanup phone number format
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    return Row(
      children: [
        GestureDetector(
          onTap: () => launchUrl(Uri.parse('https://wa.me/$cleanPhone')),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF25D366), Color(0xFF128C7E)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF25D366).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.message_rounded, color: Colors.white, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManifestCard(PenjadwalanResponse jadwal) {
    return _buildCard(
      icon: Icons.assignment_turned_in_rounded,
      title: 'Informasi Manifest Ekspedisi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ID Manifest:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(jadwal.manifestId ?? '-',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.purple,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Daftar Memo/Resi dalam Manifest:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: (jadwal.manifestResiList ?? [])
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 14, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(e,
                                style: const TextStyle(
                                    fontFamily: 'monospace', fontSize: 13)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsCard(MemoDetail memo) {
    final jadwal = memo.penjadwalanHistory.isNotEmpty
        ? memo.penjadwalanHistory.last
        : null;

    return _buildCard(
      icon: Icons.local_shipping_rounded,
      title: 'Logistik & Penjadwalan',
      child: Column(
        children: [
          _buildInfoRow('Marketing', memo.marketingName ?? '-'),
          const Divider(height: 24),
          _buildInfoRow('Tanggal', jadwal?.tanggalJadwal ?? '-'),
          const Divider(height: 24),
          _buildInfoRow('Estimasi (ETA)', jadwal?.estimasiWaktu ?? '-'),
          if (jadwal?.catatan != null && jadwal!.catatan!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Catatan Penjadwalan:',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey)),
                  const SizedBox(height: 4),
                  Text(jadwal.catatan!,
                      style: const TextStyle(fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard(MemoDetail memo) {
    final jadwal = memo.penjadwalanHistory.isNotEmpty
        ? memo.penjadwalanHistory.last
        : null;
    final address =
        jadwal?.alamatLengkap ?? memo.deskripsi ?? 'Alamat tidak tersedia';
    final mapsUrl = jadwal?.alamatMaps;

    return _buildCard(
      icon: Icons.location_on_rounded,
      title: 'Alamat Pengiriman',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Kode Pos', jadwal?.kodePos ?? memo.kodePos ?? '-'),
          const SizedBox(height: 12),
          Text(address,
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: Colors.black87)),
          if (mapsUrl != null && mapsUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(mapsUrl),
                    mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Buka Google Maps'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard(MemoDetail memo) {
    return _buildCard(
      icon: Icons.inventory_2_rounded,
      title: 'Daftar Barang & Harga',
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: memo.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = memo.items[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(item.namaBarang ?? 'Item Tidak Dikenal',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3)),
                      ),
                      const SizedBox(width: 8),
                      Text('x${item.qty}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatCurrency(item.hargaSatuan)} / unit',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        _formatCurrency(item.subtotal),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const Divider(thickness: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL PESANAN',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey)),
              Text(
                _formatCurrency(memo.totalHarga),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.indigo),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(num amount) {
    final hexant = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < hexant.length; i++) {
      if (i > 0 && (hexant.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(hexant[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  Widget _buildStickyFooter(BuildContext context, MemoDetail memo) {
    if (memo.statusAkhir == MemoStatus.DITERIMA_USER) return const SizedBox();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -5)),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (memo.statusAkhir == MemoStatus.MENUNGGU_PENGIRIMAN)
              ActionSlider(
                label: 'GESER UNTUK MULAI JALAN',
                icon: Icons.local_shipping_rounded,
                baseColor: Colors.indigo,
                onComplete: () {
                  HapticFeedback.mediumImpact();
                  _handleAction(context, memo);
                },
              )
            else if (memo.statusAkhir == MemoStatus.DALAM_PENGIRIMAN)
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Colors.teal, Color(0xFF10B981)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _handleAction(context, memo),
                  icon:
                      const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: const Text('SELESAIKAN PENGIRIMAN',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, MemoDetail memo) async {
    final bloc = context.read<MemoBloc>();

    if (memo.statusAkhir == MemoStatus.MENUNGGU_PENGIRIMAN) {
      bloc.add(UpdateMemoStatusEvent(memo.id!, MemoStatus.DALAM_PENGIRIMAN,
          "Mulai Pengiriman oleh Kurir"));
    } else if (memo.statusAkhir == MemoStatus.DALAM_PENGIRIMAN) {
      _showFinishDeliveryModal(context, memo, bloc);
    }
  }

  void _showFinishDeliveryModal(
      BuildContext outerContext, MemoDetail memo, MemoBloc bloc) {
    XFile? localPhoto;

    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text('Konfirmasi Selesai',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Builder(builder: (context) {
                      final isExpedition = memo.penjadwalanHistory.isNotEmpty &&
                          memo.penjadwalanHistory.last.tipeTugas ==
                              'DROP_OFF_EKSPEDISI';
                      return Text(
                          isExpedition
                              ? 'WAJIB: Ambil foto bukti Drop-off Ekspedisi untuk laporan manifest.'
                              : 'Mohon ambil foto bukti sebagai syarat penyelesaian.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              color: isExpedition ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.w600));
                    }),
                    const SizedBox(height: 32),
                    if (localPhoto == null)
                      GestureDetector(
                        onTap: () async {
                          XFile? photo;
                          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                            final ImagePicker picker = ImagePicker();
                            photo = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 70,
                            );
                          } else {
                            photo = await Navigator.push<XFile>(
                              context,
                              MaterialPageRoute(builder: (_) => const CameraScreen()),
                            );
                          }
                          if (photo != null) {
                            setModalState(() => localPhoto = photo);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.indigo.withOpacity(0.1),
                                width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.indigo, size: 32),
                              ),
                              const SizedBox(height: 16),
                              const Text('Ketuk untuk Ambil Foto',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo)),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  image: DecorationImage(
                                    image: FileImage(File(localPhoto!.path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () =>
                                      setModalState(() => localPhoto = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.refresh_rounded,
                                        color: Colors.indigo, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          ActionSlider(
                            label: 'GESER UNTUK SELESAIKAN',
                            icon: Icons.check_rounded,
                            baseColor: Colors.teal,
                            onComplete: () {
                              HapticFeedback.heavyImpact();
                              bloc.add(FinishDeliveryProcessEvent(
                                id: memo.id!,
                                photo: localPhoto!,
                                catatan: "Pengiriman diselesaikan oleh Kurir",
                              ));
                              Navigator.pop(context); // Close modal
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCard(
      {required IconData icon, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: Colors.indigo),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey))),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
