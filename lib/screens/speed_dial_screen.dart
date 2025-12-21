import 'package:flutter/material.dart';
import 'dart:ui';

class SpeedDialScreen extends StatefulWidget {
  const SpeedDialScreen({super.key});

  @override
  State<SpeedDialScreen> createState() => _SpeedDialScreenState();
}

class _SpeedDialScreenState extends State<SpeedDialScreen> {
  final Map<String, Map<String, dynamic>?> _speedDials = {
    '2': {'name': 'Mom', 'number': '999888777', 'color': Colors.pink},
    '3': null,
    '4': null,
    '5': {'name': 'Work', 'number': '555123456', 'color': Colors.blue},
    '6': null,
    '7': null,
    '8': null,
    '9': {'name': 'Pizza Hut', 'number': '444987654', 'color': Colors.red},
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Speed Dial'),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                // Info card
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Long press a dial key (2-9) on the keypad to quickly call the assigned contact.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
      
                // Voicemail (always 1)
                _buildSpeedDialTile(
                  context,
                  '1',
                  {'name': 'Voicemail', 'number': '123', 'color': Colors.orange},
                  isFixed: true,
                ),
                const SizedBox(height: 12),
      
                // Speed dial slots
                ..._speedDials.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSpeedDialTile(context, entry.key, entry.value),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDialTile(BuildContext context, String key, Map<String, dynamic>? contact, {bool isFixed = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasContact = contact != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(200),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasContact 
                    ? (contact['color'] as Color).withAlpha(30)
                    : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasContact 
                      ? (contact['color'] as Color).withAlpha(60)
                      : (isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10)),
                ),
              ),
              child: Center(
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: hasContact ? contact['color'] as Color : Colors.grey,
                  ),
                ),
              ),
            ),
            title: Text(
              hasContact ? contact['name'] as String : 'Not set',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: hasContact ? null : Colors.grey,
              ),
            ),
            subtitle: hasContact
                ? Text(contact['number'] as String, style: const TextStyle(fontSize: 12))
                : const Text('Tap to assign', style: TextStyle(fontSize: 12)),
            trailing: isFixed
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Fixed', style: TextStyle(fontSize: 11, color: Colors.orange)),
                  )
                : hasContact
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _speedDials[key] = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Speed dial $key cleared'), behavior: SnackBarBehavior.floating),
                          );
                        },
                      )
                    : const Icon(Icons.add, size: 20, color: Colors.grey),
            onTap: isFixed ? null : () => _showContactPicker(context, key),
          ),
        ),
      ),
    );
  }

  void _showContactPicker(BuildContext context, String key) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contacts = [
      {'name': 'Alice Johnson', 'number': '123456789', 'color': Colors.blue},
      {'name': 'Bob Smith', 'number': '987654321', 'color': Colors.purple},
      {'name': 'Mom', 'number': '999888777', 'color': Colors.pink},
      {'name': 'Work', 'number': '555123456', 'color': Colors.blue},
      {'name': 'Pizza Hut', 'number': '444987654', 'color': Colors.red},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withAlpha(220) : Colors.white.withAlpha(245),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
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
                Text('Assign to key $key', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (contact['color'] as Color).withAlpha(40),
                          child: Text(
                            (contact['name'] as String)[0],
                            style: TextStyle(color: contact['color'] as Color, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(contact['name'] as String),
                        subtitle: Text(contact['number'] as String, style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          setState(() {
                            _speedDials[key] = contact;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${contact['name']} assigned to key $key'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
