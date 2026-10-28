import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    required AppController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this context');
    return scope!.notifier!;
  }
}

class AksharamalaApp extends StatefulWidget {
  const AksharamalaApp({super.key, this.controller});

  final AppController? controller;

  @override
  State<AksharamalaApp> createState() => _AksharamalaAppState();
}

class _AksharamalaAppState extends State<AksharamalaApp> {
  late final AppController controller = widget.controller ?? AppController();

  @override
  void initState() {
    super.initState();
    controller.initialise();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
        controller: controller,
        child: MaterialApp(
          title: 'Aksharamala',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: const SplashScreen(),
        ),
      );
}

