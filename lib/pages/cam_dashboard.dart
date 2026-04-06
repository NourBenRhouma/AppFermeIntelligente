import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/ubidots_service.dart';
import '../services/alert_service.dart';
import '../widgets/actuator_tile.dart';
import 'alerts_page.dart';

const Color _bg = Color(0xFF0A0B0F);
const Color _surface = Color(0xFF13151C);
const Color _surface2 = Color(0xFF1C1F2B);
const Color _amber = Color(0xFFFFB340);
const Color _red = Color(0xFFFF5C5C);
const Color _green = Color(0xFF3DDC84);
const Color _text = Color(0xFFF0F2FF);
const Color _text2 = Color(0xFF8B90A8);
const Color _text3 = Color(0xFF4A4F68);

class CamDashboard extends StatefulWidget {
  const CamDashboard({super.key});
  @override
  State<CamDashboard> createState() => _CamDashboardState();
}

class _CamDashboardState extends State<CamDashboard>
    with TickerProviderStateMixin {
  CamData _data = CamData.zero();
  String? _savedPhotoUrl;
  bool _isLoading = false;
  bool _loadingPhoto = false;
  bool _loadingStop = false;
  String _lastUpdate = '';
  bool _alarmeOverrideOff = false;

  static const Duration _pollInterval = Duration(seconds: 2);
  Timer? _pollTimer;
  bool _isFetching = false;

  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _motionCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _motionAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _motionCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _motionAnim = CurvedAnimation(parent: _motionCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _motionCtrl.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _runPolling();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _runPolling());
  }

  Future<void> _runPolling() async {
    if (!mounted || _isFetching) return;
    _isFetching = true;

    if (_lastUpdate.isEmpty && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Lire les données de base sans photo
      final raw = await UbidotsService.fetchCamData(withPhoto: false);

      // Si mouvement détecté, récupérer aussi la photo
      CamData finalRaw = raw;
      if (raw.mouvement) {
        print('📸 Mouvement détecté, récupération de la photo...');
        finalRaw = await UbidotsService.fetchCamData(withPhoto: true);
      }

      // ✅ FIX PRINCIPAL : détecter changement d'URL photo
      final newPhotoUrl = finalRaw.lastPhotoUrl;
      final photoChanged = newPhotoUrl != null &&
          newPhotoUrl.isNotEmpty &&
          newPhotoUrl != _savedPhotoUrl;

      final changed = finalRaw.mouvement != _data.mouvement ||
          finalRaw.stopAlarme != _data.stopAlarme ||
          finalRaw.connected != _data.connected ||
          photoChanged; // ✅ Ajouté ici

      if (!finalRaw.mouvement) _alarmeOverrideOff = false;

      final data = await UbidotsService.applyAlertsAndSendCam(
        raw: finalRaw,
        alarmeOverrideOff: _alarmeOverrideOff,
      );
      await AlertService.checkCam(data);

      // ✅ FIX : Toujours sauvegarder la nouvelle URL si elle existe
      if (photoChanged) {
        _savedPhotoUrl = newPhotoUrl;
        print('🖼️ Nouvelle photo sauvegardée: $_savedPhotoUrl');
      }

      final finalData = CamData(
        mouvement: data.mouvement,
        stopAlarme: data.stopAlarme,
        demandePhoto: data.demandePhoto,
        lastPhotoUrl: _savedPhotoUrl,
        connected: data.connected,
      );

      if (mounted && (changed || _lastUpdate.isEmpty)) {
        setState(() {
          _data = finalData;
          _lastUpdate = _now();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('_runPolling erreur: $e');
      if (mounted) setState(() => _isLoading = false);
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _manualRefresh() async {
    if (_isFetching) return;
    await _runPolling();
  }

  Future<void> _demandePhoto() async {
    if (_loadingPhoto) return;
    setState(() => _loadingPhoto = true);
    try {
      await UbidotsService.sendDemandePhoto();

      await Future.delayed(const Duration(seconds: 15));

      final raw = await UbidotsService.fetchCamData(withPhoto: true);

      if (!raw.mouvement) _alarmeOverrideOff = false;

      final data = await UbidotsService.applyAlertsAndSendCam(
        raw: raw,
        alarmeOverrideOff: _alarmeOverrideOff,
      );
      await AlertService.checkCam(data);

      // ✅ FIX : Toujours mettre à jour après demande manuelle
      final newUrl = raw.lastPhotoUrl;
      if (newUrl != null && newUrl.isNotEmpty) {
        _savedPhotoUrl = newUrl;
      }

      if (mounted) {
        setState(() {
          _data = CamData(
            mouvement: data.mouvement,
            stopAlarme: data.stopAlarme,
            demandePhoto: data.demandePhoto,
            lastPhotoUrl: _savedPhotoUrl,
            connected: data.connected,
          );
          _lastUpdate = _now();
        });
      }
    } catch (e) {
      print('_demandePhoto erreur: $e');
    } finally {
      if (mounted) setState(() => _loadingPhoto = false);
    }
  }

  Future<void> _stopAlarme() async {
    if (_loadingStop) return;
    setState(() => _loadingStop = true);
    try {
      _alarmeOverrideOff = true;
      await _runPolling();
    } finally {
      if (mounted) setState(() => _loadingStop = false);
    }
  }

  String _now() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  int get _alertCount => AlertService.camAlerts.length;
  bool get _connected => _lastUpdate.isNotEmpty;
  bool get _alarmeActive => _data.mouvement && !_alarmeOverrideOff;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        onRefresh: _manualRefresh,
        color: _amber,
        backgroundColor: _surface,
        child: CustomScrollView(slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildUpdateRow(),
                    const SizedBox(height: 20),
                    _buildDetectionSection(),
                    const SizedBox(height: 20),
                    _buildPhotoSection(),
                    if (_alarmeActive) ...[
                      const SizedBox(height: 20),
                      _buildAlarmSection(),
                    ],
                    const SizedBox(height: 20),
                    _buildLiveCard(),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: _bg,
      elevation: 0,
      toolbarHeight: 56,
      title: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _amber.withOpacity(0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child:
              const Center(child: Text('📷', style: TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 10),
        const Text('Caméra',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _text,
                letterSpacing: -0.4)),
        if (_isLoading) ...[
          const SizedBox(width: 10),
          SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _amber.withOpacity(0.6))),
        ],
      ]),
      actions: [
        _buildAlertBtn(),
        Container(
          margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Text('↻', style: TextStyle(color: _text2, fontSize: 16)),
            onPressed: _isLoading ? null : _manualRefresh,
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _alertCount > 0 ? _amber.withOpacity(0.12) : _surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Text('🔔',
                style: TextStyle(
                    fontSize: 15, color: _alertCount > 0 ? _amber : _text3)),
            onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AlertsPage()))
                .then((_) => setState(() {})),
          ),
        ),
        if (_alertCount > 0)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(color: _amber, shape: BoxShape.circle),
              child: Center(
                  child: Text(_alertCount > 9 ? '9+' : '$_alertCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800))),
            ),
          ),
      ]),
    );
  }

  Widget _buildUpdateRow() {
    return Row(children: [
      AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) => Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: _connected ? _green : _text3,
            shape: BoxShape.circle,
            boxShadow: _connected
                ? [
                    BoxShadow(
                        color: _green.withOpacity(0.4 * _pulseAnim.value),
                        blurRadius: 6,
                        spreadRadius: 1)
                  ]
                : null,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _amber.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _amber.withOpacity(0.20)),
            ),
            child: Text('$_alertCount alerte${_alertCount > 1 ? 's' : ''}',
                style: const TextStyle(
                    color: _amber, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ),
    ]);
  }

  Widget _buildDetectionSection() {
    final detected = _data.mouvement;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Détection'),
      const SizedBox(height: 10),
      AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: detected
                ? [const Color(0xFF200A0A), _surface]
                : [const Color(0xFF0A1A0D), _surface],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: detected ? _red.withOpacity(0.35) : _green.withOpacity(0.18),
            width: detected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          AnimatedBuilder(
            animation: detected ? _motionAnim : _pulseAnim,
            builder: (_, __) {
              final scale = detected ? (1.0 + 0.08 * _motionAnim.value) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: detected
                        ? _red.withOpacity(0.15)
                        : _green.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(detected ? '🚨' : '🛡️',
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(detected ? 'Mouvement détecté' : 'Zone sécurisée',
                    style: TextStyle(
                        color: detected ? _red : _green,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2)),
                const SizedBox(height: 3),
                Text(
                  detected
                      ? 'Quelqu\'un a été détecté dans la zone surveillée'
                      : 'Aucun mouvement — surveillance active',
                  style: TextStyle(color: _text3, fontSize: 11, height: 1.4),
                ),
                if (detected) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _red.withOpacity(0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      _red.withOpacity(0.6 * _pulseAnim.value),
                                  blurRadius: 4)
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('Alarme active',
                          style: TextStyle(
                              color: _red,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ])),
        ]),
      ),
    ]);
  }

  Widget _buildPhotoSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Photo'),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _data.lastPhotoUrl != null
                ? Image.network(
                    _data.lastPhotoUrl!,
                    // ✅ ValueKey force le rechargement quand l'URL change
                    key: ValueKey(_data.lastPhotoUrl),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 160,
                        color: _surface2,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _amber,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Image erreur: $error');
                      return _photoPlaceholder();
                    },
                  )
                : _photoPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: _loadingPhoto ? null : _demandePhoto,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _loadingPhoto
                      ? _amber.withOpacity(0.15)
                      : _amber.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _amber.withOpacity(_loadingPhoto ? 0.40 : 0.25)),
                ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _loadingPhoto
                      ? SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _amber))
                      : const Text('📸', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Text(
                    _loadingPhoto ? 'Capture en cours...' : 'Prendre une photo',
                    style: const TextStyle(
                        color: _amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _photoPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: _surface2,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📷', style: TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        Text('Appuyez pour prendre une photo',
            style: TextStyle(color: _text3, fontSize: 11)),
      ]),
    );
  }

  Widget _buildAlarmSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Alarme'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _red.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _red.withOpacity(0.28), width: 1.5),
        ),
        child: Column(children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: Text('🔊', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Alarme sonore active',
                      style: TextStyle(
                          color: _text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Déclenchée par détection de mouvement',
                      style: TextStyle(color: _text3, fontSize: 11)),
                ])),
          ]),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _loadingStop ? null : _stopAlarme,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _red.withOpacity(0.35)),
              ),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _loadingStop
                    ? SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _red))
                    : const Text('⏹', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  _loadingStop ? 'Arrêt en cours...' : 'Arrêter l\'alarme',
                  style: const TextStyle(
                      color: _red, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildLiveCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _connected ? _green : _red,
              shape: BoxShape.circle,
              boxShadow: _connected
                  ? [
                      BoxShadow(
                          color: _green.withOpacity(0.5 * _pulseAnim.value),
                          blurRadius: 5)
                    ]
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _connected
                ? 'Temps réel · actualisation toutes les ${_pollInterval.inSeconds}s'
                : 'Connexion en cours...',
            style: const TextStyle(color: _text3, fontSize: 11),
          ),
        ),
        GestureDetector(
          onTap: _isLoading ? null : _manualRefresh,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _amber.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _amber.withOpacity(0.20)),
            ),
            child: const Text('Actualiser',
                style: TextStyle(
                    color: _amber, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text.toUpperCase(),
        style: const TextStyle(
            color: _text2,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5));
  }
}
