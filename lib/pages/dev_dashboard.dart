import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/ubidots_service.dart';
import '../services/alert_service.dart';
import '../widgets/sensor_card.dart';
import '../widgets/actuator_tile.dart';
import 'alerts_page.dart';

// Design tokens matching HTML mockup
const Color _bg       = Color(0xFF0A0B0F);
const Color _surface  = Color(0xFF13151C);
const Color _surface2 = Color(0xFF1C1F2B);
const Color _green    = Color(0xFF3DDC84);
const Color _greenDim = Color(0xFF1A3D2B);
const Color _amber    = Color(0xFFFFB340);
const Color _blue     = Color(0xFF4A9EFF);
const Color _red      = Color(0xFFFF5C5C);
const Color _text     = Color(0xFFF0F2FF);
const Color _text2    = Color(0xFF8B90A8);
const Color _text3    = Color(0xFF4A4F68);

class DevDashboard extends StatefulWidget {
  const DevDashboard({super.key});
  @override
  State<DevDashboard> createState() => _DevDashboardState();
}

class _DevDashboardState extends State<DevDashboard>
    with TickerProviderStateMixin {

  DevData _data      = DevData.zero();
  bool _isLoading    = false;
  String _lastUpdate = '';

  bool _loadingRequeteEau = false;
  bool _loadingRequeteTh  = false;

  final Map<String, bool> _overrideOff = {
    'fan': false, 'heater': false, 'pump': false,
  };

  static const Duration _periodicInterval = Duration(minutes: 3);
  int _secondsUntilNext = 180;
  Timer? _periodicTimer;
  Timer? _countdown;

  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double>   _pulseAnim;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl,  curve: Curves.easeOut);
    _fadeCtrl.forward();
    _startPeriodicTimer();
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _countdown?.cancel();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _runMode1();
    _periodicTimer = Timer.periodic(_periodicInterval, (_) => _runMode1());
    _startCountdown();
  }

  void _startCountdown() {
    _countdown?.cancel();
    setState(() => _secondsUntilNext = _periodicInterval.inSeconds);
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsUntilNext > 0 ? _secondsUntilNext-- : _secondsUntilNext = _periodicInterval.inSeconds);
    });
  }

  Future<void> _runMode1() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final raw = await UbidotsService.fetchDevData();
      if (raw.temperature <= 35.0 && raw.humidite <= 80.0) _overrideOff['fan']    = false;
      if (raw.temperature >= 15.0)                          _overrideOff['heater'] = false;
      if (raw.niveauEau   >= 20.0)                          _overrideOff['pump']   = false;
      final data = await UbidotsService.applyAlertsAndSendDev(raw: raw, overrideOff: _overrideOff);
      await AlertService.checkDev(data);
      if (mounted) setState(() { _data = data; _lastUpdate = _now(); });
      _startCountdown();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _demandeNiveauEau() async {
    if (_loadingRequeteEau || _loadingRequeteTh) return;
    setState(() => _loadingRequeteEau = true);
    try {
      final updated = await UbidotsService.fetchNiveauEauOnly(_data);
      if (updated.niveauEau < 20.0 && !_data.pumpOn) {
        final withAlerts = await UbidotsService.applyAlertsAndSendDev(raw: updated, overrideOff: _overrideOff);
        await AlertService.checkDev(withAlerts);
        if (mounted) setState(() { _data = withAlerts; _lastUpdate = _now(); });
      } else {
        await AlertService.checkDev(updated);
        if (mounted) setState(() { _data = updated; _lastUpdate = _now(); });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingRequeteEau = false);
    }
  }

  Future<void> _demandeTemperatureHumidite() async {
    if (_loadingRequeteEau || _loadingRequeteTh) return;
    setState(() => _loadingRequeteTh = true);
    try {
      final updated = await UbidotsService.fetchTempHumOnly(_data);
      final needsMode3 = (updated.temperature > 35.0 || updated.humidite > 90.0 || updated.temperature < 5.0) && (!_data.fanOn && !_data.heaterOn);
      if (needsMode3) {
        final withAlerts = await UbidotsService.applyAlertsAndSendDev(raw: updated, overrideOff: _overrideOff);
        await AlertService.checkDev(withAlerts);
        if (mounted) setState(() { _data = withAlerts; _lastUpdate = _now(); });
      } else {
        await AlertService.checkDev(updated);
        if (mounted) setState(() { _data = updated; _lastUpdate = _now(); });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingRequeteTh = false);
    }
  }

  String _now() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}';
  }

  Color get _tempColor {
    if (_data.temperature < 15) return _blue;
    if (_data.temperature < 35) return _green;
    return _red;
  }
  Color get _waterColor {
    if (_data.niveauEau < 20) return _red;
    if (_data.niveauEau < 50) return _amber;
    return _blue;
  }

  int get _alertCount  => AlertService.devAlerts.length;
  bool get _connected  => _lastUpdate.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        onRefresh: _runMode1,
        color: _green,
        backgroundColor: _surface,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 12),
                  _buildUpdateRow(),
                  const SizedBox(height: 20),
                  _buildSensorsSection(),
                  const SizedBox(height: 20),
                  _buildActuatorsSection(),
                  const SizedBox(height: 20),
                  _buildManualSection(),
                  const SizedBox(height: 20),
                  _buildAutoRefreshCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // .dash-header style appbar
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: _bg,
      elevation: 0,
      toolbarHeight: 56,
      title: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _green.withOpacity(0.12), borderRadius: BorderRadius.circular(11),
          ),
          child: const Center(child: Text('🌿', style: TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 10),
        const Text('Serre',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _text, letterSpacing: -0.4)),
        if (_isLoading) ...[
          const SizedBox(width: 10),
          SizedBox(width: 12, height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: _green.withOpacity(0.6))),
        ],
      ]),
      actions: [
        // Alert .icon-btn
        _buildAlertBtn(),
        // Refresh .icon-btn
        Container(
          margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Text('↻', style: TextStyle(color: _text2, fontSize: 16)),
            onPressed: _isLoading ? null : _runMode1,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.white.withOpacity(0.07)),
      ),
    );
  }

  Widget _buildAlertBtn() {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 10, bottom: 10),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _alertCount > 0 ? _amber.withOpacity(0.12) : _surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Text(_alertCount > 0 ? '🔔' : '🔔',
                style: TextStyle(fontSize: 15, color: _alertCount > 0 ? _amber : _text3)),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AlertsPage()))
                .then((_) => setState(() {})),
          ),
        ),
        if (_alertCount > 0) Positioned(
          top: -3, right: -3,
          child: Container(
            width: 15, height: 15,
            decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
            child: Center(
              child: Text(_alertCount > 9 ? '9+' : '$_alertCount',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ]),
    );
  }

  // .update-row
  Widget _buildUpdateRow() {
    return Row(children: [
      AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) => Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: _connected ? _green : _text3,
            shape: BoxShape.circle,
            boxShadow: _connected ? [BoxShadow(
              color: _green.withOpacity(0.4 * _pulseAnim.value),
              blurRadius: 6, spreadRadius: 1,
            )] : null,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        _connected ? 'Mis à jour à $_lastUpdate' : 'Connexion en cours...',
        style: const TextStyle(color: _text3, fontSize: 11),
      ),
      const Spacer(),
      if (_alertCount > 0)
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AlertsPage()))
              .then((_) => setState(() {})),
          child: Container(
            // .alert-pill
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _red.withOpacity(0.22)),
            ),
            child: Text(
              '$_alertCount alerte${_alertCount > 1 ? 's' : ''}',
              style: const TextStyle(color: _red, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ),
    ]);
  }

  // .section-title + .sensors-grid
  Widget _buildSensorsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Capteurs'),
      const SizedBox(height: 10),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
        children: [
          SensorCard(
            title: 'Température',
            value: '${_data.temperature.toStringAsFixed(1)}°C',
            icon: _data.temperature < 15 ? Icons.ac_unit_rounded : Icons.thermostat_rounded,
            color: _tempColor,
            subtitle: _data.temperature > 35 ? 'Élevée' : _data.temperature < 15 ? 'Basse' : 'Normale',
          ),
          SensorCard(
            title: 'Humidité',
            value: '${_data.humidite.toStringAsFixed(0)}%',
            icon: Icons.water_drop_rounded,
            color: _blue,
            subtitle: _data.humidite > 80 ? 'Élevée' : 'Normale',
          ),
          SensorCard(
            title: 'Réservoir',
            value: '${_data.niveauEau.toStringAsFixed(0)}%',
            icon: Icons.water_rounded,
            color: _waterColor,
            subtitle: _data.niveauEau < 20 ? 'Faible' : _data.niveauEau < 50 ? 'Moyen' : 'Suffisant',
          ),
          _buildTimerCard(),
        ],
      ),
    ]);
  }

  // Timer card (.sc-surface style)
  Widget _buildTimerCard() {
    final mins = _secondsUntilNext ~/ 60;
    final secs = _secondsUntilNext % 60;
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('⏱️', style: TextStyle(fontSize: 14)),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '${mins.toString().padLeft(2,'0')}:${secs.toString().padLeft(2,'0')}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                color: _text2, height: 1, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          const Text('Prochain refresh', style: TextStyle(fontSize: 11, color: _text3)),
        ]),
      ]),
    );
  }

  // .section-title + .actuators-list
  Widget _buildActuatorsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _sectionTitle('Automatismes'),
        const Spacer(),
        if (_data.fanOn || _data.heaterOn || _data.pumpOn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.10), borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('En cours',
                style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
      ]),
      const SizedBox(height: 10),
      ActuatorTile(title: 'Ventilateur', autoReason: 'Température élevée',
          icon: Icons.air_rounded, value: _data.fanOn, activeColor: _green),
      ActuatorTile(title: 'Chauffage', autoReason: 'En veille',
          icon: Icons.local_fire_department_rounded, value: _data.heaterOn, activeColor: _amber),
      ActuatorTile(title: 'Pompe à eau', autoReason: 'Réservoir faible',
          icon: Icons.water_damage_rounded, value: _data.pumpOn, activeColor: _blue),
    ]);
  }

  // .section-title + .manual-btns
  Widget _buildManualSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Lecture manuelle'),
      const SizedBox(height: 10),
      _manualBtn(
        isLoading: _loadingRequeteEau,
        emoji: '🪣',
        title: 'Vérifier le niveau d\'eau',
        currentVal: '${_data.niveauEau.toStringAsFixed(0)}%',
        color: _blue,
        onTap: _demandeNiveauEau,
      ),
      const SizedBox(height: 8),
      _manualBtn(
        isLoading: _loadingRequeteTh,
        emoji: '🌡️',
        title: 'Vérifier temp. & humidité',
        currentVal: '${_data.temperature.toStringAsFixed(1)}°C · ${_data.humidite.toStringAsFixed(0)}%',
        color: _amber,
        onTap: _demandeTemperatureHumidite,
      ),
    ]);
  }

  // .man-btn
  Widget _manualBtn({
    required bool isLoading,
    required String emoji,
    required String title,
    required String currentVal,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLoading ? color.withOpacity(0.08) : _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLoading ? color.withOpacity(0.22) : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Row(children: [
          Container(
            // .man-icon
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? Padding(padding: const EdgeInsets.all(11),
                    child: CircularProgressIndicator(strokeWidth: 2, color: color))
                : Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              isLoading ? 'Mise à jour...' : currentVal,
              style: TextStyle(color: isLoading ? color : _text2, fontSize: 11),
            ),
          ])),
          Text('›', style: TextStyle(color: _text3, fontSize: 18, fontWeight: FontWeight.w400)),
        ]),
      ),
    );
  }

  // .refresh-card
  Widget _buildAutoRefreshCard() {
    final mins = _secondsUntilNext ~/ 60;
    final secs = _secondsUntilNext % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        const Text('⏱️', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Mise à jour automatique dans ${mins.toString().padLeft(2,'0')}:${secs.toString().padLeft(2,'0')}',
            style: const TextStyle(color: _text3, fontSize: 11),
          ),
        ),
        GestureDetector(
          onTap: _isLoading ? null : _runMode1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _green.withOpacity(0.20)),
            ),
            child: const Text('Actualiser',
                style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  // .section-title
  Widget _sectionTitle(String text) {
    return Text(text.toUpperCase(),
        style: const TextStyle(color: _text2, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5));
  }
}