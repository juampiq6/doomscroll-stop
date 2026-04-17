import 'package:doomscroll_stop/providers/app_jump_threshold_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _minMinutes = 1;
const _maxMinutes = 30;

class JumpThresholdModal extends ConsumerStatefulWidget {
  const JumpThresholdModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const JumpThresholdModal(),
    );
  }

  @override
  ConsumerState<JumpThresholdModal> createState() => _JumpThresholdModalState();
}

class _JumpThresholdModalState extends ConsumerState<JumpThresholdModal> {
  late int _minutes;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final thresholdAsync = ref.watch(appJumpThresholdProvider);

    return thresholdAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Error: $e'),
      ),
      data: (thresholdMs) {
        if (!_initialized) {
          _minutes = (thresholdMs / 60000).round().clamp(_minMinutes, _maxMinutes);
          _initialized = true;
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'App Switch Threshold',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Minimum time between app switches before it counts as doomscrolling.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    icon: const Icon(Icons.remove),
                    onPressed: _minutes > _minMinutes
                        ? () => setState(() => _minutes--)
                        : null,
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '$_minutes min',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    onPressed: _minutes < _maxMinutes
                        ? () => setState(() => _minutes++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await ref
                            .read(appJumpThresholdProvider.notifier)
                            .setThreshold(_minutes * 60000);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('SAVE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
