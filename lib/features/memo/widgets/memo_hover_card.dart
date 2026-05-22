import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stok_anandam/data/models/memo.dart';

class MemoHoverCard extends StatefulWidget {
  final MemoDetail memo;
  final Widget child;

  const MemoHoverCard({
    super.key,
    required this.memo,
    required this.child,
  });

  @override
  State<MemoHoverCard> createState() => _MemoHoverCardState();
}

class _MemoHoverCardState extends State<MemoHoverCard> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isHovering = false;
  Timer? _showTimer;

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    final screenHeight = MediaQuery.of(context).size.height;
    final globalOffset = renderBox.localToGlobal(Offset.zero);
    
    // Estimate card height
    // Header: ~60, Divider: 24, Items: max 250, Footer: ~30, Padding: 32
    double estimatedHeight = 60 + 24 + 32;
    if (widget.memo.items.isEmpty) {
      estimatedHeight += 40;
    } else {
      estimatedHeight += (widget.memo.items.length * 34.0).clamp(0.0, 250.0);
    }
    if (widget.memo.items.length > 5) estimatedHeight += 40;

    double verticalOffset = -20;
    // If the card would go off the bottom of the screen
    if (globalOffset.dy + verticalOffset + estimatedHeight > screenHeight - 20) {
      // Shift it up so it stays within screen bounds
      verticalOffset = (screenHeight - 20) - globalOffset.dy - estimatedHeight;
      
      // But don't let it go too high (keep it at least somewhat aligned with the row)
      if (verticalOffset < -estimatedHeight + size.height) {
        verticalOffset = -estimatedHeight + size.height;
      }
    }

    return OverlayEntry(
      builder: (context) => Positioned(
        width: 320,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(size.width + 12, verticalOffset),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) {
              setState(() => _isHovering = false);
              _hideOverlay();
            },
            child: Material(
              elevation: 12,
              shadowColor: Colors.black45,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.inventory_2_outlined, size: 16, color: Colors.blue.shade700),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Detail Barang",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                "${widget.memo.items.length} jenis barang",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: widget.memo.items.isEmpty 
                        ? const Center(child: Text("Tidak ada data barang", style: TextStyle(fontSize: 12, color: Colors.grey)))
                        : SingleChildScrollView(
                            child: Column(
                              children: widget.memo.items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          "${widget.memo.items.indexOf(item) + 1}",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.namaBarang ?? '-',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            if (item.catatanGudang != null && item.catatanGudang!.isNotEmpty)
                                              Text(
                                                "Catatan: ${item.catatanGudang}",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.orange.shade800,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "${item.qty.toString().replaceAll(RegExp(r'\.0$'), '')}",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                    ),
                    if (widget.memo.items.length > 5) ...[
                      const Divider(height: 24),
                      Center(
                        child: Text(
                          "Scroll untuk melihat lebih banyak",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _showTimer?.cancel();
          _isHovering = true;
          _showTimer = Timer(const Duration(milliseconds: 500), () {
            if (mounted && _isHovering) {
              _showOverlay();
            }
          });
        },
        onExit: (_) {
          _showTimer?.cancel();
          _isHovering = false;
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && !_isHovering) {
              _hideOverlay();
            }
          });
        },
        child: widget.child,
      ),
    );
  }
}
