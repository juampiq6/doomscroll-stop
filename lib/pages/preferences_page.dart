import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doomscroll_stop/models/app_info.dart';
import 'package:doomscroll_stop/providers/app_preferences_provider.dart';
import 'package:doomscroll_stop/providers/installed_apps_provider.dart';
import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';
import 'package:get_it/get_it.dart';
import 'dart:typed_data';

class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
// Local state for app list is removed in favor of installedAppsProvider

  void _showAddAppSheet(List<AppInfo> apps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
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
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      final pkg = app.packageName;

                      return ListTile(
                        leading: app.icon != null
                            ? Image.memory(app.icon!, width: 32)
                            : const Icon(Icons.android),
                        title: Text(app.appName),
                        subtitle: Text(pkg),
                        onTap: () {
                          ref
                              .read(appPreferencesProvider.notifier)
                              .updateLimit(pkg, 300); // Default 5 mins
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(installedAppsProvider);
    final prefs = ref.watch(appPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracked Apps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              appsAsync.whenData((apps) => _showAddAppSheet(apps));
            },
          ),
        ],
      ),
      body: appsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (apps) {
          return prefs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (p) {
              if (p.appLimits.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.app_registration,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text('No apps added yet'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAddAppSheet(apps),
                        child: const Text('Add App'),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: p.appLimits.length,
                itemBuilder: (context, index) {
                  final pkg = p.appLimits.keys.elementAt(index);
                  final seconds = p.appLimits[pkg]!;

                  // Find app info
                  final appInfo = apps.where((a) => a.packageName == pkg).firstOrNull;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: appInfo?.icon != null
                          ? Image.memory(appInfo!.icon!, width: 32)
                          : const Icon(Icons.android),
                      title: Text(appInfo?.appName ?? pkg),
                      subtitle: Text(
                        '${(seconds / 60).toStringAsFixed(1)} minutes',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editTimeLimit(pkg, seconds),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => ref
                                .read(appPreferencesProvider.notifier)
                                .removeApp(pkg),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: prefs.asData?.value.appLimits.isEmpty ?? true
                ? null
                : () async {
                    await ref
                        .read(appPreferencesProvider.notifier)
                        .saveAndApply();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Preferences saved and service updated!',
                          ),
                        ),
                      );
                    }
                  },
            child: const Text(
              'SAVE & START TRACKING',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  void _editTimeLimit(String pkg, int currentSeconds) {
    int minutes = currentSeconds ~/ 60;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Time Limit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Set limit in minutes:'),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: minutes > 1
                            ? () => setDialogState(() => minutes--)
                            : null,
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
                        onPressed: () => setDialogState(() => minutes++),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(appPreferencesProvider.notifier)
                    .updateLimit(pkg, minutes * 60);
                Navigator.pop(context);
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }
}
