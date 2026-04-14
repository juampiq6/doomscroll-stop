import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doomscroll_stop/providers/app_preferences_provider.dart';
import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';
import 'package:get_it/get_it.dart';
import 'dart:typed_data';

class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  List<Map<String, dynamic>> _installedApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final service = GetIt.instance<MethodChannelServiceInterface>();
    final apps = await service.getInstalledApps(includeSystemApps: false);
    if (mounted) {
      setState(() {
        _installedApps = apps;
        _isLoading = false;
      });
    }
  }

  void _showAddAppSheet() {
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
                    itemCount: _installedApps.length,
                    itemBuilder: (context, index) {
                      final app = _installedApps[index];
                      final pkg = app['packageName'] as String;

                      return ListTile(
                        leading: app['icon'] != null
                            ? Image.memory(app['icon'] as Uint8List, width: 32)
                            : const Icon(Icons.android),
                        title: Text(app['appName'] as String),
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
    final prefs = ref.watch(appPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracked Apps'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddAppSheet),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : prefs.value!.appLimits.isEmpty
          ? Center(
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
                    onPressed: _showAddAppSheet,
                    child: const Text('Add App'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: prefs.value!.appLimits.length,
              itemBuilder: (context, index) {
                final pkg = prefs.value!.appLimits.keys.elementAt(index);
                final seconds = prefs.value!.appLimits[pkg]!;

                // Find app info
                final appInfo = _installedApps.firstWhere(
                  (a) => a['packageName'] == pkg,
                  orElse: () => {'appName': pkg},
                );

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: appInfo['icon'] != null
                        ? Image.memory(appInfo['icon'] as Uint8List, width: 32)
                        : const Icon(Icons.android),
                    title: Text(appInfo['appName'] as String),
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
            onPressed: prefs.value!.appLimits.isEmpty
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
