import 'dart:math';
class DevData {
  // ── Capteurs ──────────────────────────────────────────────────
  final double temperature;
  final double humidite;
  final double niveauEau;

  // ── Actionneurs ───────────────────────────────────────────────
  final bool fanOn;
  final bool heaterOn;
  final bool pumpOn;

  // ── Alertes Ubidots ───────────────────────────────────────────
  final bool alerteChaud;    // alerte_chaud
  final bool alerteNiveau;   // alerte_niveau

  // ── Switches de demande manuelle ─────────────────────────────
  final bool switchRequete;    // switch_requete   → demande niveau eau
  final bool switchRequeteTh;  // switch_requete_th → demande temp + humidité

  // ── État connexion ────────────────────────────────────────────
  final bool connected;

  const DevData({
    required this.temperature,
    required this.humidite,
    required this.niveauEau,
    this.fanOn         = false,
    this.heaterOn      = false,
    this.pumpOn        = false,
    this.alerteChaud   = false,
    this.alerteNiveau  = false,
    this.switchRequete   = false,
    this.switchRequeteTh = false,
    this.connected     = false,
  });

  factory DevData.zero() => const DevData(
    temperature: 0, humidite: 0, niveauEau: 0,
  );

  
}

class CamData {
  // ── Capteur ───────────────────────────────────────────────────
  final bool mouvement;   // mouvement

  // ── Contrôle ─────────────────────────────────────────────────
  final bool stopAlarme;    // stop_alarme
  final bool demandePhoto;  // demande_photo

  // ── Photo ─────────────────────────────────────────────────────
  final String? lastPhotoUrl;

  // ── État connexion ────────────────────────────────────────────
  final bool connected;

  const CamData({
    required this.mouvement,
    this.stopAlarme   = false,
    this.demandePhoto = false,
    this.lastPhotoUrl,
    this.connected    = false,
  });

  factory CamData.zero() => const CamData(mouvement: false);

  
}

/// Message d'alerte unifié
class AlertMessage {
  final String message;
  final DateTime timestamp;
  final String type;
  final String device;

  AlertMessage({
    required this.message,
    required this.timestamp,
    required this.type,
    required this.device,
  });

  String get icon {
    switch (type) {
      case 'temp_hot':   return '🌡️';
      case 'temp_cold':  return '🥶';
      case 'humidity':   return '💧';
      case 'water':      return '🪣';
      case 'mouvement':  return '🚨';
      default:
        if (type.endsWith('_resolved')) return '✅';
        return '⚠️';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60)  return 'il y a ${diff.inSeconds}s';
    if (diff.inMinutes < 60)  return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24)    return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2,'0')}:'
        '${timestamp.minute.toString().padLeft(2,'0')}:'
        '${timestamp.second.toString().padLeft(2,'0')}';
  }
}
