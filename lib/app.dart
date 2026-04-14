import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';
import 'dart:typed_data';
import 'package:doomscroll_stop/widgets/permission_banner.dart';
import 'package:doomscroll_stop/widgets/service_status_banner.dart';
import 'package:doomscroll_stop/pages/app_stats_page.dart';
import 'package:doomscroll_stop/providers/permission_provider.dart';
import 'package:doomscroll_stop/providers/service_status_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doomscroll_stop/pages/preferences_page.dart';

class DoomscrollApp extends StatelessWidget {
  const DoomscrollApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doomscroll Stopper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Doomscroll Stopper'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  List<Map<String, dynamic>> _apps = [];
  Map<String, dynamic>? _selectedApp;

  final List<int> _minutesOptions = [1, 2, 3, 4, 5, 7, 10, 15, 20, 30, 45, 60];
  int _selectedMinutes = 5;

  bool _isServiceRunning = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Fetch installed apps using method channel service
    final methodChannelService =
        GetIt.instance<MethodChannelServiceInterface>();
    List<Map<String, dynamic>> apps = await methodChannelService
        .getInstalledApps();

    setState(() {
      _apps = apps;
      _loading = false;
    });
  }

  Future<void> _toggleService() async {
    if (_selectedApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an app first')),
      );
      return;
    }

    final methodChannelService =
        GetIt.instance<MethodChannelServiceInterface>();

    try {
      if (_isServiceRunning) {
        await methodChannelService.stopDetectionService();
        setState(() => _isServiceRunning = false);
        ref.read(serviceStatusProvider.notifier).updateStatus(false);
      } else {
        await methodChannelService.startDetectionService(
          appTimeLimits: {
            _selectedApp!['packageName'] as String: _selectedMinutes * 60,
          },
        );
        setState(() => _isServiceRunning = true);
        ref.read(serviceStatusProvider.notifier).updateStatus(true);
      }
    } catch (e) {
      debugPrint("Service error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'test_notif') {
                final methodChannelService =
                    GetIt.instance<MethodChannelServiceInterface>();
                await methodChannelService.testNotification();
              } else if (value == 'stats') {
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AppStatsPage()),
                  );
                }
              } else if (value == 'prefs') {
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PreferencesPage()),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'prefs',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 20),
                      SizedBox(width: 10),
                      Text('Preferences'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart, size: 20),
                      SizedBox(width: 10),
                      Text('App Stats'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'test_notif',
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, size: 20),
                      SizedBox(width: 10),
                      Text('Test Notification'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ServiceStatusBanner(),
                  const PermissionBanner(type: PermissionType.notification),
                  const PermissionBanner(type: PermissionType.usage),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PreferencesPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text('CONFIGURE TRACKED APPS'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const Divider(height: 48),
                  const Text(
                    '1. Pick an App',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: _selectedApp,
                    isExpanded: true,
                    hint: const Text('Select application...'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _apps.map((app) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: app,
                        child: Row(
                          children: [
                            if (app['icon'] != null) ...[
                              Image.memory(
                                app['icon'] as Uint8List,
                                width: 32,
                                height: 32,
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: Text(
                                app['appName'] as String,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedApp = val);
                    },
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    '2. Trigger Time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedMinutes,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _minutesOptions
                        .map(
                          (min) => DropdownMenuItem(
                            value: min,
                            child: Text('$min minutes'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMinutes = val);
                    },
                  ),

                  const Spacer(),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: _isServiceRunning
                          ? Colors.red
                          : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _toggleService,
                    child: Text(
                      _isServiceRunning ? 'STOP TRACKING' : 'START TRACKING',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
