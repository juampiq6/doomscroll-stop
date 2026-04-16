import 'dart:typed_data';
import 'package:doomscroll_stop/features/stats/widgets/usage_timeline.dart';
import 'package:flutter/material.dart';
import 'package:doomscroll_stop/models/app_session.dart';
import 'package:doomscroll_stop/features/stats/widgets/app_session_card.dart';

class AppSessionsDetailPage extends StatelessWidget {
  final String appName;
  final String packageName;
  final Uint8List? icon;
  final List<AppSession> sessions;
  final int beginTime;
  final int endTime;

  const AppSessionsDetailPage({
    super.key,
    required this.appName,
    required this.packageName,
    required this.sessions,
    required this.beginTime,
    required this.endTime,
    this.icon,
  });

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);

    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    // Sort sessions by start time descending (newest first)
    final sortedSessions = List<AppSession>.from(sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    final totalTime = sessions.fold(0, (sum, s) => sum + s.durationMs);
    final interactions = sessions.where((s) => s.hasInteraction).length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Session History'),
      ),
      body: Column(
        children: [
          _buildHeader(totalTime, interactions),
          UsageTimeline(
            sessions: sessions,
            beginTime: beginTime,
            endTime: endTime,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sortedSessions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = sortedSessions[index];
                return AppSessionCard(session: session);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int totalTime, int interactions) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (icon != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(icon!, width: 64, height: 64),
            )
          else
            const Icon(Icons.android, size: 64, color: Colors.white24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  packageName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.timer_outlined,
                      label: _formatDuration(totalTime),
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      icon: Icons.touch_app_outlined,
                      label: '$interactions',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.deepPurpleAccent),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
