import 'package:doomscroll_stop/models/permission_state.dart';
import 'package:doomscroll_stop/providers/permission_provider.dart';
import 'package:doomscroll_stop/service_locator.dart';
import 'package:doomscroll_stop/services/permission_service/permission_service_interface.dart';
import 'package:doomscroll_stop/widgets/permission_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPermissionService extends Mock
    implements PermissionServiceInterface {}

void main() {
  late MockPermissionService mockService;

  setUp(() {
    mockService = MockPermissionService();
    getIt.registerLazySingleton<PermissionServiceInterface>(() => mockService);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget createBanner(PermissionType type) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: PermissionBanner(type: type)),
      ),
    );
  }

  testWidgets('PermissionBanner: granted - shows nothing', (tester) async {
    when(
      () => mockService.notificationPermissionStatus(),
    ).thenAnswer((_) async => NotificationPermissionStatus.granted);

    await tester.pumpWidget(createBanner(PermissionType.notification));
    await tester.pumpAndSettle();

    // The build method returns SizedBox.shrink() when isGranted is true
    expect(find.byType(AnimatedContainer), findsNothing);
  });

  testWidgets('PermissionBanner: denied - shows warning and GRANT button', (
    tester,
  ) async {
    when(
      () => mockService.notificationPermissionStatus(),
    ).thenAnswer((_) async => NotificationPermissionStatus.denied);

    await tester.pumpWidget(createBanner(PermissionType.notification));
    await tester.pumpAndSettle();

    expect(find.text('Permission Required'), findsOneWidget);
    expect(find.text('GRANT'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets(
    'PermissionBanner: permanently denied - shows error and SETTINGS button',
    (tester) async {
      when(
        () => mockService.notificationPermissionStatus(),
      ).thenAnswer((_) async => NotificationPermissionStatus.permanentlyDenied);

      await tester.pumpWidget(createBanner(PermissionType.notification));
      await tester.pumpAndSettle();

      expect(find.text('Permission Required'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    },
  );

  testWidgets('PermissionBanner: tapping GRANT calls requestPermission', (
    tester,
  ) async {
    when(
      () => mockService.notificationPermissionStatus(),
    ).thenAnswer((_) async => NotificationPermissionStatus.denied);
    when(
      () => mockService.requestNotificationPermission(),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(createBanner(PermissionType.notification));
    await tester.pumpAndSettle();

    await tester.tap(find.text('GRANT'));
    await tester.pumpAndSettle();

    verify(() => mockService.requestNotificationPermission()).called(1);
  });

  testWidgets(
    'PermissionBanner: UI transition from denied to permanently denied after failed request',
    (tester) async {
      // 1. Initial state: denied
      when(
        () => mockService.notificationPermissionStatus(),
      ).thenAnswer((_) async => NotificationPermissionStatus.denied);

      // 2. Mock request failure that triggers status change
      when(() => mockService.requestNotificationPermission()).thenAnswer((
        _,
      ) async {
        when(() => mockService.notificationPermissionStatus()).thenAnswer(
          (_) async => NotificationPermissionStatus.permanentlyDenied,
        );
        return false;
      });

      await tester.pumpWidget(createBanner(PermissionType.notification));
      await tester.pumpAndSettle();

      expect(find.text('GRANT'), findsOneWidget);

      await tester.tap(find.text('GRANT'));
      await tester.pumpAndSettle();

      // Verify it changed to SETTINGS
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    },
  );

  testWidgets(
    'PermissionBanner: UI transition from denied to granted after request',
    (tester) async {
      // 1. Initial state: denied
      when(
        () => mockService.notificationPermissionStatus(),
      ).thenAnswer((_) async => NotificationPermissionStatus.denied);

      // 2. Mock request failure that triggers status change
      when(() => mockService.requestNotificationPermission()).thenAnswer((
        _,
      ) async {
        when(
          () => mockService.notificationPermissionStatus(),
        ).thenAnswer((_) async => NotificationPermissionStatus.granted);
        return true;
      });

      await tester.pumpWidget(createBanner(PermissionType.notification));
      await tester.pumpAndSettle();

      expect(find.text('GRANT'), findsOneWidget);

      await tester.tap(find.text('GRANT'));
      await tester.pumpAndSettle();

      // Verify it changed to SETTINGS
      expect(find.byType(AnimatedContainer), findsNothing);
    },
  );

  testWidgets(
    'PermissionBanner: UI transition from permanently denied to granted after request (open settings)',
    (tester) async {
      // 1. Initial state: denied
      when(
        () => mockService.notificationPermissionStatus(),
      ).thenAnswer((_) async => NotificationPermissionStatus.permanentlyDenied);

      // 2. Mock opening settings which triggers status change to granted
      when(() => mockService.openAppNotificationSettings()).thenAnswer((
        _,
      ) async {
        when(
          () => mockService.notificationPermissionStatus(),
        ).thenAnswer((_) async => NotificationPermissionStatus.granted);
      });

      await tester.pumpWidget(createBanner(PermissionType.notification));
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS'), findsOneWidget);

      await tester.tap(find.text('SETTINGS'));
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedContainer), findsNothing);
      verify(() => mockService.openAppNotificationSettings()).called(1);
    },
  );
}
