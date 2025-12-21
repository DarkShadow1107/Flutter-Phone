import 'package:flutter/material.dart';
import 'dart:ui';
import 'speed_dial_screen.dart';
import 'blocked_numbers_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_feedback_screen.dart';
import 'ringtone_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _swipeEnabled = true;
  bool _hapticEnabled = true;
  bool _showCallerId = true;
  bool _callRecording = false;
  bool _spamProtection = true;
  String _defaultApp = 'Phone';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildSection(context, 'Call Settings', [
          _buildGlassTile(
            context,
            icon: Icons.swipe_outlined,
            title: 'Swipe to call/message',
            subtitle: 'Swipe contacts to quickly act',
            trailing: Switch(
              value: _swipeEnabled,
              onChanged: (v) => setState(() => _swipeEnabled = v),
            ),
          ),
          _buildGlassTile(
            context,
            icon: Icons.vibration,
            title: 'Haptic feedback',
            subtitle: 'Vibrate on keypad touch',
            trailing: Switch(
              value: _hapticEnabled,
              onChanged: (v) => setState(() => _hapticEnabled = v),
            ),
          ),
          _buildGlassTile(
            context,
            icon: Icons.perm_identity,
            title: 'Show caller ID',
            subtitle: 'Display your number to recipients',
            trailing: Switch(
              value: _showCallerId,
              onChanged: (v) => setState(() => _showCallerId = v),
            ),
          ),
          _buildGlassTile(
            context,
            icon: Icons.fiber_manual_record,
            title: 'Call recording',
            subtitle: 'Automatically record calls',
            trailing: Switch(
              value: _callRecording,
              onChanged: (v) => setState(() => _callRecording = v),
            ),
          ),
        ]),

        _buildSection(context, 'Default Apps', [
          _buildGlassTile(
            context,
            icon: Icons.phone_android,
            title: 'Default calling app',
            subtitle: _defaultApp,
            onTap: () => _showAppPicker(context),
          ),
        ]),

        _buildSection(context, 'Speed Dial', [
          _buildGlassTile(
            context,
            icon: Icons.speed,
            title: 'Manage speed dial',
            subtitle: 'Configure long-press shortcuts',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const SpeedDialScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
        ]),

        _buildSection(context, 'Privacy', [
          _buildGlassTile(
            context,
            icon: Icons.block,
            title: 'Blocked numbers',
            subtitle: 'Manage blocked callers',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const BlockedNumbersScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
          _buildGlassTile(
            context,
            icon: Icons.report_outlined,
            title: 'Spam protection',
            subtitle: _spamProtection ? 'Filtering enabled' : 'Disabled',
            trailing: Switch(
              value: _spamProtection,
              onChanged: (v) => setState(() => _spamProtection = v),
            ),
          ),
        ]),

        _buildSection(context, 'Sound & Vibration', [
          _buildGlassTile(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Ringtone',
            subtitle: 'Default (Pixel Sound)',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const RingtoneScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
          _buildGlassTile(
            context,
            icon: Icons.volume_up_outlined,
            title: 'Dial pad tones',
            trailing: Switch(
              value: true,
              onChanged: (v) {},
            ),
          ),
        ]),

        _buildSection(context, 'About', [
          _buildGlassTile(
            context,
            icon: Icons.info_outline,
            title: 'App version',
            subtitle: '1.2.8 (Stable)',
          ),
          _buildGlassTile(
            context,
            icon: Icons.help_outline,
            title: 'Help & Feedback',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const HelpFeedbackScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
          _buildGlassTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy policy',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const PrivacyPolicyScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
        ]),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 20, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: child,
        )),
      ],
    );
  }

  Widget _buildGlassTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(8) : Colors.white.withAlpha(180),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(6),
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: subtitle != null 
                ? Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)) 
                : null,
            trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right, size: 20, color: isDark ? Colors.white38 : Colors.black38) : null),
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  void _showAppPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(40), // Very subtle dimming to keep background visible
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Match navbar blur
          child: Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withAlpha(180) // Match navbar opacity
                  : Colors.white.withAlpha(200),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Choose default app', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: const Text('Phone System'),
                  trailing: _defaultApp == 'Phone' ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () {
                    setState(() => _defaultApp = 'Phone');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_android, color: Colors.green),
                  ),
                  title: const Text('WhatsApp'),
                  trailing: _defaultApp == 'WhatsApp' ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () {
                    setState(() => _defaultApp = 'WhatsApp');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
