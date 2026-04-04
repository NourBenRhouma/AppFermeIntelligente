import 'package:flutter/material.dart';

class ActuatorTile extends StatelessWidget {
  final String title;
  final String autoReason;
  final IconData icon;
  final bool value;
  final Color activeColor;
  final VoidCallback? onDisable;

  const ActuatorTile({
    super.key,
    required this.title,
    required this.autoReason,
    required this.icon,
    required this.value,
    required this.activeColor,
    this.onDisable,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: value
            ? activeColor.withOpacity(0.07)
            : const Color(0xFF13151C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? activeColor.withOpacity(0.25)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: value
                  ? activeColor.withOpacity(0.12)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: value ? activeColor : const Color(0xFF4A4F68),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: value ? const Color(0xFFF0F2FF) : const Color(0xFF8B90A8),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ? autoReason : 'En veille',
                  style: TextStyle(
                    color: value
                        ? activeColor.withOpacity(0.65)
                        : const Color(0xFF4A4F68),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: value
                  ? activeColor.withOpacity(0.12)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: value
                    ? activeColor.withOpacity(0.20)
                    : Colors.white.withOpacity(0.07),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? activeColor : const Color(0xFF4A4F68),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  value ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    color: value ? activeColor : const Color(0xFF4A4F68),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}