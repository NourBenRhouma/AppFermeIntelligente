import 'dart:async';
import 'package:flutter/material.dart';
import 'models/sensor_data.dart';
import 'services/ubidots_service.dart';
import 'services/alert_service.dart';
import 'widgets/sensor_card.dart';
import 'widgets/actuator_tile.dart';
import 'widgets/alerts_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  SensorData _data = SensorData(
    temperature: 0,
    humidity: 0,
    motion: false,
    waterLevel: 0,
  );

  bool _useFakeData = false;
  bool _isLoading = false;
  String _status = 'Connexion à Ubidots...';

  Timer? _timer;

  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  // ── Overrides manuels ───────────────────────────────────
  final Map<String, bool> _manualOverrideOff = {
    'fan':    false,
    'heater': false,
    'pump':   false,
    'buzzer': false,
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _pulseAnim =
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer?.cancel();
    // Intervalle 15s pour éviter le rate limit Ubidots (plan gratuit)
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
    _refresh();
  }

  // ════════════════════════════════════════════════════════
  //  REFRESH
  // ════════════════════════════════════════════════════════
  Future<void> _refresh() async {
    if (_useFakeData) {
      final fake = SensorData.fake();
      await AlertService.checkAndNotify(fake);
      if (mounted) {
        setState(() {
          _data   = fake;
          _status = '🟡 Données simulées';
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      // 1. Lecture capteurs
      final raw = await UbidotsService.fetchSensorData();

      // 2. Réinitialiser overrides si condition disparue
      if (raw.temperature <= 35.0) _manualOverrideOff['fan']    = false;
      if (raw.temperature >= 15.0) _manualOverrideOff['heater'] = false;
      if (raw.waterLevel  >= 20.0) _manualOverrideOff['pump']   = false;
      if (!raw.motion)              _manualOverrideOff['buzzer'] = false;

      // 3. Appliquer overrides manuels
      final fanOn    = _manualOverrideOff['fan']!    ? false : raw.fanOn;
      final heaterOn = _manualOverrideOff['heater']! ? false : raw.heaterOn;
      final pumpOn   = _manualOverrideOff['pump']!   ? false : raw.pumpOn;
      final buzzerOn = _manualOverrideOff['buzzer']! ? false : raw.buzzerOn;

      // 4. Envoi séquentiel espacé de 500ms — évite le status 429
      //    On n'envoie QUE si l'état a changé (économise les requêtes)
      if (fanOn != _data.fanOn) {
        await UbidotsService.setFan(fanOn ? 1 : 0);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (heaterOn != _data.heaterOn) {
        await UbidotsService.setHeater(heaterOn ? 1 : 0);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (pumpOn != _data.pumpOn) {
        await UbidotsService.setPump(pumpOn ? 1 : 0);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (buzzerOn != _data.buzzerOn) {
        await UbidotsService.setBuzzer(buzzerOn ? 1 : 0);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // 5. Construire SensorData final
      final data = SensorData(
        temperature: raw.temperature,
        humidity:    raw.humidity,
        motion:      raw.motion,
        waterLevel:  raw.waterLevel,
        fanOn:    fanOn,
        heaterOn: heaterOn,
        pumpOn:   pumpOn,
        buzzerOn: buzzerOn,
      );

      await AlertService.checkAndNotify(data);

      if (mounted) {
        setState(() {
          _data   = data;
          _status = '🟢 Ubidots — ${_timeNow()}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = '🔴 Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _timeNow() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:'
        '${n.minute.toString().padLeft(2, '0')}:'
        '${n.second.toString().padLeft(2, '0')}';
  }

  // ════════════════════════════════════════════════════════
  //  ACTIONNEURS — contrôle manuel
  //  Délai 600ms après envoi avant refresh pour laisser
  //  Ubidots enregistrer la valeur (évite 429)
  // ════════════════════════════════════════════════════════
  Future<void> _setFan(int v) async {
    if (v == 0) _manualOverrideOff['fan'] = true;
    await UbidotsService.setFan(v);
    await Future.delayed(const Duration(milliseconds: 600));
    await _refresh();
  }

  Future<void> _setHeater(int v) async {
    if (v == 0) _manualOverrideOff['heater'] = true;
    await UbidotsService.setHeater(v);
    await Future.delayed(const Duration(milliseconds: 600));
    await _refresh();
  }

  Future<void> _setPump(int v) async {
    if (v == 0) _manualOverrideOff['pump'] = true;
    await UbidotsService.setPump(v);
    await Future.delayed(const Duration(milliseconds: 600));
    await _refresh();
  }

  Future<void> _setBuzzer(int v) async {
    if (v == 0) {
      _manualOverrideOff['buzzer'] = true;
      await UbidotsService.setMotion(0);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    await UbidotsService.setBuzzer(v);
    await Future.delayed(const Duration(milliseconds: 600));
    await _refresh();
  }

  // ── Couleurs dynamiques ─────────────────────────────────
  Color get _tempColor {
    if (_data.temperature < 15) return const Color(0xFF90CAF9);
    if (_data.temperature < 35) return const Color(0xFF66BB6A);
    return const Color(0xFFFF7043);
  }

  Color get _waterColor {
    if (_data.waterLevel < 20) return const Color(0xFFFF7043);
    if (_data.waterLevel < 50) return const Color(0xFFFFB300);
    return const Color(0xFF26C6DA);
  }

  int get _alertCount => AlertService.history.length;

  // ════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D06),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBar(),
                    const SizedBox(height: 12),
                    _buildAlertShortcut(),
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                        '📡', 'Capteurs', 'DHT22 · HC-SR04 · PIR HC-SR501'),
                    const SizedBox(height: 14),
                    _buildSensorsGrid(),
                    const SizedBox(height: 28),
                    _buildSectionHeader('🎛️', 'Actionneurs',
                        'Contrôle auto ESP32 — désactivation uniquement'),
                    const SizedBox(height: 14),
                    _buildActuators(),
                    const SizedBox(height: 28),
                    _buildAlertBanner(),
                    const SizedBox(height: 28),
                    _buildSmsEmailInfo(),
                    const SizedBox(height: 28),
                    _buildModeToggle(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF060D06),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Smart Farm',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3)),
                Text('Dashboard IoT',
                    style: TextStyle(
                        fontSize: 10,
                        color: const Color(0xFF4CAF50).withOpacity(0.8),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D2010), Color(0xFF060D06)],
                ),
              ),
            ),
            Positioned(
              right: -20, top: -20,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50).withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              right: 30, top: 10,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50).withOpacity(0.08),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: _alertCount > 0
                    ? const Color(0xFFFF7043).withOpacity(0.15)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _alertCount > 0
                      ? const Color(0xFFFF7043).withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  _alertCount > 0
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: _alertCount > 0
                      ? const Color(0xFFFF7043)
                      : Colors.white.withOpacity(0.7),
                  size: 22,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsPage()),
                ).then((_) => setState(() {})),
              ),
            ),
            if (_alertCount > 0)
              Positioned(
                top: 8, right: 8,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7043),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7043)
                              .withOpacity(0.5 * _pulseAnim.value),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Text(
                      _alertCount > 9 ? '9+' : '$_alertCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xFF4CAF50).withOpacity(0.8),
              ),
            ),
          )
        else
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: Colors.white.withOpacity(0.5), size: 20),
            onPressed: _refresh,
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Barre de statut ──────────────────────────────────────
  Widget _buildStatusBar() {
    final isConnected = _status.startsWith('🟢');
    final isError     = _status.startsWith('🔴');
    final statusColor = isConnected
        ? const Color(0xFF4CAF50)
        : isError
            ? const Color(0xFFFF7043)
            : const Color(0xFFFFB300);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.5 * _pulseAnim.value),
                    blurRadius: 4,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_status,
                style: TextStyle(
                    color: statusColor.withOpacity(0.9), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Raccourci alertes ────────────────────────────────────
  Widget _buildAlertShortcut() {
    final count = _alertCount;
    return GestureDetector(
      onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsPage()))
          .then((_) => setState(() {})),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: count > 0
              ? const Color(0xFFFF7043).withOpacity(0.1)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: count > 0
                ? const Color(0xFFFF7043).withOpacity(0.35)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: count > 0
                    ? const Color(0xFFFF7043).withOpacity(0.15)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                count > 0
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: count > 0
                    ? const Color(0xFFFF7043)
                    : Colors.white.withOpacity(0.35),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count > 0
                        ? '$count alerte(s) enregistrée(s)'
                        : 'Aucune alerte',
                    style: TextStyle(
                      color: count > 0
                          ? const Color(0xFFFF7043)
                          : Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    count > 0
                        ? 'Appuyer pour voir l\'historique'
                        : 'Historique vide',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.25), size: 20),
          ],
        ),
      ),
    );
  }

  // ── En-têtes de section ──────────────────────────────────
  Widget _buildSectionHeader(String emoji, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 3, height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4CAF50), Color(0xFF1B5E20)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
              ],
            ),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    letterSpacing: 0.3)),
          ],
        ),
      ],
    );
  }

  // ── Grille capteurs ─────────────────────────────────────
  Widget _buildSensorsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        SensorCard(
          title: 'Température',
          value: '${_data.temperature.toStringAsFixed(1)} °C',
          icon: _data.temperature < 15
              ? Icons.ac_unit_rounded
              : Icons.thermostat_rounded,
          color: _tempColor,
          subtitle: _data.temperature > 35
              ? '⚠️ CHAUD'
              : _data.temperature < 15
                  ? '❄️ FROID'
                  : 'NORMAL',
        ),
        SensorCard(
          title: 'Humidité',
          value: '${_data.humidity.toStringAsFixed(0)} %',
          icon: Icons.water_drop_rounded,
          color: const Color(0xFF29B6F6),
          subtitle: _data.humidity > 80
              ? '⚠️ ÉLEVÉ'
              : _data.humidity < 40
                  ? '⚠️ SEC'
                  : 'OK',
        ),
        SensorCard(
          title: 'Mouvement PIR',
          value: _data.motion ? 'Détecté !' : 'Aucun',
          icon: _data.motion
              ? Icons.directions_run_rounded
              : Icons.person_off_rounded,
          color: _data.motion
              ? const Color(0xFFFF7043)
              : const Color(0xFF78909C),
          subtitle: _data.motion ? '🔴 ALERTE' : 'CALME',
        ),
        SensorCard(
          title: 'Réservoir eau',
          value: '${_data.waterLevel.toStringAsFixed(0)} %',
          icon: Icons.water_rounded,
          color: _waterColor,
          subtitle: _data.waterLevel < 20
              ? '⚠️ BAS'
              : _data.waterLevel < 50
                  ? 'MOYEN'
                  : 'BON',
        ),
      ],
    );
  }

  // ── Actionneurs ─────────────────────────────────────────
  Widget _buildActuators() {
    return Column(
      children: [
        ActuatorTile(
          title: 'Ventilateur',
          autoReason: 'Temp > 35°C',
          icon: Icons.air_rounded,
          value: _data.fanOn,
          activeColor: const Color(0xFF66BB6A),
          onDisable: () => _setFan(0),
        ),
        ActuatorTile(
          title: 'Chauffage',
          autoReason: 'Temp < 15°C',
          icon: Icons.local_fire_department_rounded,
          value: _data.heaterOn,
          activeColor: const Color(0xFFFF8A65),
          onDisable: () => _setHeater(0),
        ),
        ActuatorTile(
          title: 'Pompe à eau',
          autoReason: 'Eau < 20%',
          icon: Icons.water_damage_rounded,
          value: _data.pumpOn,
          activeColor: const Color(0xFF29B6F6),
          onDisable: () => _setPump(0),
        ),
        ActuatorTile(
          title: 'Buzzer / Alarme',
          autoReason: 'Mouvement PIR',
          icon: Icons.notifications_active_rounded,
          value: _data.buzzerOn,
          activeColor: const Color(0xFFFF7043),
          onDisable: () => _setBuzzer(0),
        ),
      ],
    );
  }

  // ── Bannière alertes actives ────────────────────────────
  Widget _buildAlertBanner() {
    final List<_AlertEntry> alerts = [];
    if (_data.temperature > 35) {
      alerts.add(_AlertEntry('🌡️ ${_data.temperature.toStringAsFixed(1)}°C',
          'Ventilateur ON', const Color(0xFFFF7043)));
    }
    if (_data.temperature < 15) {
      alerts.add(_AlertEntry('🥶 ${_data.temperature.toStringAsFixed(1)}°C',
          'Chauffage ON', const Color(0xFF90CAF9)));
    }
    if (_data.humidity > 80) {
      alerts.add(_AlertEntry('💧 ${_data.humidity.toStringAsFixed(0)}%',
          'Humidité élevée', const Color(0xFF29B6F6)));
    }
    if (_data.waterLevel < 20) {
      alerts.add(_AlertEntry('🪣 ${_data.waterLevel.toStringAsFixed(0)}%',
          'Pompe ON', const Color(0xFFFFB300)));
    }
    if (_data.motion) {
      alerts.add(_AlertEntry(
          '🚨 Mouvement', 'Buzzer ON', const Color(0xFFFF5252)));
    }

    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20).withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tous les paramètres normaux',
                    style: TextStyle(
                        color: Color(0xFF66BB6A),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text('Aucune action automatique active',
                    style: TextStyle(
                        color: const Color(0xFF4CAF50).withOpacity(0.5),
                        fontSize: 11)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7F0000).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF7043).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFFF7043), size: 16),
              ),
              const SizedBox(width: 10),
              Text('${alerts.length} alerte(s) active(s)',
                  style: const TextStyle(
                      color: Color(0xFFFF7043),
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: alerts
                .map((a) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: a.color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(a.label,
                              style: TextStyle(
                                  color: a.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Text('→ ${a.action}',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Infos SMS/Email ──────────────────────────────────────
  Widget _buildSmsEmailInfo() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1929),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                    color: const Color(0xFF1565C0).withOpacity(0.2)),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.mark_email_read_rounded,
                    color: Color(0xFF42A5F5), size: 18),
                SizedBox(width: 10),
                Text('Alertes SMS & Email — Ubidots',
                    style: TextStyle(
                        color: Color(0xFF42A5F5),
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow('🌡️', 'Temp > 35°C',    'Email+SMS', '→ Ventilateur', const Color(0xFFFF7043)),
                _infoRow('🥶', 'Temp < 15°C',    'Email+SMS', '→ Chauffage',   const Color(0xFF90CAF9)),
                _infoRow('💧', 'Humidité > 80%', 'Email',     '→ Ventilation', const Color(0xFF29B6F6)),
                _infoRow('🪣', 'Eau < 20%',      'Email+SMS', '→ Pompe',       const Color(0xFF26C6DA)),
                _infoRow('🚨', 'Mouvement PIR',  'SMS',       '→ Buzzer',      const Color(0xFFFFB300)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.settings_rounded,
                          color: Colors.white.withOpacity(0.3), size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ubidots → Device "smart-farm" → Variable → Events → Add Event → Trigger → Send Email/SMS',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 10,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String emoji, String condition, String channel,
      String action, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(condition,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Text(channel,
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(action,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ── Mode données ─────────────────────────────────────────
  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.settings_rounded,
                    color: Colors.white.withOpacity(0.5), size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mode de données',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text(
                    _useFakeData ? 'Simulation locale' : 'API Ubidots — temps réel',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            _modeButton('🧪  Simulation', true),
            const SizedBox(width: 10),
            _modeButton('🌐  Ubidots API', false),
          ]),
        ],
      ),
    );
  }

  Widget _modeButton(String label, bool isFake) {
    final isActive = _useFakeData == isFake;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _useFakeData = isFake);
          _manualOverrideOff.updateAll((_, __) => false);
          _startAutoRefresh();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)])
                : null,
            color: isActive ? null : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF4CAF50).withOpacity(0.5)
                  : Colors.white.withOpacity(0.08),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.35),
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
        ),
      ),
    );
  }
}

class _AlertEntry {
  final String label;
  final String action;
  final Color color;
  const _AlertEntry(this.label, this.action, this.color);
}