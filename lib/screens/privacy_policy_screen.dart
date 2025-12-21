import 'package:flutter/material.dart';
import 'dart:ui';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF121212), const Color(0xFF1E1E24)]
                    : [const Color(0xFFF5F5F7), const Color(0xFFE8E8ED)],
              ),
            ),
          ),
          
           // Orbs
           Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary.withAlpha(20), boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withAlpha(30), blurRadius: 100, spreadRadius: 20)]))),
           Positioned(bottom: -50, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withAlpha(15), boxShadow: [BoxShadow(color: Colors.blue.withAlpha(20), blurRadius: 100, spreadRadius: 20)]))),
           
           // Blur Overlay
           Positioned.fill(
             child: BackdropFilter(
               filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
               child: Container(color: Colors.transparent),
             ),
           ),
          
          // Content
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
              children: [
                _buildGlassCard(
                  context,
                  title: 'Data Collection',
                  content: 'We collect minimal data necessary to function as a phone app. This includes your contact list names and numbers solely for display and calling purposes within the app. No data is sent to external servers.',
                  icon: Icons.data_usage,
                ),
                const SizedBox(height: 16),
                _buildGlassCard(
                  context,
                  title: 'Permissions',
                  content: 'The app requires access to Contacts to display them, and Phone permissions to initiate calls. SMS permission is used to launch your default messaging app.',
                  icon: Icons.security,
                ),
                const SizedBox(height: 16),
                _buildGlassCard(
                  context,
                  title: 'Local Storage',
                  content: 'Speed dial configurations and local settings are stored on your device securely. We do not track your location or share your personal information.',
                  icon: Icons.storage,
                ),
                const SizedBox(height: 16),
                _buildGlassCard(
                  context,
                  title: 'Updates',
                  content: 'Policy updates will be reflected in future versions of the application. By using this app, you agree to the terms outlined here.',
                  icon: Icons.update,
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Last updated: 18 December 2025',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required String title, required String content, required IconData icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(180),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 20 : 5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
