import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doomscroll_stop/features/preferences/app_selection_sheet.dart';
import 'package:doomscroll_stop/features/preferences/time_limit_edit_dialog.dart';
import 'package:doomscroll_stop/models/app_info.dart';
import 'package:doomscroll_stop/providers/app_preferences_provider.dart';
import 'package:doomscroll_stop/providers/installed_apps_provider.dart';

class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  Future<void> _showAddAppSheet(List<AppInfo> apps) async {
    final selection = await AppSelectionSheet.show(context, apps);
    if (selection != null) {
      final pkg = selection.$1;
      final minutes = selection.$2;

      ref.read(appPreferencesProvider.notifier).updateLimit(pkg, minutes * 60);
    }
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
                  final appInfo = apps.firstWhere((a) => a.packageName == pkg);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: appInfo.icon != null
                          ? Image.memory(appInfo.icon!, width: 32)
                          : const Icon(Icons.android),
                      title: Text(appInfo.appName),
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

  Future<void> _editTimeLimit(String pkg, int currentSeconds) async {
    final minutes = await TimeLimitEditDialog.show(
      context,
      currentSeconds ~/ 60,
    );
    if (minutes != null) {
      ref.read(appPreferencesProvider.notifier).updateLimit(pkg, minutes * 60);
    }
  }
}
