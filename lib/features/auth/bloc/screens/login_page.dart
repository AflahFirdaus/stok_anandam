import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/widgets/app_feedback.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/injection.dart';
import 'package:local_auth/local_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:stok_anandam/token_storage.dart';
import '../../../Biometric/api/biometric_api.dart';
import '../../../Biometric/repositories/biometric_repository.dart';
import '../../../Biometric/services/biometric_crypto_service.dart';
import '../../../../core/network/websocket_service.dart';
import '../auth_bloc.dart';
import '../auth_event.dart';
import '../auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscurePassword = true;
  /// Pesan server busy yang akan ditampilkan di banner (dari state sebelumnya,
  /// agar banner tidak menghilang saat widget rebuild).
  String? _serverBusyMessage;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  static const double _breakpoint = 700;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _breakpoint;
    final padding = MediaQuery.paddingOf(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          // Hanya rebuild saat tipe state berubah (Initial→Loading→Success/Failure)
          // agar TextField tidak kehilangan focus saat Bloc emit state baru yang sama.
          buildWhen: (previous, current) =>
              previous.runtimeType != current.runtimeType,
          listener: (context, state) {
            if (state is AuthSuccess) {
              // Connect WebSocket presence
              final userId = getIt<CurrentUserStore>().userId?.toString();
              final name = getIt<CurrentUserStore>().displayName;
              if (userId != null && userId.isNotEmpty) {
                getIt<WebSocketService>().connectPresence(
                  userId: userId,
                  name: name,
                );
              }

              // Navigate to the role-appropriate home page.
              // User data is already loaded by AuthBloc before AuthSuccess is emitted.
              final userRole =
                  getIt<CurrentUserStore>().userRole?.toUpperCase();
              if (userRole == null) {
                // If role not yet loaded, wait for CurrentUserStore to notify and trigger a rebuild
                // or the app_router redirect will eventually take over.
                // For now, we can show a message or just wait.
                return;
              }

              if (userRole == 'TEKNISI' || userRole == 'DELIVERY') {
                context.go(AppRoutes.pengiriman);
              } else if (userRole.contains('NOTA')) {
                context.go(AppRoutes.memo);
              } else if (userRole == 'GUDANG' ||
                  userRole.startsWith('MARKETING')) {
                context.go(AppRoutes.stok);
              } else {
                context.go(AppRoutes.stok);
              }
            } else if (state is AuthFailure) {
              if (state.isDeactivated) {
                context.go(AppRoutes.accessDenied);
              } else {
                AppFeedback.showError(context, state.error);
              }
            } else if (state is AuthInitial) {
              // Reset banner saat kembali ke initial state
              setState(() => _serverBusyMessage = null);
            }
          },
          builder: (context, state) {
            // Simpan pesan server busy dari state terakhir
            if (state is AuthServerBusy) {
              _serverBusyMessage = state.message;
            } else if (state is AuthInitial || state is AuthLoading) {
              // Jangan hapus banner saat loading — biarkan tetap terlihat
            } else {
              // AuthSuccess/AuthFailure — banner tidak relevan lagi
              _serverBusyMessage = null;
            }

            // Widget banner server busy (dipasang di atas form)
            Widget? serverBanner;
            if (state is AuthServerBusy || (_serverBusyMessage != null && state is! AuthSuccess && state is! AuthFailure)) {
              serverBanner = _ServerBusyBanner(
                message: _serverBusyMessage ?? 'Server sedang sibuk...',
                isRetrying: state is AuthServerBusy && state.isRetrying,
              );
            }

            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        if (serverBanner != null) serverBanner,
                        Expanded(
                          child: _FormPanel(
                            userController: _userController,
                            passController: _passController,
                            obscurePassword: _obscurePassword,
                            onTogglePassword: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                            isLoading: state is AuthLoading,
                            onSubmit: () {
                              debugPrint(
                                  '[LoginPage] Submitting login with username: ${_userController.text}');
                              context.read<AuthBloc>().add(
                                    LoginSubmitted(
                                        _userController.text, _passController.text),
                                  );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _IllustrationPanel()),
                ],
              );
            }
            final w = MediaQuery.sizeOf(context).width;
            final hPad = w < 400 ? 16.0 : 24.0;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height -
                      padding.top -
                      padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MobileHeader(),
                    if (serverBanner != null) serverBanner,
                    Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 32),
                      child: _FormPanel(
                        userController: _userController,
                        passController: _passController,
                        obscurePassword: _obscurePassword,
                        onTogglePassword: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        isLoading: state is AuthLoading,
                        onSubmit: () {
                          debugPrint(
                              '[LoginPage] Submitting login with username: ${_userController.text}');
                          context.read<AuthBloc>().add(
                                LoginSubmitted(
                                    _userController.text, _passController.text),
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Banner informasi ketika server sedang sibuk / gangguan.
/// Tidak auto-dismiss — tetap terlihat sampai user mencoba lagi dan berhasil.
class _ServerBusyBanner extends StatelessWidget {
  final String message;
  final bool isRetrying;

  const _ServerBusyBanner({
    required this.message,
    this.isRetrying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.sync_problem_rounded,
            color: Colors.orange.shade700,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Server Tidak Tersedia',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (isRetrying)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.orange.shade700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FormPanel extends StatefulWidget {
  const _FormPanel({
    required this.userController,
    required this.passController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController userController;
  final TextEditingController passController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  State<_FormPanel> createState() => _FormPanelState();
}

class _FormPanelState extends State<_FormPanel> {
  // FocusNodes yang dikelola di sini agar stabil dan tidak terpengaruh rebuild parent
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  final _localAuth = LocalAuthentication();
  late final BiometricRepository _biometricRepository;
  String? _deviceId;
  bool _hasBiometricKeys = false;
  bool _canCheckBiometrics = false;
  bool _isLoadingBiometric = false;

  @override
  void initState() {
    super.initState();
    final dio = getIt<Dio>();
    const storage = FlutterSecureStorage();
    _biometricRepository = BiometricRepository(
      BiometricApi(dio),
      BiometricCryptoService(storage),
    );
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      String deviceId;
      try {
        final deviceInfo = DeviceInfoPlugin();
        try {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } catch (_) {
          try {
            final iosInfo = await deviceInfo.iosInfo;
            deviceId = iosInfo.identifierForVendor ?? 'ios-fallback';
          } catch (_) {
            deviceId = 'device-fallback';
          }
        }
      } catch (_) {
        deviceId = 'device-fallback';
      }

      final hasKeys = await _biometricRepository.isBiometricAvailable(deviceId);

      if (mounted) {
        setState(() {
          _deviceId = deviceId;
          _canCheckBiometrics = canCheckBiometrics || isDeviceSupported;
          _hasBiometricKeys = hasKeys;
        });
      }
    } catch (e) {
      debugPrint('[LoginPage] Biometric init error: $e');
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (!_canCheckBiometrics) {
      AppFeedback.showError(
          context, 'Perangkat Anda tidak mendukung autentikasi biometrik.');
      return;
    }

    if (!_hasBiometricKeys || _deviceId == null) {
      if (mounted) {
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Biometrik Belum Aktif'),
            content: const Text(
              'Untuk menggunakan login biometrik, silakan:\n\n'
              '1. Login menggunakan username & password\n'
              '2. Masuk ke menu Profile\n'
              '3. Aktifkan Biometric di pengaturan profil\n\n'
              'Setelah itu, login biometrik sudah bisa digunakan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoadingBiometric = true;
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint untuk login',
      );

      if (!authenticated) {
        if (mounted) {
          AppFeedback.showError(
              context, 'Autentikasi biometrik dibatalkan atau gagal.');
        }
        setState(() {
          _isLoadingBiometric = false;
        });
        return;
      }

      final token = await _biometricRepository.loginWithBiometric(_deviceId!);
      await getIt<TokenStorage>().setTokens(accessToken: token);

      try {
        await getIt<CurrentUserStore>().loadFromApi().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('[BiometricLogin] User info load timeout');
            return;
          },
        );
      } catch (e) {
        debugPrint('[BiometricLogin] User info load error: $e');
      }

      if (mounted) {
        final userRole = getIt<CurrentUserStore>().userRole?.toUpperCase();
        if (userRole == 'TEKNISI' || userRole == 'DELIVERY') {
          context.go(AppRoutes.pengiriman);
        } else if (userRole != null && userRole.contains('NOTA')) {
          context.go(AppRoutes.memo);
        } else if (userRole == 'GUDANG' ||
            (userRole != null && userRole.startsWith('MARKETING'))) {
          context.go(AppRoutes.stok);
        } else {
          context.go(AppRoutes.dashboard);
        }
      }
    } catch (e) {
      bool unregistered = false;
      if (e is DioException) {
        final response = e.response;
        if (response?.statusCode == 401) {
          final data = response?.data;
          final message = data is Map ? data['message']?.toString() : '';
          if (message != null && message.contains('Device not registered')) {
            unregistered = true;
          }
        }
      }

      if (unregistered && _deviceId != null) {
        try {
          await _biometricRepository.deleteBiometricKeys(_deviceId!);
          setState(() {
            _hasBiometricKeys = false;
          });
        } catch (_) {}
      }

      if (mounted) {
        AppFeedback.showError(
          context,
          unregistered
              ? 'Perangkat ini belum terdaftar di server. Silakan daftarkan biometrik Anda.'
              : 'Gagal login biometrik: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBiometric = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Movva ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Color.fromARGB(223, 9, 5, 89),
                      ),
                    ),
                    TextSpan(
                      text: 'by Anandam.id',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 16,
                        color: Color.fromARGB(255, 53, 205, 15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selamat datang. Masuk ke sistem manajemen stok Anda.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Username',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.userController,
                focusNode: _usernameFocusNode,
                decoration: InputDecoration(
                  hintText: 'Masukkan username',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),
              const SizedBox(height: 20),
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.passController,
                focusNode: _passwordFocusNode,
                obscureText: widget.obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Masukkan password',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      widget.obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.grey.shade600,
                      size: 22,
                    ),
                    onPressed: widget.onTogglePassword,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => widget.onSubmit(),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (widget.isLoading || _isLoadingBiometric)
                            ? null
                            : widget.onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: widget.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('LOGIN',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: (_isLoadingBiometric || widget.isLoading)
                            ? null
                            : _handleBiometricLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(color: Colors.blue.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: _isLoadingBiometric
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.fingerprint, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IllustrationPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100.withValues(alpha: 0.6),
            Colors.blue.shade200.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 80,
            left: 40,
            child: _ChartCircle(
                size: 120, color: Colors.blue.shade200.withValues(alpha: 0.5)),
          ),
          Positioned(
            top: 120,
            right: 60,
            child: _ChartCircle(
                size: 80, color: Colors.blue.shade300.withValues(alpha: 0.4)),
          ),
          Positioned(
            bottom: 120,
            left: 80,
            child: _BarStack(),
          ),
          Positioned(
            bottom: 180,
            right: 100,
            child: _DashboardCard(),
          ),
          Center(
            child: SvgPicture.asset(
              'assets/images/anandam-logo.svg',
              width: 140,
              height: 140,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCircle extends StatelessWidget {
  const _ChartCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        painter: _PieSlicePainter(),
        size: Size(size, size),
      ),
    );
  }
}

class _PieSlicePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade400.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -0.5,
      1.8,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarStack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Bar(
            width: 60,
            height: 24,
            color: Colors.blue.shade300.withValues(alpha: 0.5)),
        const SizedBox(height: 6),
        _Bar(
            width: 90,
            height: 24,
            color: Colors.blue.shade400.withValues(alpha: 0.5)),
        const SizedBox(height: 6),
        _Bar(
            width: 50,
            height: 24,
            color: Colors.blue.shade300.withValues(alpha: 0.5)),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 70,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
                4,
                (_) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade300.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    )),
          ),
          _Bar(
              width: 60,
              height: 8,
              color: Colors.blue.shade200.withValues(alpha: 0.6)),
          _Bar(
              width: 40,
              height: 8,
              color: Colors.blue.shade200.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade700,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    'assets/images/icon-anandam.svg',
                    width: 28,
                    height: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Stok Anandam',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Masuk ke sistem manajemen stok',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
