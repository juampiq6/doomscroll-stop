import 'package:flutter/material.dart';
import 'package:doomscroll_stop/providers/installed_apps_provider.dart';
import 'package:doomscroll_stop/features/stats/app_sessions_detail_page.dart';
import 'package:doomscroll_stop/providers/app_usage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppStatsPage extends ConsumerStatefulWidget {
  const AppStatsPage({super.key});

  @override
  ConsumerState<AppStatsPage> createState() => _AppStatsPageState();
}

class _AppStatsPageState extends ConsumerState<AppStatsPage> {
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
    final usageAsync = ref.watch(appUsageProvider);
    final appsAsync = ref.watch(installedAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Usage (Last 24h)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(appUsageProvider.notifier).refresh(),
          ),
        ],
      ),
      body: usageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (state) {
          final usageList = state.usageList;
          if (usageList.isEmpty) {
            return const Center(
              child: Text('No usage data found for the last 24h.'),
            );
          }

          return appsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text('Error loading app info: $err')),
            data: (apps) {
              final appsMap = {for (var app in apps) app.packageName: app};

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: usageList.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final usage = usageList[index];
                  final app = appsMap[usage.packageName];

                  if (app == null) return const SizedBox.shrink();

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppSessionsDetailPage(
                            appName: app.appName,
                            packageName: app.packageName,
                            sessions: usage.sessions,
                            beginTime: state.beginTime,
                            endTime: state.endTime,
                            icon: app.icon,
                          ),
                        ),
                      );
                    },
                    leading: app.icon != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              app.icon!,
                              width: 48,
                              height: 48,
                            ),
                          )
                        : const Icon(Icons.android, size: 48),
                    title: Text(
                      app.appName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          app.packageName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDuration(usage.totalTimeMs),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
