import 'package:flutter/material.dart';
import 'package:doomscroll_stop/models/app_session.dart';

class UsageTimeline extends StatelessWidget {
  final List<AppSession> sessions;
  final int beginTime;
  final int endTime;

  const UsageTimeline({
    super.key,
    required this.sessions,
    required this.beginTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    final totalSpan = endTime - beginTime;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      height: 80,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Usage Pattern',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                return Stack(
                  children: [
                    // Background bar
                    Container(
                      height: 12,
                      width: width,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    // Session segments
                    ...sessions.map((session) {
                      final left =
                          ((session.startTime - beginTime) / totalSpan) * width;
                      final sessionWidth =
                          ((session.stopTime - session.startTime) / totalSpan) *
                          width;

                      // Ensure minimum width of 2px for visibility of tiny sessions
                      final displayWidth = sessionWidth < 2
                          ? 2.0
                          : sessionWidth;

                      return Positioned(
                        left: left,
                        child: Container(
                          height: 12,
                          width: displayWidth,
                          decoration: BoxDecoration(
                            color: session.hasInteraction
                                ? Colors.deepPurpleAccent
                                : Colors.deepPurpleAccent.withValues(
                                    alpha: 0.4,
                                  ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: session.hasInteraction
                                ? [
                                    BoxShadow(
                                      color: Colors.deepPurpleAccent.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }),
                    // Time markers
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _buildTimeLabel(beginTime),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _buildTimeLabel(endTime),
                            ),
                            _buildMidnightMarker(width, totalSpan),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMidnightMarker(double width, int totalSpan) {
    final now = DateTime.now();
    final midnight = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;

    if (midnight > beginTime && midnight < endTime) {
      final left = ((midnight - beginTime) / totalSpan) * width;
      return Positioned(
        left: left - 15, // Center the label approx
        child: _buildTimeLabel(midnight),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTimeLabel(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return Text(
      '$h:$m',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.3),
        fontSize: 10,
      ),
    );
  }
}
