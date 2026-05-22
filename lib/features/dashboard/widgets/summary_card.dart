import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  static const List<Color> _cardColors = [
    Color(0xFF6366F1), // indigo
    Color(0xFFF59E0B), // amber
    Color(0xFF10B981), // emerald
    Color(0xFFEC4899), // pink
    Color(0xFF14B8A6), // teal
  ];

  @override
  Widget build(BuildContext context) {
    final color =
        iconColor ?? _cardColors[title.hashCode.abs() % _cardColors.length];
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    final isSmallMobile = MediaQuery.sizeOf(context).width < 600;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      shadowColor: Colors.black26,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(isSmallMobile
              ? 4
              : isMobile
                  ? 6
                  : 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: isMobile
              ? _buildMobileLayout(color)
              : _buildDesktopLayout(context, color),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        if (icon != null) const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Color color) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxHeight < 100;
          final isVerySmall = constraints.maxHeight < 80;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Container(
                  padding: EdgeInsets.all(isVerySmall
                      ? 4
                      : isSmall
                          ? 6
                          : 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon,
                      size: isVerySmall
                          ? 16
                          : isSmall
                              ? 18
                              : 20,
                      color: color),
                ),
              if (icon != null)
                SizedBox(
                    height: isVerySmall
                        ? 2
                        : isSmall
                            ? 4
                            : 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isVerySmall
                        ? 10
                        : isSmall
                            ? 11
                            : 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                  height: isVerySmall
                      ? 1
                      : isSmall
                          ? 2
                          : 4),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isVerySmall
                        ? 14
                        : isSmall
                            ? 16
                            : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(
                    height: isVerySmall
                        ? 0
                        : isSmall
                            ? 1
                            : 2),
                Flexible(
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: isVerySmall
                          ? 9
                          : isSmall
                              ? 10
                              : 11,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
