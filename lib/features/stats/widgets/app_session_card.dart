import 'package:flutter/material.dart';
import 'package:doomscroll_stop/models/app_session.dart';

class AppSessionCard extends StatelessWidget {
  final AppSession session;

  const AppSessionCard({super.key, required this.session});

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);

    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  bool _isYesterday(int timestamp) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final isYesterday = _isYesterday(session.startTime);
    final showFinishTime = session.durationMs >= 60000;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: session.hasInteraction
              ? Colors.deepPurpleAccent.withValues(alpha: 0.2)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          _buildLeadingIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 6),
                _buildTimeInfo(isYesterday, showFinishTime),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: session.hasInteraction
            ? Colors.deepPurpleAccent.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(
        session.hasInteraction ? Icons.touch_app : Icons.timer,
        size: 20,
        color: session.hasInteraction
            ? Colors.deepPurpleAccent
            : Colors.white38,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(session.durationMs),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (session.hasInteraction)
          const Text(
            'Interacted',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurpleAccent,
              letterSpacing: 0.5,
            ),
          ),
      ],
    );
  }

  Widget _buildTimeInfo(bool isYesterday, bool showFinishTime) {
    return Row(
      children: [
        Text(
          _formatTime(session.startTime),
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        if (showFinishTime) ...[
          Text(
            ' - ${_formatTime(session.stopTime)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
        if (isYesterday) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Yesterday',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
