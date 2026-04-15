import 'package:doomscroll_stop/providers/app_preferences_provider.dart';
import 'package:flutter/material.dart';

class TimeLimitEditDialog extends StatefulWidget {
  final int initialMinutes;

  const TimeLimitEditDialog({super.key, required this.initialMinutes});

  static Future<int?> show(BuildContext context, int initialMinutes) {
    return showDialog<int?>(
      context: context,
      builder: (context) => TimeLimitEditDialog(initialMinutes: initialMinutes),
    );
  }

  @override
  State<TimeLimitEditDialog> createState() => _TimeLimitEditDialogState();
}

class _TimeLimitEditDialogState extends State<TimeLimitEditDialog> {
  late int minutes;

  @override
  void initState() {
    super.initState();
    minutes = widget.initialMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Time Limit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Set limit in minutes:'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: minutes > 1 ? () => setState(() => minutes--) : null,
              ),
              Text(
                '$minutes min',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: minutes < maxMinutes
                    ? () => setState(() => minutes++)
                    : null,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, minutes),
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
