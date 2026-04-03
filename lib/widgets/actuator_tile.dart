import 'package:flutter/material.dart';

class ActuatorTile extends StatelessWidget {
  final String title;
  final String autoReason;   // ex: "Temp > 35°C"
  final IconData icon;
  final bool value;          // état actuel lu depuis Ubidots
  final Color activeColor;
  final VoidCallback onDisable;   // envoie 0 à Ubidots (seule action permise)

  const ActuatorTile({
    super.key,
    required this.title,
    required this.autoReason,
    required this.icon,
    required this.value,
    required this.activeColor,
    required this.onDisable,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: value
              ? [activeColor.withOpacity(0.2), activeColor.withOpacity(0.08)]
              : [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? activeColor.withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Icône ──────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: value
                    ? activeColor.withOpacity(0.25)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: value ? activeColor : Colors.white.withOpacity(0.4),
                  size: 22),
            ),
            const SizedBox(width: 12),

            // ── Texte ───────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    value
                        ? '🟢 AUTO — $autoReason'
                        : '⚫ INACTIF — Contrôle auto ESP32',
                    style: TextStyle(
                      color: value
                          ? activeColor
                          : Colors.white.withOpacity(0.35),
                      fontSize: 12,
                      fontWeight:
                          value ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // ── Bouton : Désactiver si ON, label "Auto" si OFF ──
            value
                // Actionneur ON → seul bouton Désactiver disponible
                ? TextButton.icon(
                    onPressed: onDisable,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.stop_circle_outlined,
                        color: Colors.redAccent, size: 16),
                    label: const Text('Désactiver',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  )
                // Actionneur OFF → badge informatif (pas de bouton Activer)
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_mode_rounded,
                            color: Colors.white.withOpacity(0.3), size: 14),
                        const SizedBox(width: 5),
                        Text('Auto',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}