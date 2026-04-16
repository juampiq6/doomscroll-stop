import 'package:doomscroll_stop/routes.dart';
import 'package:flutter/material.dart';

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
      initialRoute: AppRoutes.home,
      routes: appRoutes,
    );
  }
}
