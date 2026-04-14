abstract interface class LocalDbServiceInterface {
  Future<void> save();
  Future<void> delete();
  Future<void> update();
  Future<void> get();
}
