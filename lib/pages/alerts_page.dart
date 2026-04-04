import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/alert_service.dart';

// Design tokens from HTML mockup
const Color _bg      = Color(0xFF0A0B0F);
const Color _surface = Color(0xFF13151C);
const Color _green   = Color(0xFF3DDC84);
const Color _amber   = Color(0xFFFFB340);
const Color _blue    = Color(0xFF4A9EFF);
const Color _red     = Color(0xFFFF5C5C);
const Color _text    = Color(0xFFF0F2FF);
const Color _text2   = Color(0xFF8B90A8);
const Color _text3   = Color(0xFF4A4F68);

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});
  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Color _colorForType(String type) {
    if (type.endsWith('_resolved')) return _green;
    switch (type) {
      case 'temp_hot':  return _red;
      case 'temp_cold': return _blue;
      case 'humidity':  return _blue;
      case 'water':     return _amber;
      case 'mouvement': return _amber;
      default:          return _text2;
    }
  }

  String _labelForType(String type) {
    if (type.endsWith('_resolved')) return 'Résolu';
    switch (type) {
      case 'temp_hot':  return 'Chaleur';
      case 'temp_cold': return 'Froid';
      case 'humidity':  return 'Humidité';
      case 'water':     return 'Eau';
      case 'mouvement': return 'Mouvement';
      default:          return 'Alerte';
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'temp_hot':  return Icons.thermostat_rounded;
      case 'temp_cold': return Icons.ac_unit_rounded;
      case 'humidity':  return Icons.water_drop_rounded;
      case 'water':     return Icons.water_rounded;
      case 'mouvement': return Icons.directions_run_rounded;
      default:          return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = AlertService.history;
    final dev = AlertService.devAlerts;
    final cam = AlertService.camAlerts;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          // .alerts-header
          _buildHeader(all),
          // .filter-tabs
          _buildFilterTabs(all, dev, cam),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildList(all),
                _buildList(dev),
                _buildList(cam),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // .alerts-header
  Widget _buildHeader(List<AlertMessage> all) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        // .back-btn
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: const Center(
              child: Text('←', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text('Notifications',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                  color: _text, letterSpacing: -0.3)),
        ),
        if (all.isNotEmpty)
          GestureDetector(
            onTap: () {
              AlertService.clearHistory();
              setState(() {});
            },
            child: const Text('Effacer',
                style: TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: _text3, size: 18),
          color: const Color(0xFF1A1D24),
          onSelected: (val) async {
            if (val == 'reset') {
              await AlertService.resetAllStates();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('États réinitialisés',
                      style: TextStyle(color: Colors.white)),
                  backgroundColor: _surface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: _green.withOpacity(0.3)),
                  ),
                ));
                setState(() {});
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'reset',
              child: Text('Réinitialiser', style: TextStyle(color: _text, fontSize: 13)),
            ),
          ],
        ),
      ]),
    );
  }

  // .filter-tabs
  Widget _buildFilterTabs(
      List<AlertMessage> all, List<AlertMessage> dev, List<AlertMessage> cam) {
    final labels = [
      'Tout${all.isNotEmpty ? " (${all.length})" : ""}',
      'Serre${dev.isNotEmpty ? " (${dev.length})" : ""}',
      'Caméra${cam.isNotEmpty ? " (${cam.length})" : ""}',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = _tab.index == i;
          return Padding(
            padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
            child: GestureDetector(
              onTap: () => _tab.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF1A3D2B) : _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? _green.withOpacity(0.30) : Colors.white.withOpacity(0.07),
                  ),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: isActive ? _green : _text2,
                    fontSize: 11, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // .alerts-list
  Widget _buildList(List<AlertMessage> alerts) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.08), shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: _green.withOpacity(0.6), size: 34),
          ),
          const SizedBox(height: 16),
          Text('Tout est normal',
              style: TextStyle(color: _text2, fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Aucune notification', style: TextStyle(color: _text3, fontSize: 12)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: alerts.length,
      itemBuilder: (_, i) => _buildTile(alerts[i]),
    );
  }

  // .alert-item
  Widget _buildTile(AlertMessage alert) {
    final color = _colorForType(alert.type);
    final resolved = alert.type.endsWith('_resolved');
    final deviceLabel = alert.device == 'dev' ? 'Serre' : 'Caméra';
    final deviceColor = alert.device == 'dev' ? _green : _amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // .alert-dot
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            resolved ? Icons.check_rounded : _iconForType(alert.type),
            color: color, size: 16,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // .alert-msg
          Text(alert.message,
              style: TextStyle(color: _text.withOpacity(0.85), fontSize: 12, height: 1.45)),
          const SizedBox(height: 5),
          // .alert-meta
          Row(children: [
            Text(deviceLabel,
                style: TextStyle(color: deviceColor, fontSize: 11, fontWeight: FontWeight.w600)),
            Text(' · ${alert.timeAgo}',
                style: TextStyle(color: _text3, fontSize: 11)),
            const Spacer(),
            // .alert-tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_labelForType(alert.type),
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ]),
        ])),
      ]),
    );
  }
}