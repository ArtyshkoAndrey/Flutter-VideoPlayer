import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player_lent/screens/auth/Cameras/VideoCameraScreen.dart';

/// The route configuration.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const VideoCameraScreen(url: 'https://flussonic.com/path/index.m3u8'),
      ),
    ],
  );
}