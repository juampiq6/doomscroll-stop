import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doomscroll_stop/models/permission_state.dart';
import 'package:doomscroll_stop/providers/permission_provider.dart';

class PermissionBanner extends ConsumerStatefulWidget {
  final PermissionType type;

  const PermissionBanner({super.key, required this.type});

  @override
  ConsumerState<PermissionBanner> createState() => _PermissionBannerState();
}

class _PermissionBannerState extends ConsumerState<PermissionBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionProvider(widget.type).notifier).reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionAsync = ref.watch(permissionProvider(widget.type));

    return permissionAsync.when(
      loading: SizedBox.shrink,
      error: (e, st) => const SizedBox.shrink(),
      data: (permissionState) {
        final String? errorMessage = permissionState.error;

        final bool isGranted = permissionState.isGranted;
        final bool isPermanentlyDenied = permissionState.isPermanentlyDenied;

        if (isGranted) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isPermanentlyDenied
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPermanentlyDenied
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isPermanentlyDenied
                    ? Icons.error_outline
                    : Icons.warning_amber_rounded,
                color: isPermanentlyDenied
                    ? Colors.redAccent
                    : Colors.orangeAccent,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Permission Required',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      errorMessage ?? 'Unknown permission error',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ref
                      .read(permissionProvider(widget.type).notifier)
                      .requestPermission();
                },
                style: TextButton.styleFrom(
                  foregroundColor: isPermanentlyDenied
                      ? Colors.redAccent
                      : Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  isPermanentlyDenied ? 'SETTINGS' : 'GRANT',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
