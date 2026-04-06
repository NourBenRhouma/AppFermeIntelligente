import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class UbidotsService {
  static const String token =
      'BBUS-9NZu3KVYg3OVup9XdI9Es392wCiFZl'; // esp32-cam
  static const String tokenCam =
      'BBUS-cXkFLuFylAJAhKxrdsFln5tIzFz79P'; // esp-cam
  static const String baseUrl = 'https://industrial.api.ubidots.com/api/v1.6';
  static const String devLabel = 'esp32-cam';
  static const String camLabel = 'esp-cam';

  // ── Headers séparés ──
  static Map<String, String> get _headers => {
        'X-Auth-Token': token,
        'Content-Type': 'application/json',
      };

  static Map<String, String> get _headersCam => {
        'X-Auth-Token': tokenCam,
        'Content-Type': 'application/json',
      };

  // ═══════════════════════════════════════════════════════════════
  //  PRIMITIVES HTTP — séparées par device
  // ═══════════════════════════════════════════════════════════════

  static Future<double> _fetchValue(String device, String variable) async {
    // ✅ Choisir le bon header selon le device
    final headers = device == camLabel ? _headersCam : _headers;
    final url = Uri.parse('$baseUrl/devices/$device/$variable/lv');
    try {
      final res = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return double.tryParse(res.body.trim()) ?? 0.0;
    } catch (e) {
      print('[$device/$variable] fetch: $e');
    }
    return 0.0;
  }

  static Future<bool> _sendValue(
      String device, String variable, num value) async {
    // ✅ Choisir le bon token selon le device
    final tkn = device == camLabel ? tokenCam : token;
    final url = Uri.parse('$baseUrl/devices/$device/?token=$tkn');
    final body = jsonEncode({
      variable: {'value': value}
    });
    try {
      final res = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10));
      print('[$device/$variable] → $value | ${res.statusCode}');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('[$device/$variable] send: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  ESP32-DEV
  // ═══════════════════════════════════════════════════════════════

  static Future<DevData> fetchDevData() async {
    final r = await Future.wait([
      _fetchValue(devLabel, 'temperature'),
      _fetchValue(devLabel, 'humidite'),
      _fetchValue(devLabel, 'niveau_eau'),
      _fetchValue(devLabel, 'fan'),
      _fetchValue(devLabel, 'heater'),
      _fetchValue(devLabel, 'pump'),
      _fetchValue(devLabel, 'alerte_chaud'),
      _fetchValue(devLabel, 'alerte_niveau'),
      _fetchValue(devLabel, 'switch_requete'),
      _fetchValue(devLabel, 'switch_requete_th'),
    ]);
    return DevData(
      temperature: r[0],
      humidite: r[1],
      niveauEau: r[2],
      fanOn: r[3] >= 0.5,
      heaterOn: r[4] >= 0.5,
      pumpOn: r[5] >= 0.5,
      alerteChaud: r[6] >= 0.5,
      alerteNiveau: r[7] >= 0.5,
      switchRequete: r[8] >= 0.5,
      switchRequeteTh: r[9] >= 0.5,
      connected: true,
    );
  }

  static Future<DevData> fetchNiveauEauOnly(DevData current) async {
    await _sendValue(devLabel, 'switch_requete', 1);
    await Future.delayed(const Duration(seconds: 2));
    await _sendValue(devLabel, 'switch_requete', 0);
    await Future.delayed(const Duration(seconds: 1));
    final niveauEau = await _fetchValue(devLabel, 'niveau_eau');
    return DevData(
      temperature: current.temperature,
      humidite: current.humidite,
      niveauEau: niveauEau,
      fanOn: current.fanOn,
      heaterOn: current.heaterOn,
      pumpOn: current.pumpOn,
      alerteChaud: current.alerteChaud,
      alerteNiveau: current.alerteNiveau,
      switchRequete: false,
      switchRequeteTh: current.switchRequeteTh,
      connected: true,
    );
  }

  static Future<DevData> fetchTempHumOnly(DevData current) async {
    await _sendValue(devLabel, 'switch_requete_th', 1);
    await Future.delayed(const Duration(seconds: 2));
    await _sendValue(devLabel, 'switch_requete_th', 0);
    await Future.delayed(const Duration(seconds: 1));
    final results = await Future.wait([
      _fetchValue(devLabel, 'temperature'),
      _fetchValue(devLabel, 'humidite'),
    ]);
    return DevData(
      temperature: results[0],
      humidite: results[1],
      niveauEau: current.niveauEau,
      fanOn: current.fanOn,
      heaterOn: current.heaterOn,
      pumpOn: current.pumpOn,
      alerteChaud: current.alerteChaud,
      alerteNiveau: current.alerteNiveau,
      switchRequete: current.switchRequete,
      switchRequeteTh: false,
      connected: true,
    );
  }

  static Future<DevData> applyAlertsAndSendDev({
    required DevData raw,
    required Map<String, bool> overrideOff,
  }) async {
    final fanShouldOn = raw.temperature > 35.0 || raw.humidite > 90.0;
    final heaterShouldOn = raw.temperature < 5.0;
    final pumpShouldOn = raw.niveauEau > 80.0;
    final alerteChaud = raw.temperature > 35.0;
    final alerteNiveau = raw.niveauEau < 20.0;

    final fanOn = overrideOff['fan']! ? false : fanShouldOn;
    final heaterOn = overrideOff['heater']! ? false : heaterShouldOn;
    final pumpOn = overrideOff['pump']! ? false : pumpShouldOn;

    if (fanOn != raw.fanOn) {
      await _sendValue(devLabel, 'fan', fanOn ? 1 : 0);
      await _delay();
    }
    if (heaterOn != raw.heaterOn) {
      await _sendValue(devLabel, 'heater', heaterOn ? 1 : 0);
      await _delay();
    }
    if (pumpOn != raw.pumpOn) {
      await _sendValue(devLabel, 'pump', pumpOn ? 1 : 0);
      await _delay();
    }
    if (alerteChaud != raw.alerteChaud) {
      await _sendValue(devLabel, 'alerte_chaud', alerteChaud ? 1 : 0);
      await _delay();
    }
    if (alerteNiveau != raw.alerteNiveau) {
      await _sendValue(devLabel, 'alerte_niveau', alerteNiveau ? 1 : 0);
      await _delay();
    }

    return DevData(
      temperature: raw.temperature,
      humidite: raw.humidite,
      niveauEau: raw.niveauEau,
      fanOn: fanOn,
      heaterOn: heaterOn,
      pumpOn: pumpOn,
      alerteChaud: alerteChaud,
      alerteNiveau: alerteNiveau,
      switchRequete: raw.switchRequete,
      switchRequeteTh: raw.switchRequeteTh,
      connected: true,
    );
  }

  static Future<bool> setFan(int v) => _sendValue(devLabel, 'fan', v);
  static Future<bool> setHeater(int v) => _sendValue(devLabel, 'heater', v);
  static Future<bool> setPump(int v) => _sendValue(devLabel, 'pump', v);

  // ═══════════════════════════════════════════════════════════════
  //  ESP32-CAM
  // ═══════════════════════════════════════════════════════════════

  // ✅ fetchPhotoUrl — utilise tokenCam
  static Future<String?> fetchPhotoUrl() async {
    final url = Uri.parse(
        '$baseUrl/devices/$camLabel/photo_url/?token=$tokenCam' // ✅ tokenCam
        );
    try {
      final res = await http
          .get(url, headers: _headersCam) // ✅ _headersCam
          .timeout(const Duration(seconds: 10));

      print('[fetchPhotoUrl] status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final lastValue = data['last_value'];
        if (lastValue != null) {
          final context = lastValue['context'];
          if (context != null && context['url'] != null) {
            final photoUrl = context['url'] as String;
            print('[fetchPhotoUrl] ✅ URL : $photoUrl');
            return photoUrl;
          }
        }
      }
    } catch (e) {
      print('[fetchPhotoUrl] erreur: $e');
    }
    return null;
  }

  // ✅ fetchCamData — utilise _fetchValue qui choisit automatiquement _headersCam
  static Future<CamData> fetchCamData({bool withPhoto = false}) async {
    final r = await Future.wait([
      _fetchValue(camLabel, 'mouvement'), // ✅ tokenCam auto
      _fetchValue(camLabel, 'stop_alarme'), // ✅ tokenCam auto
      _fetchValue(camLabel, 'demande_photo'), // ✅ tokenCam auto
    ]);

    String? photoUrl;
    if (withPhoto) {
      photoUrl = await fetchPhotoUrl();
      print('[fetchCamData] photoUrl = $photoUrl');
    }

    return CamData(
      mouvement: r[0] >= 0.5,
      stopAlarme: r[1] >= 0.5,
      demandePhoto: r[2] >= 0.5,
      lastPhotoUrl: photoUrl,
      connected: true,
    );
  }

  static Future<CamData> applyAlertsAndSendCam({
    required CamData raw,
    required bool alarmeOverrideOff,
  }) async {
    if (alarmeOverrideOff && raw.mouvement) {
      await _sendValue(camLabel, 'stop_alarme', 1); // ✅ tokenCam auto
      await _delay();
      await _sendValue(camLabel, 'mouvement', 0); // ✅ tokenCam auto
      await _delay();
    }
    return CamData(
      mouvement: alarmeOverrideOff ? false : raw.mouvement,
      stopAlarme: alarmeOverrideOff,
      demandePhoto: raw.demandePhoto,
      lastPhotoUrl: raw.lastPhotoUrl,
      connected: true,
    );
  }

  static Future<bool> sendDemandePhoto() async {
    final ok =
        await _sendValue(camLabel, 'demande_photo', 1); // ✅ tokenCam auto
    if (ok) {
      await Future.delayed(const Duration(seconds: 2));
      await _sendValue(camLabel, 'demande_photo', 0);
    }
    return ok;
  }

  static Future<bool> sendStopAlarme() =>
      _sendValue(camLabel, 'stop_alarme', 1); // ✅ tokenCam auto

  static Future<void> _delay([int ms = 400]) =>
      Future.delayed(Duration(milliseconds: ms));
}
