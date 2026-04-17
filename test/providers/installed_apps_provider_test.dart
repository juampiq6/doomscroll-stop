import 'package:doomscroll_stop/models/app_info.dart';
import 'package:doomscroll_stop/providers/installed_apps_provider.dart';
import 'package:doomscroll_stop/service_locator.dart';
import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMethodChannelService extends Mock
    implements MethodChannelServiceInterface {}

void main() {
  late MockMethodChannelService mockService;

  setUp(() {
    mockService = MockMethodChannelService();
    getIt.registerLazySingleton<MethodChannelServiceInterface>(
      () => mockService,
    );
  });

  tearDown(() {
    getIt.reset();
  });

  ProviderContainer makeContainer() => ProviderContainer();

  group('InstalledAppsProvider', () {
    test('returns empty list when no apps installed', () async {
      when(
        () => mockService.getInstalledApps(includeSystemApps: false),
      ).thenAnswer((_) async => []);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(installedAppsProvider.future);

      expect(state, isEmpty);
      verify(
        () => mockService.getInstalledApps(includeSystemApps: false),
      ).called(1);
    });

    test('returns mapped AppInfo list from service data', () async {
      final rawApps = [
        {
          'appName': 'Twitter',
          'packageName': 'com.twitter.android',
          'icon': null,
        },
        {
          'appName': 'Instagram',
          'packageName': 'com.instagram.android',
          'icon': null,
        },
      ];

      when(
        () => mockService.getInstalledApps(includeSystemApps: false),
      ).thenAnswer((_) async => rawApps);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(installedAppsProvider.future);

      expect(state.length, 2);
      expect(state[0].appName, 'Twitter');
      expect(state[0].packageName, 'com.twitter.android');
      expect(state[1].appName, 'Instagram');
      expect(state[1].packageName, 'com.instagram.android');
    });

    test('emits error state when service throws', () async {
      when(
        () => mockService.getInstalledApps(includeSystemApps: false),
      ).thenThrow((_) => Exception('channel error'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(installedAppsProvider.future);

      final state = container.read(installedAppsProvider);
      expect(state, isA<AsyncError>());
    });
  }, skip: true);
}
