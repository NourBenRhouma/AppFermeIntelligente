class SensorData {
  final double temperature;
  final double humidity;
  final bool   motion;
  final double waterLevel;

  // États actionneurs (lus depuis Ubidots)
  final bool fanOn;
  final bool pumpOn;
  final bool heaterOn;
  final bool buzzerOn;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.motion,
    required this.waterLevel,
    this.fanOn    = false,
    this.pumpOn   = false,
    this.heaterOn = false,
    this.buzzerOn = false,
  });

  factory SensorData.fake() {
    final now   = DateTime.now();
    final temp  = 22.0 + (now.second % 10).toDouble();
    final water = 30.0 + (now.second % 50).toDouble();
    final hum   = 45.0 + (now.second % 25).toDouble();
    final motion = now.second % 6 < 3;

    return SensorData(
      temperature: temp,
      humidity:    hum,
      motion:      motion,
      waterLevel:  water,
      fanOn:       temp > 35,
      heaterOn:    temp < 15,
      pumpOn:      water < 20,
      buzzerOn:    motion,
    );
  }
}