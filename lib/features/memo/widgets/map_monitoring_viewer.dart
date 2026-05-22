import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';
import '../../../injection.dart';
import '../../../data/repositories/map_repository.dart';
import '../../../data/models/map_delivery.dart';

class MapMonitoringViewer extends StatefulWidget {
  final bool isMini;
  final VoidCallback? onExpand;

  const MapMonitoringViewer({
    super.key,
    this.isMini = false,
    this.onExpand,
  });

  @override
  State<MapMonitoringViewer> createState() => _MapMonitoringViewerState();
}

class _MapMonitoringViewerState extends State<MapMonitoringViewer> {
  final MapRepository _repository = getIt<MapRepository>();
  final MapController _mapController = MapController();
  bool _hasCenteredInitially = false;
  List<MapDelivery> _deliveries = [];
  bool _isLoading = true;
  String? _error;
  int _totalData = 0;

  static const LatLng diyCenter = LatLng(-7.7956, 110.3695);
  static const String mapUrlTemplate =
      "https://peta.anandamcomputer.com/styles/basic-preview/{z}/{x}/{y}.png";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await _repository.getTodaysDeliveries();
      if (!mounted) return;

      final activeData = data.where((d) {
        final mStatus = d.memoStatus.toUpperCase();
        final tStatus = d.status.toUpperCase();

        return tStatus != 'SELESAI' &&
            mStatus != 'DITERIMA_USER' &&
            mStatus != 'SELESAI' &&
            mStatus != 'DIBATALKAN';
      }).toList();

      setState(() {
        _totalData = activeData.length;
        _deliveries =
            activeData.where((d) => d.lat != null && d.lng != null).toList();
        _isLoading = false;
      });

      // Auto-center jika baru pertama kali load data dan bukan mode mini
      if (!_hasCenteredInitially && _deliveries.isNotEmpty && !widget.isMini) {
        _hasCenteredInitially = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitAllMarkers();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _centerToDiy() {
    _mapController.move(diyCenter, 11.0);
  }

  void _fitAllMarkers() {
    if (_deliveries.isEmpty) return;

    double minLat = _deliveries.first.lat!;
    double maxLat = _deliveries.first.lat!;
    double minLng = _deliveries.first.lng!;
    double maxLng = _deliveries.first.lng!;

    for (var d in _deliveries) {
      if (d.lat! < minLat) minLat = d.lat!;
      if (d.lat! > maxLat) maxLat = d.lat!;
      if (d.lng! < minLng) minLng = d.lng!;
      if (d.lng! > maxLng) maxLng = d.lng!;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    _mapController.move(center, 12.0);
  }

  void _zoomIn() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom - 1);
  }

  Future<void> _openInMaps(double lat, double lng, {String? mapUrl}) async {
    final Uri uri;
    if (mapUrl != null && mapUrl.isNotEmpty && mapUrl.startsWith('http')) {
      uri = Uri.parse(mapUrl);
    } else {
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getMarkerColor(MapDelivery d) {
    // 1. Prioritas Utama: Drop-off Ekspedisi (Ungu / Purple)
    if (d.isExpedition) return const Color(0xFF800080);

    // 2. Urgen (Merah Terang)
    if (d.isUrgen) return const Color(0xFFFF0000);

    // 3. Request Delivery / Manual (Kuning Emas)
    if (d.isManual) return const Color(0xFFFFD700);

    // 4. Pengiriman Memo Standar (Orange Vivid)
    return const Color(0xFFFF8C00);
  }

  List<Marker> _buildMarkers() {
    final List<Marker> individualMarkers = [];
    final Map<String, int> counts = {};

    for (var d in _deliveries) {
      if (d.lat == null || d.lng == null) continue;

      final key = '${d.lat?.toStringAsFixed(6)},${d.lng?.toStringAsFixed(6)}';
      int index = counts[key] ?? 0;
      counts[key] = index + 1;

      // Geser sedikit (jitter) jika ada lebih dari satu di lokasi yang sama
      double jitterLat = d.lat! + (index * 0.000012);
      double jitterLng = d.lng! + (index * 0.000012);

      individualMarkers.add(
        Marker(
          point: LatLng(jitterLat, jitterLng),
          width: 140,
          height: 100,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {
              final sameLocation = _deliveries.where((item) {
                if (item.lat == null || item.lng == null) return false;
                final itemKey =
                    '${item.lat?.toStringAsFixed(6)},${item.lng?.toStringAsFixed(6)}';
                return itemKey == key;
              }).toList();
              _showDetail(sameLocation);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                        color: _getMarkerColor(d).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    d.customerName.length > 15
                        ? '${d.customerName.substring(0, 12)}...'
                        : d.customerName,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Icon(
                  Icons.location_on_rounded,
                  color: _getMarkerColor(d),
                  size: widget.isMini ? 26 : 38,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return individualMarkers;
  }

  void _showDetail(List<MapDelivery> group) {
    if (widget.isMini) {
      widget.onExpand?.call();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: group.length > 2 ? 0.6 : 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  Text(
                    group.length > 1
                        ? '${group.length} Pengiriman di Lokasi Ini'
                        : 'Detail Pengiriman',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                itemCount: group.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final delivery = group[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getMarkerColor(delivery)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.local_shipping_rounded,
                                color: _getMarkerColor(delivery), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  delivery.customerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: _getMarkerColor(delivery)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        delivery.status.replaceAll('_', ' '),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: _getMarkerColor(delivery),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(delivery.nomorMemo,
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _openInMaps(
                                delivery.lat!, delivery.lng!,
                                mapUrl: delivery.mapUrl),
                            icon: Icon(Icons.navigation_rounded,
                                color: Colors.blue.shade700),
                            tooltip: 'Navigasi',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRowSmall(Icons.location_on_rounded,
                                'Alamat', _buildAlamatText(delivery)),
                            const SizedBox(height: 8),
                            _buildDetailRowSmall(Icons.map_rounded, 'Kabupaten',
                                _cleanValue(delivery.kabupaten)),
                            const SizedBox(height: 8),
                            _buildDetailRowSmall(
                                Icons.person_pin_rounded,
                                'Request',
                                delivery.senderName.isNotEmpty
                                    ? delivery.senderName
                                    : 'Admin'),
                            const SizedBox(height: 8),
                            _buildDetailRowSmall(
                                Icons.gps_fixed_rounded,
                                'Koordinat',
                                '${delivery.lat?.toStringAsFixed(6)}, ${delivery.lng?.toStringAsFixed(6)}'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanValue(String? val) {
    if (val == null || val.isEmpty || val.toUpperCase() == 'N/A') return '-';
    return val;
  }

  String _buildAlamatText(MapDelivery d) {
    final parts = [
      d.desa,
      d.kecamatan,
    ]
        .where((s) =>
            s.isNotEmpty &&
            s.toUpperCase() != 'N/A' &&
            s.toUpperCase() != 'WILAYAH')
        .toList();

    if (parts.isEmpty) {
      return d.alamatLengkap.isNotEmpty
          ? d.alamatLengkap
          : 'Alamat tidak tersedia';
    }
    return parts.join(', ');
  }

  Widget _buildDetailRowSmall(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: widget.isMini ? 32 : 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Error: $_error',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: widget.isMini ? 12 : 14)),
            TextButton(onPressed: _loadData, child: const Text('Coba Lagi'))
          ],
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          key: const ValueKey('monitoring_map'),
          mapController: _mapController,
          options: MapOptions(
            initialCenter: diyCenter,
            initialZoom: widget.isMini ? 9.5 : 11.0,
            onMapReady: () {
              // Jika sudah ada data saat map siap, pusatkan ke sebaran marker
              if (_deliveries.isNotEmpty && !widget.isMini) {
                _fitAllMarkers();
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: mapUrlTemplate,
              userAgentPackageName: 'com.example.stok_anandam',
              tileProvider: NetworkTileProvider(),
            ),
            MarkerLayer(
              markers: _buildMarkers(),
            ),
          ],
        ),

        // INFO PANEL (Markers Count)
        if (!widget.isMini)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_deliveries.length} / $_totalData Lokasi',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  if (_deliveries.length < _totalData)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${_totalData - _deliveries.length} data belum ada koordinat',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
          ),

        // MAP CONTROLS
        if (!widget.isMini)
          Positioned(
            bottom: 32,
            right: 16,
            child: Column(
              children: [
                _buildMapControl(Icons.add_rounded, _zoomIn, 'Zoom In'),
                const SizedBox(height: 8),
                _buildMapControl(Icons.remove_rounded, _zoomOut, 'Zoom Out'),
                const SizedBox(height: 16),
                _buildMapControl(
                    Icons.my_location_rounded, _centerToDiy, 'Pusatkan ke DIY',
                    color: Colors.blue.shade700),
              ],
            ),
          ),

        // MINI OVERLAY
        if (widget.isMini)
          Positioned(
            right: 8,
            bottom: 8,
            child: FloatingActionButton.small(
              heroTag: 'expandMap',
              backgroundColor: Colors.white,
              onPressed: widget.onExpand,
              child:
                  Icon(Icons.fullscreen_rounded, color: Colors.blue.shade800),
            ),
          ),
      ],
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onTap, String tooltip,
      {Color? color}) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: color ?? Colors.grey.shade800),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
