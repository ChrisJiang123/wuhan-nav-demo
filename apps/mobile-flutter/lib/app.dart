import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/map/presentation/map_page.dart';

class WuhanNavApp extends StatelessWidget {
  const WuhanNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '武汉导航 Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MapPage(),
    );
  }
}
