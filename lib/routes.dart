import 'package:doomscroll_stop/features/home/home_screen.dart';
import 'package:doomscroll_stop/features/preferences/preferences_page.dart';
import 'package:doomscroll_stop/features/stats/app_sessions_detail_page.dart';
import 'package:doomscroll_stop/features/stats/app_stats_page.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const home = '/';
  static const preferences = '/preferences';
  static const stats = '/stats';
  static const sessionDetail = '/stats/detail';
}

Map<String, WidgetBuilder> get appRoutes => {
  AppRoutes.home: (_) => const HomeScreen(),
  AppRoutes.preferences: (_) => const PreferencesPage(),
  AppRoutes.stats: (_) => const AppStatsPage(),
  AppRoutes.sessionDetail: (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as AppSessionDetailArgs;
    return AppSessionsDetailPage(
      appName: args.appName,
      packageName: args.packageName,
      sessions: args.sessions,
      beginTime: args.beginTime,
      endTime: args.endTime,
      icon: args.icon,
    );
  },
};
