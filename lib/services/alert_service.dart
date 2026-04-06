import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_data.dart';

class AlertService {
  static const _kTempHot  = 'alert_temp_hot';
  static const _kTempCold = 'alert_temp_cold';
  static const _kHumid    = 'alert_humidity';
  static const _kWater    = 'alert_water';
  static const _kMouv     = 'alert_mouvement';

  // Seuils cohérents avec ubidots_service.dart
  static const double tempHotThreshold  = 35.0;
  static const double tempColdThreshold = 5.0;
  static const double humidThreshold    = 90.0;
  // niveauEau = distance capteur : > 20 = réservoir bas = alerte
  static const double waterThreshold    = 20.0;

  static final List<AlertMessage> _history = [];
  static List<AlertMessage> get history => List.unmodifiable(_history);

  static final StreamController<AlertMessage> _streamCtrl =
      StreamController<AlertMessage>.broadcast();
  static Stream<AlertMessage> get alertStream => _streamCtrl.stream;

  static Future<void> checkDev(DevData data) async {
    final prefs = await SharedPreferences.getInstance();

    await _handle(
      prefs: prefs, key: _kTempHot,
      triggered: data.temperature > tempHotThreshold,
      type: 'temp_hot', device: 'dev',
      message:  '🌡️ Temp. élevée : ${data.temperature.toStringAsFixed(1)}°C → Ventilateur activé',
      resolved: '✅ Température normale — Ventilateur coupé',
    );

    await _handle(
      prefs: prefs, key: _kTempCold,
      triggered: data.temperature < tempColdThreshold,
      type: 'temp_cold', device: 'dev',
      message:  '🥶 Temp. froide : ${data.temperature.toStringAsFixed(1)}°C → Chauffage activé',
      resolved: '✅ Température normale — Chauffage coupé',
    );

    await _handle(
      prefs: prefs, key: _kHumid,
      triggered: data.humidite > humidThreshold,
      type: 'humidity', device: 'dev',
      message:  '💧 Humidité élevée : ${data.humidite.toStringAsFixed(0)}% → Vérifier ventilation',
      resolved: '✅ Humidité revenue à la normale',
    );

    await _handle(
      prefs: prefs, key: _kWater,
      // niveauEau > 20 = capteur loin = eau basse = alerte
      triggered: data.niveauEau > waterThreshold,
      type: 'water', device: 'dev',
      message:  '🪣 Réservoir bas : ${(100 - data.niveauEau).toStringAsFixed(0)} cm restants → Pompe activée',
      resolved: '✅ Réservoir rempli — Pompe coupée',
    );
  }

  static Future<void> checkCam(CamData data) async {
    final prefs = await SharedPreferences.getInstance();
    await _handle(
      prefs: prefs, key: _kMouv,
      triggered: data.mouvement,
      type: 'mouvement', device: 'cam',
      message:  '🚨 Mouvement détecté — Alarme activée',
      resolved: '✅ Plus de mouvement — Alarme coupée',
    );
  }
  static final Map<String, bool> _activeStates = {};

  static Future<void> _handle({
    required SharedPreferences prefs,
    required String key,
    required bool triggered,
    required String type,
    required String device,
    required String message,
    required String resolved,
  }) async {
     final already = _activeStates[key] ?? false;
    if (triggered && !already) {
      _activeStates[key] = true;
      final msg = AlertMessage(
        message: message,
        timestamp: DateTime.now(),
        type: type,
        device: device,
      );
      _add(msg);
      _streamCtrl.add(msg);
      await prefs.setBool(key, true);
    } else if (!triggered && already) {
      _activeStates[key] = false;
      await prefs.setBool(key, false);
      final msg = AlertMessage(
        message: resolved,
        timestamp: DateTime.now(),
        type: '${type}_resolved',
        device: device,
      );
      _add(msg);
      _streamCtrl.add(msg);
    }
  }

  static void _add(AlertMessage msg) {
    _history.insert(0, msg);
    if (_history.length > 100) _history.removeLast();
  }

  static void clearHistory() => _history.clear();

  static Future<void> resetAllStates() async {
    _activeStates.clear(); // ✅ vider le cache
    final prefs = await SharedPreferences.getInstance();
    for (final k in [_kTempHot, _kTempCold, _kHumid, _kWater, _kMouv]) {
      await prefs.setBool(k, false);
    }
  }

  static List<AlertMessage> get devAlerts =>
      _history.where((a) => a.device == 'dev').toList();
  static List<AlertMessage> get camAlerts =>
      _history.where((a) => a.device == 'cam').toList();

  static void dispose() => _streamCtrl.close();
}