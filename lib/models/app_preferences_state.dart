class AppPreferencesState {
  final Map<String, int> appLimits; // packageName -> seconds

  AppPreferencesState({this.appLimits = const {}});

  AppPreferencesState copyWith({Map<String, int>? appLimits}) {
    return AppPreferencesState(appLimits: appLimits ?? this.appLimits);
  }
}
