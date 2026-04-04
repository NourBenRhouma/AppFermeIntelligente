import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class UbidotsService {
  static const String token   = 'BBUS-k4uhWKEoyL0KGWpRB5atTXl7rIl9Pm';
  static const String baseUrl = 'https://industrial.api.ubidots.com/api/v1.6';
  static const String devLabel = 'esp32-dev';
  static const String camLabel = 'esp32-cam';

  static Map<String, String> get _headers => {
    'X-Auth-Token': token,
    'Content-Type': 'application/json',
  };

  // ═══════════════════════════════════════════════════════════════
  //  PRIMITIVES HTTP
  // ═══════════════════════════════════════════════════════════════

  static Future<double> _fetchValue(String device, String variable) async {
    final url = Uri.parse('$baseUrl/devices/$device/$variable/lv');
    try {
      final res = await http.get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return double.tryParse(res.body.trim()) ?? 0.0;
    } catch (e) { print('[$device/$variable] fetch: $e'); }
    return 0.0;
  }

  static Future<bool> _sendValue(String device, String variable, num value) async {
    final url  = Uri.parse('$baseUrl/devices/$device/?token=$token');
    final body = jsonEncode({variable: {'value': value}});
    try {
      final res = await http.post(url,
          headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10));
      print('[$device/$variable] → $value | ${res.statusCode}');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) { print('[$device/$variable] send: $e'); return false; }
  }

  // ═══════════════════════════════════════════════════════════════
  //  ESP32-DEV
  // ═══════════════════════════════════════════════════════════════

  // ── MODE 1 — PÉRIODIQUE : Lit TOUTES les variables DEV ─────────
  static Future<DevData> fetchDevData() async {
    final r = await Future.wait([
      _fetchValue(devLabel, 'temperature'),      // [0]
      _fetchValue(devLabel, 'humidite'),          // [1]
      _fetchValue(devLabel, 'niveau_eau'),        // [2]
      _fetchValue(devLabel, 'fan'),               // [3]
      _fetchValue(devLabel, 'heater'),            // [4]
      _fetchValue(devLabel, 'pump'),              // [5]
      _fetchValue(devLabel, 'alerte_chaud'),      // [6]
      _fetchValue(devLabel, 'alerte_niveau'),     // [7]
      _fetchValue(devLabel, 'switch_requete'),    // [8]
      _fetchValue(devLabel, 'switch_requete_th'), // [9]
    ]);
    return DevData(
      temperature:     r[0],
      humidite:        r[1],
      niveauEau:       r[2],
      fanOn:           r[3] >= 0.5,
      heaterOn:        r[4] >= 0.5,
      pumpOn:          r[5] >= 0.5,
      alerteChaud:     r[6] >= 0.5,
      alerteNiveau:    r[7] >= 0.5,
      switchRequete:   r[8] >= 0.5,
      switchRequeteTh: r[9] >= 0.5,
      connected:       true,
    );
  }

  // ── MODE 2a — DEMANDE : Lit SEULEMENT niveau_eau ──────────────
  // Envoie switch_requete=1 → ESP32 publie niveau_eau → on lit
  static Future<DevData> fetchNiveauEauOnly(DevData current) async {
    // 1. Envoyer la demande
    await _sendValue(devLabel, 'switch_requete', 1);
    await Future.delayed(const Duration(seconds: 2));
    await _sendValue(devLabel, 'switch_requete', 0);
    await Future.delayed(const Duration(seconds: 1));

    // 2. Lire SEULEMENT niveau_eau
    final niveauEau = await _fetchValue(devLabel, 'niveau_eau');

    // 3. Retourner les données actuelles avec seulement niveau_eau mis à jour
    return DevData(
      temperature:     current.temperature,
      humidite:        current.humidite,
      niveauEau:       niveauEau,           // ← seule valeur mise à jour
      fanOn:           current.fanOn,
      heaterOn:        current.heaterOn,
      pumpOn:          current.pumpOn,
      alerteChaud:     current.alerteChaud,
      alerteNiveau:    current.alerteNiveau,
      switchRequete:   false,
      switchRequeteTh: current.switchRequeteTh,
      connected:       true,
    );
  }

  // ── MODE 2b — DEMANDE : Lit SEULEMENT temperature + humidite ──
  // Envoie switch_requete_th=1 → ESP32 publie temp+hum → on lit
  static Future<DevData> fetchTempHumOnly(DevData current) async {
    // 1. Envoyer la demande
    await _sendValue(devLabel, 'switch_requete_th', 1);
    await Future.delayed(const Duration(seconds: 2));
    await _sendValue(devLabel, 'switch_requete_th', 0);
    await Future.delayed(const Duration(seconds: 1));

    // 2. Lire SEULEMENT temperature et humidite
    final results = await Future.wait([
      _fetchValue(devLabel, 'temperature'),
      _fetchValue(devLabel, 'humidite'),
    ]);

    // 3. Retourner les données actuelles avec seulement temp+hum mis à jour
    return DevData(
      temperature:     results[0],     // ← mis à jour
      humidite:        results[1],     // ← mis à jour
      niveauEau:       current.niveauEau,
      fanOn:           current.fanOn,
      heaterOn:        current.heaterOn,
      pumpOn:          current.pumpOn,
      alerteChaud:     current.alerteChaud,
      alerteNiveau:    current.alerteNiveau,
      switchRequete:   current.switchRequete,
      switchRequeteTh: false,
      connected:       true,
    );
  }

  // ── MODE 3 — ALERTE : Calcul seuils + envoi actionneurs ────────
  static Future<DevData> applyAlertsAndSendDev({
    required DevData raw,
    required Map<String, bool> overrideOff,
  }) async {
    final fanShouldOn    = raw.temperature > 35.0 || raw.humidite > 90.0;
    final heaterShouldOn = raw.temperature < 5.0;
    final pumpShouldOn   = raw.niveauEau   < 20.0;
    final alerteChaud    = raw.temperature > 35.0;
    final alerteNiveau   = raw.niveauEau   < 20.0;

    final fanOn    = overrideOff['fan']!    ? false : fanShouldOn;
    final heaterOn = overrideOff['heater']! ? false : heaterShouldOn;
    final pumpOn   = overrideOff['pump']!   ? false : pumpShouldOn;

    // Envoi SEULEMENT si changement d'état
    if (fanOn    != raw.fanOn)    { await _sendValue(devLabel, 'fan',    fanOn    ? 1 : 0); await _delay(); }
    if (heaterOn != raw.heaterOn) { await _sendValue(devLabel, 'heater', heaterOn ? 1 : 0); await _delay(); }
    if (pumpOn   != raw.pumpOn)   { await _sendValue(devLabel, 'pump',   pumpOn   ? 1 : 0); await _delay(); }

    if (alerteChaud  != raw.alerteChaud)  { await _sendValue(devLabel, 'alerte_chaud',  alerteChaud  ? 1 : 0); await _delay(); }
    if (alerteNiveau != raw.alerteNiveau) { await _sendValue(devLabel, 'alerte_niveau', alerteNiveau ? 1 : 0); await _delay(); }

    return DevData(
      temperature:     raw.temperature,
      humidite:        raw.humidite,
      niveauEau:       raw.niveauEau,
      fanOn:           fanOn,
      heaterOn:        heaterOn,
      pumpOn:          pumpOn,
      alerteChaud:     alerteChaud,
      alerteNiveau:    alerteNiveau,
      switchRequete:   raw.switchRequete,
      switchRequeteTh: raw.switchRequeteTh,
      connected:       true,
    );
  }

  // ── Commandes manuelles actionneurs DEV ──────────────────────
  static Future<bool> setFan(int v)    => _sendValue(devLabel, 'fan',    v);
  static Future<bool> setHeater(int v) => _sendValue(devLabel, 'heater', v);
  static Future<bool> setPump(int v)   => _sendValue(devLabel, 'pump',   v);


  static Future<CamData> fetchCamData({bool withPhoto = false}) async {
    final r = await Future.wait([
      _fetchValue(camLabel, 'mouvement'),
      _fetchValue(camLabel, 'stop_alarme'),
      _fetchValue(camLabel, 'demande_photo'),
    ]);

    String? photoUrl;
    if (withPhoto) {
      // Simuler une URL de photo (remplacez par la vraie URL si disponible)
      //tabldel url mta3 ep32cam netsawer tnajm 5ater inti tab3th fehe 3al eail ken tnajm ter5ou urlm t7oto fam w allahou a3lem
      photoUrl = 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch % 999}/320/240';
    }

    return CamData(
      mouvement:    r[0] >= 0.5,
      stopAlarme:   r[1] >= 0.5,
      demandePhoto: r[2] >= 0.5,
      lastPhotoUrl: photoUrl,
      connected:    true,
    );
  }

  static Future<CamData> applyAlertsAndSendCam({
    required CamData raw,
    required bool alarmeOverrideOff,
  }) async {
    if (alarmeOverrideOff && raw.mouvement) {
      await _sendValue(camLabel, 'stop_alarme', 1);
      await _delay();
      await _sendValue(camLabel, 'mouvement', 0);
      await _delay();
    }
    return CamData(
      mouvement:    alarmeOverrideOff ? false : raw.mouvement,
      stopAlarme:   alarmeOverrideOff,
      demandePhoto: raw.demandePhoto,
      lastPhotoUrl: raw.lastPhotoUrl,
      connected:    true,
    );
  }

  static Future<bool> sendDemandePhoto() async {
    final ok = await _sendValue(camLabel, 'demande_photo', 1);
    if (ok) {
      await Future.delayed(const Duration(seconds: 2));
      await _sendValue(camLabel, 'demande_photo', 0);
    }
    return ok;
  }

  static Future<bool> sendStopAlarme() => _sendValue(camLabel, 'stop_alarme', 1);

  static Future<void> _delay([int ms = 400]) =>
      Future.delayed(Duration(milliseconds: ms));
}