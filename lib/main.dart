import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'screens/home_screen.dart';
import 'screens/call_screen.dart';
import 'theme/app_theme.dart';
import 'services/call_service.dart';
import 'services/data_cache.dart';

import 'services/settings_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await settingsService.initialize();
  callService.initialize();
  
  // Set high refresh rate (120Hz+) if supported
  try {
    final modes = await FlutterDisplayMode.supported;
    debugPrint('Supported display modes: $modes');
    
    // Find highest refresh rate mode
    if (modes.isNotEmpty) {
      final highestMode = modes.reduce((curr, next) => curr.refreshRate > next.refreshRate ? curr : next);
      debugPrint('Setting highest refresh rate: ${highestMode.refreshRate}Hz');
      await FlutterDisplayMode.setPreferredMode(highestMode);
    } else {
      await FlutterDisplayMode.setHighRefreshRate();
    }
  } catch (e) {
    debugPrint("High refresh rate not supported: $e");
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make status bar transparent for edge-to-edge design
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _incomingCallSubscription;
  String? _currentIncomingNumber;
  bool _isShowingIncomingCall = false;

  @override
  void initState() {
    super.initState();
    _listenForIncomingCalls();
  }

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    super.dispose();
  }

  void _listenForIncomingCalls() {
    _incomingCallSubscription = callService.onIncomingCall.listen((callInfo) {
      if (!mounted) return;
      debugPrint('MyApp: Received incoming call from ${callInfo.number}');
      
      // Prevent duplicate screens for same number
      if (_isShowingIncomingCall) {
        debugPrint('MyApp: Already showing incoming call screen, ignoring');
        return;
      }
      
      _currentIncomingNumber = callInfo.number;
      _isShowingIncomingCall = true;
      
      // Lookup contact name from cache
      String displayName = callInfo.name;
      Color? contactColor;
      if (displayName.isEmpty) {
        final contact = dataCache.findContact(callInfo.number);
        if (contact != null) {
          displayName = contact['name'] as String? ?? callInfo.number;
          contactColor = contact['color'] as Color?;
        } else {
          displayName = callInfo.number;
        }
      }
      
      debugPrint('MyApp: Showing call from $displayName');
      
      // Navigate to call screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => CallScreen(
              name: displayName,
              number: callInfo.number,
              isIncoming: true,
              contactColor: contactColor,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 100),
          ),
        ).then((_) {
          // Reset when screen is popped
          _isShowingIncomingCall = false;
          _currentIncomingNumber = null;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Phone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
