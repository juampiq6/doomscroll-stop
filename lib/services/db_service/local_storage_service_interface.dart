abstract interface class LocalStorageInterface {
  Future<void> savePreferences(Map<String, int> appLimits);
  Future<Map<String, int>> getPreferences();
  Future<void> saveJumpThresholdMs(int ms);
  Future<int> getJumpThresholdMs();
}
