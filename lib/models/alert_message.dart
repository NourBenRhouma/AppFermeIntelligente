class AlertMessage {
  final String message;
  final DateTime timestamp;
  final String type;
  // type: 'temp' | 'temp_cold' | 'humidity' | 'water' | 'motion'
  AlertMessage({
    required this.message,
    required this.timestamp,
    required this.type,
  });

  String get icon {
    switch (type) {
      case 'temp':           return '🌡️';
      case 'temp_cold':      return '🥶';
      case 'humidity':       return '💧';
      case 'water':          return '🪣';
      case 'motion':         return '🚨';
      default:
        if (type.endsWith('_resolved')) return '✅';
        return '⚠️';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60)  return 'il y a ${diff.inSeconds}s';
    if (diff.inMinutes < 60)  return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24)    return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}