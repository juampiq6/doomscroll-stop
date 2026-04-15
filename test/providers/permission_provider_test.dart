import 'package:doomscroll_stop/models/permission_state.dart';
import 'package:doomscroll_stop/providers/permission_provider.dart';
import 'package:doomscroll_stop/service_locator.dart';
import 'package:doomscroll_stop/services/permission_service/permission_service_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPermissionService extends Mock
    implements PermissionServiceInterface {}

void main() {
  late MockPermissionService mockService;

  setUp(() {
    mockService = MockPermissionService();
    // Use registerLazySingleton so that if a widget/provider calls it, it gets the mock.
    // Register it as the interface.
    getIt.registerLazySingleton<PermissionServiceInterface>(() => mockService);
  });

  tearDown(() {
    getIt.reset();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer();
  }

  group('PermissionProvider - Notification', () {
    test('initially granted', () async {
      when(
        () => mockService.notificationPermissionStatus(),
      ).thenAnswer((_) async => NotificationPermissionStatus.granted);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(
        permissionProvider(PermissionType.notification).future,
      );

      expect(state.status, 0); // granted
      expect(state.isGranted, true);
      verify(() => mockService.notificationPermissionStatus()).called(1);
    });

    test('initially denied', () async {
      when(
        () => mockService.notificationPermissionStatus(),
      ).thenAnswer((_) async => NotificationPermissionStatus.denied);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(
        permissionProvider(PermissionType.notification).future,
      );

      expect(state.status, 1); // denied
      expect(state.isDenied, true);
    });

    test('initially permanently denied', () async {
      when(
        () => mockService.notificationPermissionStatus(),
      ).thenAnswer((_) async => NotificationPermissionStatus.permanentlyDenied);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(
        permissionProvider(PermissionType.notification).future,
      );

      expect(state.status, 2); // permanently denied
      expect(state.isPermanentlyDenied, true);
    });

    test(
      'requestPermission flow: denied -> requested -> denied again',
      () async {
        // 1. Initial status: denied
        when(
          () => mockService.notificationPermissionStatus(),
        ).thenAnswer((_) async => NotificationPermissionStatus.denied);
        // 2. Request status update: denied again
        when(
          () => mockService.requestNotificationPermission(),
        ).thenAnswer((_) async => false);

        final container = makeContainer();
        addTearDown(container.dispose);

        // Verify initial build state
        final initialState = await container.read(
          permissionProvider(PermissionType.notification).future,
        );
        expect(initialState.isDenied, true);

        // Trigger request
        await container
            .read(permissionProvider(PermissionType.notification).notifier)
            .requestPermission();

        // Verify state after request
        final finalState = container
            .read(permissionProvider(PermissionType.notification))
            .value!;
        expect(finalState.isDenied, true);

        verify(() => mockService.requestNotificationPermission()).called(1);
        verify(() => mockService.notificationPermissionStatus()).called(2);
      },
    );

    test(
      'requestPermission flow: denied -> requested -> permanentlyDenied',
      () async {
        // 1. Initial: denied
        when(
          () => mockService.notificationPermissionStatus(),
        ).thenAnswer((_) async => NotificationPermissionStatus.denied);

        // 2. Request permission. User denies again and status becomes permanentlyDenied
        when(() => mockService.requestNotificationPermission()).thenAnswer((
          _,
        ) async {
          // Mock next status check will return permanentlyDenied
          when(() => mockService.notificationPermissionStatus()).thenAnswer(
            (_) async => NotificationPermissionStatus.permanentlyDenied,
          );
          return false;
        });

        final container = makeContainer();
        addTearDown(container.dispose);

        // Verify initial build state
        final initialState = await container.read(
          permissionProvider(PermissionType.notification).future,
        );
        expect(initialState.isDenied, true);

        // Trigger request
        await container
            .read(permissionProvider(PermissionType.notification).notifier)
            .requestPermission();

        // Verify state after request
        final finalState = container
            .read(permissionProvider(PermissionType.notification))
            .value!;
        expect(finalState.isPermanentlyDenied, true);

        verify(() => mockService.requestNotificationPermission()).called(1);
        verify(() => mockService.notificationPermissionStatus()).called(2);
      },
    );

    test('requestPermission flow: denied -> requested -> granted', () async {
      // 1. Initial: denied
      when(
        () => mockService.notificationPermissionStatus(),
      ).thenAnswer((_) async => NotificationPermissionStatus.denied);

      // 2. Request permission. User grants.
      when(() => mockService.requestNotificationPermission()).thenAnswer((
        _,
      ) async {
        when(
          () => mockService.notificationPermissionStatus(),
        ).thenAnswer((_) async => NotificationPermissionStatus.granted);
        return true;
      });

      final container = makeContainer();
      addTearDown(container.dispose);

      // Initial build check
      final initialState = await container.read(
        permissionProvider(PermissionType.notification).future,
      );
      expect(initialState.isDenied, true);

      // Request
      await container
          .read(permissionProvider(PermissionType.notification).notifier)
          .requestPermission();

      // Final state
      final finalState = container
          .read(permissionProvider(PermissionType.notification))
          .value!;
      expect(finalState.isGranted, true);
      verify(() => mockService.requestNotificationPermission()).called(1);
    });

    test(
      'requestPermission flow: permanentlyDenied -> openSettings -> granted',
      () async {
        // 1. Initial: permanentlyDenied
        when(() => mockService.notificationPermissionStatus()).thenAnswer(
          (_) async => NotificationPermissionStatus.permanentlyDenied,
        );

        when(() => mockService.openAppNotificationSettings()).thenAnswer((
          _,
        ) async {
          // User goes to settings, manually grants
          // Mock next status check will be granted
          when(
            () => mockService.notificationPermissionStatus(),
          ).thenAnswer((_) async => NotificationPermissionStatus.granted);
        });

        final container = makeContainer();
        addTearDown(container.dispose);

        // Initial build check
        final initialState = await container.read(
          permissionProvider(PermissionType.notification).future,
        );
        expect(initialState.isPermanentlyDenied, true);

        // Request (this will call openAppNotificationSettings)
        await container
            .read(permissionProvider(PermissionType.notification).notifier)
            .requestPermission();

        // Final state
        final finalState = container
            .read(permissionProvider(PermissionType.notification))
            .value!;
        expect(finalState.isGranted, true);

        verify(() => mockService.openAppNotificationSettings()).called(1);
        verifyNever(() => mockService.requestNotificationPermission());
      },
    );
  });

  group('PermissionProvider - Usage', () {
    test('initially granted', () async {
      when(
        () => mockService.isUsagePermissionGranted(),
      ).thenAnswer((_) async => true);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(
        permissionProvider(PermissionType.usage).future,
      );

      expect(state.isGranted, true);
    });

    test('initially denied', () async {
      when(
        () => mockService.isUsagePermissionGranted(),
      ).thenAnswer((_) async => false);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(
        permissionProvider(PermissionType.usage).future,
      );

      expect(state.isDenied, true);
    });

    test('requestPermission flow: denied -> openSettings -> granted', () async {
      // 1. Initial: denied
      when(
        () => mockService.isUsagePermissionGranted(),
      ).thenAnswer((_) async => false);

      when(() => mockService.openUsageSettings()).thenAnswer((_) async {
        // Mock user manually granting in settings
        when(
          () => mockService.isUsagePermissionGranted(),
        ).thenAnswer((_) async => true);
      });

      final container = makeContainer();
      addTearDown(container.dispose);

      // Initial build
      final initialState = await container.read(
        permissionProvider(PermissionType.usage).future,
      );
      expect(initialState.isDenied, true);

      // Request
      await container
          .read(permissionProvider(PermissionType.usage).notifier)
          .requestPermission();

      // Final state
      final finalState =
          container.read(permissionProvider(PermissionType.usage)).value!;
      expect(finalState.isGranted, true);

      verify(() => mockService.openUsageSettings()).called(1);
    });

    test('requestPermission flow: denied -> openSettings -> remains denied',
        () async {
      // 1. Initial: denied
      when(
        () => mockService.isUsagePermissionGranted(),
      ).thenAnswer((_) async => false);

      when(() => mockService.openUsageSettings()).thenAnswer((_) async {
        // Mock user NOT granting in settings
        when(
          () => mockService.isUsagePermissionGranted(),
        ).thenAnswer((_) async => false);
      });

      final container = makeContainer();
      addTearDown(container.dispose);

      // Initial build
      final initialState = await container.read(
        permissionProvider(PermissionType.usage).future,
      );
      expect(initialState.isDenied, true);

      // Request
      await container
          .read(permissionProvider(PermissionType.usage).notifier)
          .requestPermission();

      // Final state - remains denied
      final finalState =
          container.read(permissionProvider(PermissionType.usage)).value!;
      expect(finalState.isDenied, true);

      verify(() => mockService.openUsageSettings()).called(1);
    });
  });
}
