import 'package:flutter/material.dart';
import '../models/alert_message.dart';
import '../services/alert_service.dart';


class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  Color _colorForType(String type) {
    if (type.endsWith('_resolved')) return const Color(0xFF66BB6A);
    switch (type) {
      case 'temp':      return const Color(0xFFFF7043);
      case 'temp_cold': return const Color(0xFF90CAF9);
      case 'humidity':  return const Color(0xFF29B6F6);
      case 'water':     return const Color(0xFF26C6DA);
      case 'motion':    return const Color(0xFFFFB300);
      default:          return const Color(0xFF78909C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = AlertService.history;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F0A),
        title: const Text('📋 Historique alertes',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (alerts.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                AlertService.clearHistory();
                setState(() {});
              },
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFFF7043), size: 18),
              label: const Text('Vider',
                  style: TextStyle(
                      color: Color(0xFFFF7043), fontSize: 13)),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            onSelected: (val) async {
              if (val == 'reset') {
                await AlertService.resetAllStates();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '🔄 États réinitialisés — les alertes se déclencheront à nouveau',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Color(0xFF2E7D32),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  setState(() {});
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded,
                        color: Color(0xFF66BB6A), size: 18),
                    SizedBox(width: 8),
                    Text('Réinitialiser les états',
                        style: TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: alerts.isEmpty ? _buildEmpty() : _buildList(alerts),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: const Color(0xFF66BB6A).withOpacity(0.5), size: 64),
          const SizedBox(height: 16),
          Text('Aucune alerte pour le moment',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            'Chaque dépassement de seuil\ndéclenche une alerte unique.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.25), fontSize: 12),
          ),
          const SizedBox(height: 24),
          _buildThresholdsInfo(),
        ],
      ),
    );
  }

  Widget _buildList(List<AlertMessage> alerts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) return _buildThresholdsInfo();
        return _buildAlertTile(alerts[i - 1]);
      },
    );
  }

  Widget _buildThresholdsInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seuils de déclenchement automatique',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          _thresholdRow('🌡️', 'Temp. élevée', '> 35°C → Ventilateur',
              const Color(0xFFFF7043)),
          _thresholdRow('🥶', 'Temp. froide', '< 15°C → Chauffage',
              const Color(0xFF90CAF9)),
          _thresholdRow('💧', 'Humidité', '> 80%  → Alerte',
              const Color(0xFF29B6F6)),
          _thresholdRow('🪣', 'Eau', '< 20%  → Pompe',
              const Color(0xFF26C6DA)),
          _thresholdRow('🚨', 'Mouv. PIR', 'détecté → Buzzer',
              const Color(0xFFFFB300)),
          const SizedBox(height: 6),
          Text(
            '⚡ Actionneurs activés automatiquement par ESP32 — l\'app peut seulement désactiver.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _thresholdRow(
      String emoji, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile(AlertMessage alert) {
    final color    = _colorForType(alert.type);
    final resolved = alert.type.endsWith('_resolved');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(alert.icon,
                style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.message,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        height: 1.4)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        color: color.withOpacity(0.6), size: 12),
                    const SizedBox(width: 4),
                    Text(alert.formattedTime,
                        style: TextStyle(
                            color: color.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(alert.timeAgo,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        resolved ? 'RÉSOLU' : 'ALERTE',
                        style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}