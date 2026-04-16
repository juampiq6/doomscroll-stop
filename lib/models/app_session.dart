class AppSession {
  final int startTime;
  final int stopTime;
  final bool hasInteraction;

  AppSession({
    required this.startTime,
    required this.stopTime,
    required this.hasInteraction,
  });

  factory AppSession.fromMap(Map<String, dynamic> map) {
    return AppSession(
      startTime: map['startTime'] as int,
      stopTime: map['stopTime'] as int,
      hasInteraction: map['hasInteraction'] as bool,
    );
  }

  int get durationMs => stopTime - startTime;
}

class AppUsage {
  final String packageName;
  final List<AppSession> sessions;

  AppUsage({
    required this.packageName,
    required this.sessions,
  });

  factory AppUsage.fromSessions(String packageName, List<dynamic> sessionList) {
    return AppUsage(
      packageName: packageName,
      sessions: sessionList
          .map((s) => AppSession.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }

  int get totalTimeMs => sessions.fold(0, (sum, s) => sum + s.durationMs);
  int get totalInteractions => sessions.where((s) => s.hasInteraction).length;
}
