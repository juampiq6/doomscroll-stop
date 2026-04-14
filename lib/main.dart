import 'package:doomscroll_stop/app.dart';
import 'package:doomscroll_stop/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  configureDependencies();
  runApp(const ProviderScope(child: DoomscrollApp()));
}
