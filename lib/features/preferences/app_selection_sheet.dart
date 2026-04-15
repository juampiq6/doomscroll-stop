import 'package:doomscroll_stop/models/app_info.dart';
import 'package:doomscroll_stop/providers/app_preferences_provider.dart';
import 'package:flutter/material.dart';

class AppSelectionSheet extends StatefulWidget {
  final List<AppInfo> apps;

  const AppSelectionSheet({super.key, required this.apps});

  static Future<(String, int)?> show(BuildContext context, List<AppInfo> apps) {
    return showModalBottomSheet<(String, int)?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AppSelectionSheet(apps: apps),
    );
  }

  @override
  State<AppSelectionSheet> createState() => _AppSelectionSheetState();
}

class _AppSelectionSheetState extends State<AppSelectionSheet> {
  int minutes = 5;
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select App to Track',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.apps.length,
                itemBuilder: (context, index) {
                  final app = widget.apps[index];
                  final pkg = app.packageName;

                  return ListTile(
                    leading: app.icon != null
                        ? Image.memory(app.icon!, width: 32)
                        : const Icon(Icons.android),
                    title: Text(app.appName),
                    subtitle: Text(pkg),
                    onTap: () {
                      Navigator.pop(context, (pkg, minutes));
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Time Limit:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: minutes > 1
                          ? () => setState(() => minutes--)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$minutes min',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
              ),
            ),
          ],
        );
      },
    );
  }
}
