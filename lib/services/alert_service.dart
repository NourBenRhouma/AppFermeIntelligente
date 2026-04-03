import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_data.dart';
import '../models/alert_message.dart';

class AlertService {
  static const String _keyTemp     = 'alert_sent_temp';
  static const String _keyTempCold = 'alert_sent_temp_cold';
  static const String _keyHumid   = 'alert_sent_humidity';
  static const String _keyWater   = 'alert_sent_water';
  static const String _keyMotion  = 'alert_sent_motion';

  static const double tempHotThreshold  = 35.0;   // Temp > 35°C → Ventilateur
  static const double tempColdThreshold = 15.0;   // Temp < 15°C → Chauffage
  static const double humidThreshold    = 80.0;   // Humidité > 80% → Ventilation
  static const double waterThreshold    = 20.0;   // Eau < 20% → Pompe
  // motion = true                                 // Mouvement PIR → Buzzer

  static final List<AlertMessage> _history = [];
  static List<AlertMessage> get history => List.unmodifiable(_history);

  static Future<void> checkAndNotify(SensorData data) async {
    final prefs = await SharedPreferences.getInstance();

    // 🌡️ Temp > 35°C → Ventilateur automatiquement activé
    await _handle(
      prefs:     prefs,
      key:       _keyTemp,
      triggered: data.temperature > tempHotThreshold,
      type:      'temp',
      message:   '🌡️ Température élevée : ${data.temperature.toStringAsFixed(1)}°C '
                 '(seuil ${tempHotThreshold.toInt()}°C) — Ventilateur activé automatiquement',
    );

    // 🥶 Temp < 15°C → Chauffage automatiquement activé
    await _handle(
      prefs:     prefs,
      key:       _keyTempCold,
      triggered: data.temperature < tempColdThreshold,
      type:      'temp_cold',
      message:   '🥶 Température froide : ${data.temperature.toStringAsFixed(1)}°C '
                 '(seuil ${tempColdThreshold.toInt()}°C) — Chauffage activé automatiquement',
    );

    // 💧 Humidité > 80% → Alerte ventilation
    await _handle(
      prefs:     prefs,
      key:       _keyHumid,
      triggered: data.humidity > humidThreshold,
      type:      'humidity',
      message:   '💧 Humidité élevée : ${data.humidity.toStringAsFixed(0)}% '
                 '(seuil ${humidThreshold.toInt()}%) — Vérifier la ventilation',
    );

    // 🪣 Eau < 20% → Pompe automatiquement activée
    await _handle(
      prefs:     prefs,
      key:       _keyWater,
      triggered: data.waterLevel < waterThreshold,
      type:      'water',
      message:   '🪣 Réservoir bas : ${data.waterLevel.toStringAsFixed(0)}% '
                 '(seuil ${waterThreshold.toInt()}%) — Pompe activée automatiquement',
    );

    // 🚨 Mouvement PIR → Buzzer automatiquement activé
    await _handle(
      prefs:     prefs,
      key:       _keyMotion,
      triggered: data.motion,
      type:      'motion',
      message:   '🚨 Mouvement détecté par capteur PIR — Buzzer activé automatiquement',
    );
  }

  static Future<void> _handle({
    required SharedPreferences prefs,
    required String key,
    required bool triggered,
    required String type,
    required String message,
  }) async {
    final alreadySent = prefs.getBool(key) ?? false;

    if (triggered && !alreadySent) {
      _add(AlertMessage(message: message, timestamp: DateTime.now(), type: type));
      await prefs.setBool(key, true);
    } else if (!triggered && alreadySent) {
      await prefs.setBool(key, false);
      _add(AlertMessage(
        message:   _resolvedMessage(type),
        timestamp: DateTime.now(),
        type:      '${type}_resolved',
      ));
    }
  }

  static void _add(AlertMessage msg) {
    _history.insert(0, msg);
    if (_history.length > 50) _history.removeLast();
  }

  static String _resolvedMessage(String type) {
    switch (type) {
      case 'temp':      return '✅ Température normale — Ventilateur coupé automatiquement';
      case 'temp_cold': return '✅ Température normale — Chauffage coupé automatiquement';
      case 'humidity':  return '✅ Humidité revenue à la normale';
      case 'water':     return '✅ Réservoir rechargé — Pompe coupée automatiquement';
      case 'motion':    return '✅ Plus de mouvement — Buzzer coupé automatiquement';
      default:          return '✅ Situation normalisée';
    }
  }

  static void clearHistory() => _history.clear();

  static Future<void> resetAllStates() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [_keyTemp, _keyTempCold, _keyHumid, _keyWater, _keyMotion]) {
      await prefs.setBool(key, false);
    }
  }
}