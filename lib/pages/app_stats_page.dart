import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';

class AppStatsPage extends StatefulWidget {
  const AppStatsPage({super.key});

  @override
  State<AppStatsPage> createState() => _AppStatsPageState();
}

class _AppStatsPageState extends State<AppStatsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _stats = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final service = GetIt.instance<MethodChannelServiceInterface>();

    // Get apps to have names/icons
    final apps = await service.getInstalledApps();
    final appsMap = {for (var app in apps) app['packageName'] as String: app};

    // Get usage stats for the last 24 hours
    final now = DateTime.now().millisecondsSinceEpoch;
    final yesterday = DateTime.now()
        .subtract(Duration(days: 1))
        .millisecondsSinceEpoch;

    final usageMap = await service.getAppUsageStats(
      beginTime: yesterday,
      endTime: now,
    );

    final statsList = <Map<String, dynamic>>[];
    usageMap.forEach((pkg, data) {
      final app = appsMap[pkg];
      if (app != null) {
        final timeMs = data['totalTimeInForeground'] as int? ?? 0;
        if (timeMs > 0) {
          statsList.add({
            'appName': app['appName'],
            'packageName': pkg,
            'icon': app['icon'],
            'totalTimeInForeground': timeMs,
          });
        }
      }
    });

    // Sort by time descending
    statsList.sort(
      (a, b) => (b['totalTimeInForeground'] as num).compareTo(
        a['totalTimeInForeground'] as num,
      ),
    );

    if (mounted) {
      setState(() {
        _stats = statsList;
        _loading = false;
      });
    }
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);

    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Usage (Last 24h)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _fetchStats();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats.isEmpty
          ? const Center(child: Text('No usage data found for the last 24h.'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _stats.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _stats[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: item['icon'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            item['icon'] as Uint8List,
                            width: 44,
                            height: 44,
                          ),
                        )
                      : const Icon(Icons.android, size: 44),
                  title: Text(
                    item['appName'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    item['packageName'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  trailing: Text(
                    _formatDuration(item['totalTimeInForeground'] as int),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
