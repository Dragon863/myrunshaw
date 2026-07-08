import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:runshaw/pages/main/subpages/buses/helpers.dart';
import 'package:runshaw/utils/config.dart';


class BusCard extends StatelessWidget {
  const BusCard({
    super.key,
    required this.bus,
    this.onTap,
  });

  final BusInfo bus;
  final VoidCallback? onTap;

  static final List<Color> _badgeColors = MyRunshawConfig.busBayColors;

  Color _bayColor(int index) =>
      bus.bayColor ?? _badgeColors[index % _badgeColors.length];

  String get _subtitle {
    if (bus.status == BusStatus.waiting) return 'Not arrived yet';
    final timeAgo = bus.arrivedTimeAgo;
    return 'Arrived $timeAgo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final iconBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFF0EF);
    final iconColor = isDark ? Colors.white70 : Colors.black;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), side: BorderSide.none),
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              _StatusIcon(
                status: bus.status,
                bgColor: iconBg,
                iconColor: iconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bus.number,
                      style: GoogleFonts.rubik(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BayBadge(bus: bus, colorAt: _bayColor),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.status,
    required this.bgColor,
    required this.iconColor,
  });

  final BusStatus status;
  final Color bgColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
        child: Icon(
          status == BusStatus.waiting
              ? Icons.access_time_rounded
              : Icons.check_rounded,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }
}

class BayBadge extends StatelessWidget {
  const BayBadge({
    required this.bus,
    required this.colorAt,
  });

  final BusInfo bus;
  final Color Function(int index) colorAt;

  @override
  Widget build(BuildContext context) {
    final bool isWaiting = bus.status == BusStatus.waiting;
    final Color bg = colorAt(0);
    final String label = isWaiting ? '...' : (bus.bay ?? '?');

    return Container(
      constraints: const BoxConstraints(minWidth: 61, minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.rubik(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
