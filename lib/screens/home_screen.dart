import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:permission_handler/permission_handler.dart';
import 'keypad_screen.dart';
import 'recents_screen.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';
import 'call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final List<String> _titles = ['Phone', 'Recents', 'Contacts', 'Settings'];
  static const platform = MethodChannel('com.example.flutter_phone/dialer');
  bool _isDefaultDialer = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDefaultDialer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDefaultDialer();
    }
  }

  Future<void> _checkDefaultDialer() async {
    try {
      final bool isDefault = await platform.invokeMethod('checkDefaultDialer');
      if (mounted) {
        setState(() {
          _isDefaultDialer = isDefault;
        });
        if (!isDefault) {
          _showDefaultDialerPrompt();
        }
      }
      debugPrint('Is default dialer: $isDefault');
    } catch (e) {
      debugPrint("Error checking default dialer: $e");
    }
  }

  void _showDefaultDialerPrompt() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Set Flutter Phone as your default dialer?'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'SET AS DEFAULT',
            onPressed: () async {
              try {
                await platform.invokeMethod('requestDefaultDialer');
                // Recheck after user action
                await Future.delayed(const Duration(seconds: 1));
                _checkDefaultDialer();
              } catch (e) {
                debugPrint("Error requesting default dialer: $e");
              }
            },
          ),
        ),
      );
    });
  }

  Future<void> _requestPermissions() async {
    // Request critical permissions first
    final criticalPermissions = [
      Permission.phone,
      Permission.contacts,
    ];

    for (var permission in criticalPermissions) {
      final status = await permission.request();
      debugPrint('Permission ${permission.toString()}: $status');
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Then request other permissions
    final otherPermissions = [
      Permission.microphone,
      Permission.camera,
      Permission.notification,
    ];

    for (var permission in otherPermissions) {
      await permission.request();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _onTabChanged(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _makeCall(String number) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CallScreen(
          name: number,
          number: number,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Global Background Gradient for Glassmorphism
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        const Color(0xFF121212),
                        const Color(0xFF1E1E24),
                        const Color(0xFF121212),
                      ]
                    : [
                        const Color(0xFFF5F5F7),
                        const Color(0xFFE8E8ED),
                        const Color(0xFFF5F5F7),
                      ],
              ),
            ),
          ),
          
          // Subtle ambient orbs for depth
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha(30),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withAlpha(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha(20),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Glass Blur Overlay for background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                if (_selectedIndex != 0)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Text(
                      _titles[_selectedIndex],
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  const SizedBox(height: 16),

                // Content with animation
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: IndexedStack(
                      key: ValueKey(_selectedIndex),
                      index: _selectedIndex,
                      children: [
                        KeypadScreen(onCall: _makeCall),
                        const RecentsScreen(),
                        ContactsScreen(onCall: _makeCall),
                        const SettingsScreen(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_isDefaultDialer)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.amber.withAlpha(200),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.black87),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'App is not set as default dialer',
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                          ),
                        ),
                        TextButton(
                          onPressed: () => platform.invokeMethod('requestDefaultDialer'),
                          child: const Text('SET', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // FAB removed to avoid duplicates using child screens' own buttons
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withAlpha(180)
                  : Colors.white.withAlpha(200),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withAlpha(15)
                      : Colors.black.withAlpha(8),
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onTabChanged,
              height: 70,
              elevation: 0,
              backgroundColor: Colors.transparent,
              indicatorColor: Theme.of(context).colorScheme.primary.withAlpha(40),
              animationDuration: const Duration(milliseconds: 200),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dialpad_outlined),
                  selectedIcon: Icon(Icons.dialpad),
                  label: 'Keypad',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'Recents',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Contacts',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
