import 'package:flutter/material.dart';
import '../routing/app_router.dart';

/// Feedback ke user: Toast melayang (Overlay) yang selalu tampil di paling depan
/// dan diposisikan dengan rapi di bagian atas/bawah layar agar tidak terhalang dialog.
class AppFeedback {
  AppFeedback._();

  /// Tampilkan notifikasi error di bagian atas layar.
  static void showError(BuildContext context, String message, {bool isTop = true}) {
    _showToast(context, message, isError: true, isTop: isTop);
  }

  /// Tampilkan notifikasi sukses di bagian atas layar.
  static void showSuccess(BuildContext context, String message, {bool isTop = true}) {
    _showToast(context, message, isError: false, isTop: isTop);
  }

  /// Fallback global menggunakan ScaffoldMessenger
  static void showErrorGlobal(String message) {
    messengerKey.currentState?.clearSnackBars();
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Fallback global menggunakan ScaffoldMessenger
  static void showSuccessGlobal(String message) {
    messengerKey.currentState?.clearSnackBars();
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.teal.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showToast(
    BuildContext context,
    String message, {
    required bool isError,
    required bool isTop,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        isError: isError,
        isTop: isTop,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isTop;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.isError,
    required this.isTop,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _offsetAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _offsetAnimation = Tween<Offset>(
      begin: widget.isTop ? const Offset(0, -0.8) : const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Otomatis tutup setelah 3 detik
    Future.delayed(const Duration(milliseconds: 3000), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (!mounted || _isDismissed) return;
    setState(() {
      _isDismissed = true;
    });
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeArea = MediaQuery.of(context).padding;

    return Positioned(
      top: widget.isTop ? safeArea.top + 16 : null,
      bottom: widget.isTop ? null : safeArea.bottom + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Material(
            color: Colors.transparent,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: widget.isError
                      ? const Color(0xFFDC2626) // Merah premium
                      : const Color(0xFF0F766E), // Teal premium
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      widget.isError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _dismiss,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
