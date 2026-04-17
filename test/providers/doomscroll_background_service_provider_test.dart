import 'package:doomscroll_stop/providers/doomscroll_background_service_provider.dart';
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

  group('DoomscrollBackgroundServiceProvider - initial state', () {
    test('returns true when service is running', () async {
      when(() => mockService.isServiceRunning()).thenAnswer((_) async => true);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(
        doomscrollBackgroundServiceProvider.future,
      );

      expect(state, true);
      verify(() => mockService.isServiceRunning()).called(1);
    });

    test('returns false when service is not running', () async {
      when(() => mockService.isServiceRunning()).thenAnswer((_) async => false);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(
        doomscrollBackgroundServiceProvider.future,
      );

      expect(state, false);
    });

    test('emits error state when service check throws', () async {
      when(
        () => mockService.isServiceRunning(),
      ).thenThrow(Exception('channel error'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(doomscrollBackgroundServiceProvider.future)
          .catchError((_) => false);

      final state = container.read(doomscrollBackgroundServiceProvider);
      expect(state, isA<AsyncError>());
    });
  }, skip: true);

  group('DoomscrollBackgroundServiceProvider - start', () {
    test('sets state to true after start succeeds', () async {
      when(() => mockService.isServiceRunning()).thenAnswer((_) async => false);
      when(
        () => mockService.startDetectionService(
          appTimeLimits: any(named: 'appTimeLimits'),
          appJumpThresholdMs: any(named: 'appJumpThresholdMs'),
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(doomscrollBackgroundServiceProvider.future);

      await container.read(doomscrollBackgroundServiceProvider.notifier).start({
        'com.example.app': 60,
      }, 30000);

      final state = container.read(doomscrollBackgroundServiceProvider).value!;
      expect(state, true);

      verify(
        () => mockService.startDetectionService(
          appTimeLimits: {'com.example.app': 60},
          appJumpThresholdMs: 30000,
        ),
      ).called(1);
    });

    test('emits error state when start throws', () async {
      when(() => mockService.isServiceRunning()).thenAnswer((_) async => false);
      when(
        () => mockService.startDetectionService(
          appTimeLimits: any(named: 'appTimeLimits'),
          appJumpThresholdMs: any(named: 'appJumpThresholdMs'),
        ),
      ).thenThrow(Exception('start failed'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(doomscrollBackgroundServiceProvider.future);

      await container
          .read(doomscrollBackgroundServiceProvider.notifier)
          .start({}, 30000);

      final state = container.read(doomscrollBackgroundServiceProvider);
      expect(state, isA<AsyncError>());
    });
  }, skip: true);

  group('DoomscrollBackgroundServiceProvider - stop', () {
    test('sets state to false after stop succeeds', () async {
      when(() => mockService.isServiceRunning()).thenAnswer((_) async => true);
      when(() => mockService.stopDetectionService()).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(doomscrollBackgroundServiceProvider.future);

      await container.read(doomscrollBackgroundServiceProvider.notifier).stop();

      final state = container.read(doomscrollBackgroundServiceProvider).value!;
      expect(state, false);
      verify(() => mockService.stopDetectionService()).called(1);
    });

    test('emits error state when stop throws', () async {
      when(() => mockService.isServiceRunning()).thenAnswer((_) async => true);
      when(
        () => mockService.stopDetectionService(),
      ).thenThrow(Exception('stop failed'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(doomscrollBackgroundServiceProvider.future);

      await container.read(doomscrollBackgroundServiceProvider.notifier).stop();

      final state = container.read(doomscrollBackgroundServiceProvider);
      expect(state, isA<AsyncError>());
    });
  });
}
