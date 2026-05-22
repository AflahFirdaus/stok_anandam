import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/token_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _backgroundController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    // Controller untuk logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Controller untuk text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Controller untuk progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controller untuk background gradient animation
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Logo scale animation (bounce effect)
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_logoController);

    // Logo rotation animation (subtle rotation)
    _logoRotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Text fade animation
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    // Text slide animation
    _textSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    // Progress animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Background animation (for gradient shift)
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start logo animation
    await _logoController.forward();

    // Start text animation after logo starts
    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();

    // Start progress animation
    _progressController.forward();

    // Start background animation
    _backgroundController.repeat(reverse: true);

    // Wait for all animations and then navigate
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Check if user is logged in
    final tokenStorage = getIt<TokenStorage>();
    final hasToken =
        tokenStorage.token != null && tokenStorage.token!.isNotEmpty;

    bool loadSuccess = false;
    if (hasToken) {
      try {
        debugPrint('[Splash] Token found. Loading current user data...');
        // Add 3-second timeout to keep splash fast
        await getIt<CurrentUserStore>().loadFromApi().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint(
                '[Splash] CurrentUserStore.loadFromApi() timed out after 3s.');
            // We don't throw here, just mark as failed and proceed
          },
        );

        if (!mounted) return;
        loadSuccess = getIt<CurrentUserStore>().userRole != null;
        debugPrint(
            '[Splash] User data load ${loadSuccess ? 'success' : 'failed'}. Role: ${getIt<CurrentUserStore>().userRole}');
      } catch (e) {
        debugPrint('[Splash] Error loading user data: $e');
        // If it fails, we still proceed to see if the router can handle it or force login
        loadSuccess = false;
      }
    } else {
      debugPrint('[Splash] No token found.');
    }

    // Double check mounted status before navigation
    if (!mounted) return;

    // Navigate based on authentication status
    if (hasToken) {
      final userRole = getIt<CurrentUserStore>().userRole?.toUpperCase();
      debugPrint('[Splash] Token exists. Role: $userRole');

      if (userRole == 'TEKNISI' || userRole == 'DELIVERY') {
        context.go(AppRoutes.pengiriman);
      } else if (userRole != null && userRole.contains('NOTA')) {
        context.go(AppRoutes.memo);
      } else if (userRole == 'GUDANG' ||
          (userRole != null && userRole.startsWith('MARKETING'))) {
        context.go(AppRoutes.stok);
      } else if (userRole == 'ADMIN' ||
          (userRole != null && userRole.startsWith('SPV_'))) {
        context.go(AppRoutes.dashboard);
      } else {
        // Default to stok if role is unknown but we have a token (Marketing/Gudang fallback)
        context.go(AppRoutes.stok);
      }
    } else {
      debugPrint('[Splash] No token found. Navigating to Login.');
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _textController,
          _progressController,
          _backgroundController,
        ]),
        builder: (context, child) {
          // Animated gradient colors
          final primaryColor = colorScheme.primary;
          final animatedColor1 = Color.lerp(
            primaryColor,
            primaryColor.withValues(alpha: 0.7),
            _backgroundAnimation.value,
          )!;
          final animatedColor2 = Color.lerp(
            primaryColor.withValues(alpha: 0.8),
            primaryColor.withValues(alpha: 0.6),
            _backgroundAnimation.value,
          )!;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  animatedColor1,
                  animatedColor2,
                  primaryColor.withValues(alpha: 0.5),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo dengan animasi
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        Transform.scale(
                          scale: _logoScaleAnimation.value * 1.3,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.3),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Main logo
                        Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Transform.rotate(
                            angle: _logoRotationAnimation.value,
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: SvgPicture.asset(
                                'assets/images/icon-anandam.svg',
                                width: 140,
                                height: 140,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // App name dengan animasi
                    FadeTransition(
                      opacity: _textFadeAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_textSlideAnimation),
                        child: Column(
                          children: [
                            Text(
                              'Stok Anandam',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Inventory Management System',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Progress indicator dengan animasi
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 80),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.9),
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Loading text
                    FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Text(
                        'Memuat aplikasi...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
