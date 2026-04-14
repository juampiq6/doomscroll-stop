import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doomscroll_stop/providers/service_status_provider.dart';

class ServiceStatusBanner extends ConsumerStatefulWidget {
  const ServiceStatusBanner({super.key});

  @override
  ConsumerState<ServiceStatusBanner> createState() =>
      _ServiceStatusBannerState();
}

class _ServiceStatusBannerState extends ConsumerState<ServiceStatusBanner>
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
      ref.read(serviceStatusProvider.notifier).reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceStatusProvider);

    return serviceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (isRunning) {
        final color = isRunning ? Colors.green : Colors.blue;
        final icon = isRunning
            ? Icons.check_circle_outline
            : Icons.info_outline;
        final title = isRunning ? 'Service Active' : 'Service Inactive';
        final description = isRunning
            ? 'The doomscroll tracker is currently watching your screen time.'
            : 'The doomscroll tracker is currently inactive. Press START to activate.';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isRunning ? Colors.greenAccent : Colors.blueAccent,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
