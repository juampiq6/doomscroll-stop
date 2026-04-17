import 'package:doomscroll_stop/providers/app_usage_provider.dart';
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

  group('AppUsageProvider - initial state', () {
    test('returns empty usage list when no apps used', () async {
      when(
        () => mockService.getAppUsageStats(
          beginTime: any(named: 'beginTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer((_) async => {});

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(appUsageProvider.future);

      expect(state.usageList, isEmpty);
      expect(state.beginTime, lessThan(state.endTime));
    });

    test('returns sorted usage list by total time descending', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final rawStats = {
        'com.app.low': [
          {
            'startTime': now - 1000,
            'stopTime': now - 500,
            'hasInteraction': true,
          },
        ],
        'com.app.high': [
          {
            'startTime': now - 10000,
            'stopTime': now - 1000,
            'hasInteraction': true,
          },
        ],
      };

      when(
        () => mockService.getAppUsageStats(
          beginTime: any(named: 'beginTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer((_) async => rawStats);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(appUsageProvider.future);

      expect(state.usageList.length, 2);
      expect(state.usageList[0].packageName, 'com.app.high');
      expect(state.usageList[1].packageName, 'com.app.low');
    });

    test('filters out apps with zero usage time', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final rawStats = {
        'com.app.active': [
          {
            'startTime': now - 5000,
            'stopTime': now - 1000,
            'hasInteraction': true,
          },
        ],
        'com.app.idle': [
          {
            'startTime': now - 1000,
            'stopTime': now - 1000,
            'hasInteraction': false,
          },
        ],
      };

      when(
        () => mockService.getAppUsageStats(
          beginTime: any(named: 'beginTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer((_) async => rawStats);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(appUsageProvider.future);

      expect(state.usageList.length, 1);
      expect(state.usageList.first.packageName, 'com.app.active');
    });

    test('emits error state when service throws', () async {
      when(
        () => mockService.getAppUsageStats(
          beginTime: any(named: 'beginTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenThrow(Exception('usage stats error'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(appUsageProvider.future)
          .catchError(
            (_) => AppUsageState(usageList: [], beginTime: 0, endTime: 0),
          );

      final state = container.read(appUsageProvider);
      expect(state, isA<AsyncError>());
    });
  }, skip: true);

  group('AppUsageProvider - refresh', () {
    test('refresh re-fetches usage stats', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      when(
        () => mockService.getAppUsageStats(
          beginTime: any(named: 'beginTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer(
        (_) async => {
          'com.example.app': [
            {
              'startTime': now - 3000,
              'stopTime': now - 1000,
              'hasInteraction': true,
            },
          ],
        },
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(appUsageProvider.future);

      await container.read(appUsageProvider.notifier).refresh();

      final state = container.read(appUsageProvider).value!;
      expect(state.usageList.length, 1);
      expect(state.usageList.first.packageName, 'com.example.app');

      verify(
        () => mockService.getAppUsageStats(
          beginTime: any(named: 'beginTime'),
          endTime: any(named: 'endTime'),
        ),
      ).called(2);
    });

    test('refresh emits error state when service throws', () async {
      when(
        () => mockService.getAppUsageStats(
          beginTime: any(named: 'beginTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer((_) async => {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(appUsageProvider.future);

      when(
        () => mockService.getAppUsageStats(
          beginTime: any(named: 'beginTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenThrow(Exception('refresh failed'));

      await container.read(appUsageProvider.notifier).refresh();

      final state = container.read(appUsageProvider);
      expect(state, isA<AsyncError>());
    });
  });
}
