import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class UbidotsService {
  static const String token       = 'BBUS-k4uhWKEoyL0KGWpRB5atTXl7rIl9Pm';
  static const String deviceLabel = 'smart-farm';
  static const String baseUrl     = 'https://industrial.api.ubidots.com/api/v1.6';

  static Map<String, String> get _headers => {
        'X-Auth-Token': token,
        'Content-Type': 'application/json',
      };

  // ── Lecture d'une variable (dernière valeur) ────────────
  static Future<double> _fetchValue(String variableLabel) async {
    final url = Uri.parse('$baseUrl/devices/$deviceLabel/$variableLabel/lv');
    try {
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return double.tryParse(response.body.trim()) ?? 0.0;
      }
    } catch (e) {
      print('[$variableLabel] Erreur fetch: $e');
    }
    return 0.0;
  }

  // ── Lecture groupée de tous les capteurs ────────────────
  // NE PAS envoyer de commandes ici — le dashboard gère les overrides manuels
  static Future<SensorData> fetchSensorData() async {
    final results = await Future.wait([
      _fetchValue('temperature'), // 0
      _fetchValue('humidity'),    // 1
      _fetchValue('motion'),      // 2
      _fetchValue('water_level'), // 3
      _fetchValue('pump'),        // 4
      _fetchValue('fan'),         // 5
      _fetchValue('heater'),      // 6
      _fetchValue('buzzer'),      // 7
    ]);

    final temp           = results[0];
    final humidity       = results[1];
    final motionVal      = results[2];
    final waterLevel     = results[3];
    final motionDetected = motionVal >= 0.5;

    // Calcul de l'état de chaque actionneur selon les seuils
    // L'envoi réel est délégué au dashboard (après application des overrides manuels)
    return SensorData(
      temperature: temp,
      humidity:    humidity,
      motion:      motionDetected,
      waterLevel:  waterLevel,
      fanOn:    results[5] >= 0.5 || temp > 35.0 || humidity > 80.0,
      heaterOn: results[6] >= 0.5 || temp < 15.0,
      pumpOn:   results[4] >= 0.5 || waterLevel < 20.0,
      buzzerOn: results[7] >= 0.5 || motionDetected,
    );
  }

  // ── Envoi d'une commande vers Ubidots ───────────────────
  static Future<bool> _sendValue(String variable, int value) async {
    final body = jsonEncode({variable: {'value': value}});
    final url  = Uri.parse('$baseUrl/devices/$deviceLabel/?token=$token');
    try {
      final response = await http
          .post(url,
              headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10));
      print('[$variable] → $value | status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('[$variable] Exception: $e');
      return false;
    }
  }

  // ── API publique actionneurs ────────────────────────────
  static Future<bool> setFan(int v)    => _sendValue('fan',    v);
  static Future<bool> setPump(int v)   => _sendValue('pump',   v);
  static Future<bool> setHeater(int v) => _sendValue('heater', v);
  static Future<bool> setBuzzer(int v) => _sendValue('buzzer', v);
  static Future<bool> setMotion(int v) => _sendValue('motion', v);
}