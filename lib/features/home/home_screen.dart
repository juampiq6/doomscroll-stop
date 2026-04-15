import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doomscroll_stop/models/permission_state.dart';
import 'package:doomscroll_stop/widgets/permission_banner.dart';
import 'package:doomscroll_stop/widgets/service_status_banner.dart';
import 'package:doomscroll_stop/features/stats/app_stats_page.dart';
import 'package:doomscroll_stop/features/preferences/preferences_page.dart';
import 'package:doomscroll_stop/features/home/dashboard_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AppStatsPage())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PreferencesPage())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ServiceStatusBanner(),
            const PermissionBanner(type: PermissionType.notification),
            const PermissionBanner(type: PermissionType.usage),
            const SizedBox(height: 24),
            DashboardCard(
              title: 'Configure Tracking',
              subtitle:
                  'Select apps and set daily time limits to prevent doomscrolling.',
              icon: Icons.app_registration,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PreferencesPage()),
              ),
              color: Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 16),
            DashboardCard(
              title: 'View Usage Stats',
              subtitle:
                  'Check how much time you spent on apps in the last 24 hours.',
              icon: Icons.bar_chart_rounded,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AppStatsPage())),
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Ready to stop the scroll?',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
