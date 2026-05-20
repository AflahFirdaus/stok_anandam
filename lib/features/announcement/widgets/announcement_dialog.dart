import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../data/models/announcement.dart';

class AnnouncementDialog extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDialog({super.key, required this.announcement});

  static Future<void> show(BuildContext context, Announcement announcement) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => AnnouncementDialog(announcement: announcement),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;

    // Premium dynamic colors
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;
    
    final headerGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withOpacity(0.25),
              primaryColor.withOpacity(0.1),
              surfaceColor,
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.85),
              primaryColor.withOpacity(0.7),
            ],
          );

    final cardBorderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : primaryColor.withOpacity(0.08);

    final cardShadowColor = isDark
        ? Colors.black.withOpacity(0.4)
        : primaryColor.withOpacity(0.12);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Center(
        child: SingleChildScrollView(
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
              vertical: 24,
            ),
            child: Container(
              width: 480,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cardBorderColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cardShadowColor,
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: primaryColor.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Premium Header with dynamic theme gradient
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: headerGradient,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? primaryColor.withOpacity(0.15) 
                                  : Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark 
                                    ? primaryColor.withOpacity(0.3) 
                                    : Colors.white.withOpacity(0.25),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.campaign_rounded,
                              size: 36,
                              color: isDark ? primaryColor : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? primaryColor.withOpacity(0.2) 
                                  : Colors.amber.shade400,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: isDark ? null : [
                                BoxShadow(
                                  color: Colors.amber.shade700.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Text(
                              'PENGUMUMAN RESMI',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? primaryColor : const Color(0xFF0F2027),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content Body
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            announcement.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: onSurfaceColor,
                              height: 1.3,
                              letterSpacing: -0.2,
                            ) ?? TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: onSurfaceColor,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 1.5,
                            color: isDark 
                                ? Colors.white.withOpacity(0.06) 
                                : Colors.grey.shade100,
                          ),
                          const SizedBox(height: 18),
                          
                          // Scrollable Subtitle content in case of long text
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 180),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Text(
                                announcement.subtitle,
                                textAlign: TextAlign.left,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark 
                                      ? Colors.grey.shade400 
                                      : Colors.grey.shade600,
                                  height: 1.55,
                                  fontWeight: FontWeight.w400,
                                ) ?? TextStyle(
                                  fontSize: 13.5,
                                  color: isDark 
                                      ? Colors.grey.shade400 
                                      : Colors.grey.shade600,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          
                          // Custom Accent Button matching theme
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: primaryColor,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              elevation: 2,
                              shadowColor: primaryColor.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'SAYA MENGERTI',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.black : Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
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
