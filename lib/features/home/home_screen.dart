import 'package:doomscroll_stop/models/permission_state.dart';
import 'package:doomscroll_stop/routes.dart';
import 'package:doomscroll_stop/widgets/permission_banner.dart';
import 'package:doomscroll_stop/widgets/service_status_banner.dart';
import 'package:doomscroll_stop/features/home/dashboard_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doomscroll Stopper'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.stats),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.preferences),
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
              onTap: () => Navigator.pushNamed(context, AppRoutes.preferences),
              color: Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 16),
            DashboardCard(
              title: 'View Usage Stats',
              subtitle:
                  'Check how much time you spent on apps in the last 24 hours.',
              icon: Icons.bar_chart_rounded,
              onTap: () => Navigator.pushNamed(context, AppRoutes.stats),
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
