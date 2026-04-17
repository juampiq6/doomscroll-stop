import 'package:doomscroll_stop/providers/app_jump_threshold_provider.dart';
import 'package:doomscroll_stop/providers/app_preferences_provider.dart';
import 'package:doomscroll_stop/providers/doomscroll_background_service_provider.dart';
import 'package:doomscroll_stop/repositories/preferences_repository.dart';
import 'package:doomscroll_stop/service_locator.dart';
import 'package:doomscroll_stop/services/db_service/local_storage_service_interface.dart';
import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPreferencesRepository extends Mock implements PreferencesRepository {}

class MockLocalStorage extends Mock implements LocalStorageInterface {}

class MockMethodChannelService extends Mock
    implements MethodChannelServiceInterface {}

void main() {
  late MockPreferencesRepository mockRepo;
  late MockLocalStorage mockStorage;
  late MockMethodChannelService mockService;

  setUp(() {
    mockRepo = MockPreferencesRepository();
    mockStorage = MockLocalStorage();
    mockService = MockMethodChannelService();

    getIt.registerSingletonAsync<PreferencesRepository>(() async => mockRepo);
    getIt.registerLazySingleton<LocalStorageInterface>(() => mockStorage);
    getIt.registerLazySingleton<MethodChannelServiceInterface>(
      () => mockService,
    );
  });

  tearDown(() {
    getIt.reset();
  });

  ProviderContainer makeContainer() => ProviderContainer();

  group('AppPreferencesProvider - initial state', () {
    test('returns preferences from repository', () async {
      when(
        () => mockRepo.getPreferences(),
      ).thenAnswer((_) async => {'com.example.app': 120});

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(appPreferencesProvider.future);

      expect(state, {'com.example.app': 120});
      verify(() => mockRepo.getPreferences()).called(1);
    });

    test('returns empty map when no preferences saved', () async {
      when(() => mockRepo.getPreferences()).thenAnswer((_) async => {});

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(appPreferencesProvider.future);

      expect(state, isEmpty);
    });

    test('emits error state when repository throws', () async {
      when(
        () => mockRepo.getPreferences(),
      ).thenThrow(Exception('storage error'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(appPreferencesProvider.future)
          .catchError((_) => <String, int>{});

      final state = container.read(appPreferencesProvider);
      expect(state, isA<AsyncError>());
    }, skip: true);
  });

  group('AppPreferencesProvider - updateLimit', () {
    test('adds new app limit to existing preferences', () async {
      when(
        () => mockRepo.getPreferences(),
      ).thenAnswer((_) async => {'com.app.a': 60});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(appPreferencesProvider.future);

      container
          .read(appPreferencesProvider.notifier)
          .updateLimit('com.app.b', 120);

      final state = container.read(appPreferencesProvider).value!;
      expect(state.containsKey('com.app.a'), true);
      expect(state['com.app.a'], equals(60));
      expect(state.containsKey('com.app.b'), true);
      expect(state['com.app.b'], equals(120));
    });

    test('updates existing app limit', () async {
      when(
        () => mockRepo.getPreferences(),
      ).thenAnswer((_) async => {'com.app.a': 60});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(appPreferencesProvider.future);

      container
          .read(appPreferencesProvider.notifier)
          .updateLimit('com.app.a', 180);

      final state = container.read(appPreferencesProvider).value!;
      expect(state['com.app.a'], 180);
    });
  });

  group('AppPreferencesProvider - removeApp', () {
    test('removes app from preferences', () async {
      when(
        () => mockRepo.getPreferences(),
      ).thenAnswer((_) async => {'com.app.a': 60, 'com.app.b': 120});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(appPreferencesProvider.future);

      container.read(appPreferencesProvider.notifier).removeApp('com.app.a');

      final state = container.read(appPreferencesProvider).value!;
      expect(state.containsKey('com.app.a'), false);
    });
  });

  group('AppPreferencesProvider - saveAndApply', () {
    test(
      'saves preferences and restarts service when map is not empty',
      () async {
        when(
          () => mockRepo.getPreferences(),
        ).thenAnswer((_) async => {'com.app.a': 60});
        when(() => mockStorage.savePreferences(any())).thenAnswer((_) async {});
        when(() => mockStorage.getJumpThresholdMs()).thenAnswer((_) async => 60000);
        when(
          () => mockService.isServiceRunning(),
        ).thenAnswer((_) async => false);
        when(() => mockService.stopDetectionService()).thenAnswer((_) async {});
        when(
          () => mockService.startDetectionService(
            appTimeLimits: any(named: 'appTimeLimits'),
            appJumpThresholdMs: any(named: 'appJumpThresholdMs'),
          ),
        ).thenAnswer((_) async {});

        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(appPreferencesProvider.future);
        await container.read(doomscrollBackgroundServiceProvider.future);
        await container.read(appJumpThresholdProvider.future);

        await container.read(appPreferencesProvider.notifier).saveAndApply();

        verify(() => mockStorage.savePreferences({'com.app.a': 60})).called(1);
        verify(() => mockService.stopDetectionService()).called(1);
        verify(
          () => mockService.startDetectionService(
            appTimeLimits: {'com.app.a': 60},
            appJumpThresholdMs: 60000,
          ),
        ).called(1);
      },
    );

    test(
      'saves preferences and does not start service when map is empty',
      () async {
        when(() => mockRepo.getPreferences()).thenAnswer((_) async => {});
        when(() => mockStorage.savePreferences(any())).thenAnswer((_) async {});
        when(
          () => mockService.isServiceRunning(),
        ).thenAnswer((_) async => true);
        when(() => mockService.stopDetectionService()).thenAnswer((_) async {});

        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(appPreferencesProvider.future);
        await container.read(doomscrollBackgroundServiceProvider.future);

        await container.read(appPreferencesProvider.notifier).saveAndApply();

        verify(() => mockStorage.savePreferences({})).called(1);
        verify(() => mockService.stopDetectionService()).called(1);
        verifyNever(
          () => mockService.startDetectionService(
            appTimeLimits: any(named: 'appTimeLimits'),
            appJumpThresholdMs: any(named: 'appJumpThresholdMs'),
          ),
        );
      },
    );
  });
}
