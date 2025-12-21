import 'package:flutter/material.dart';
import 'dart:ui';

class BlockedNumbersScreen extends StatefulWidget {
  const BlockedNumbersScreen({super.key});

  @override
  State<BlockedNumbersScreen> createState() => _BlockedNumbersScreenState();
}

class _BlockedNumbersScreenState extends State<BlockedNumbersScreen> {
  final List<Map<String, dynamic>> _blockedNumbers = [
    {'number': '+1 555 123 4567', 'name': 'Spam Caller', 'date': 'Dec 15'},
    {'number': '+1 800 999 8888', 'name': null, 'date': 'Dec 10'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Blocked Numbers'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                  child: const Icon(Icons.add, size: 20),
                ),
              ),
            ),
            onPressed: _showAddBlockDialog,
          ),
          const SizedBox(width: 8),
        ],
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
            child: _blockedNumbers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                      const SizedBox(height: 16),
                      Text('No blocked numbers', style: TextStyle(fontSize: 18, color: isDark ? Colors.white60 : Colors.black54)),
                      const SizedBox(height: 8),
                      Text('Tap + to block a number', style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blockedNumbers.length,
                  itemBuilder: (context, index) {
                    final item = _blockedNumbers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(180),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(30),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.red.withAlpha(50)),
                                ),
                                child: const Icon(Icons.block, color: Colors.red),
                              ),
                              title: Text(
                                item['name'] ?? item['number'],
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                item['name'] != null ? item['number'] : 'Blocked ${item['date']}',
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.close, size: 20, color: isDark ? Colors.white38 : Colors.black38),
                                onPressed: () {
                                  setState(() {
                                    _blockedNumbers.removeAt(index);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${item['number']} unblocked'),
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () {
                                          setState(() {
                                            _blockedNumbers.insert(index, item);
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  void _showAddBlockDialog() {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withAlpha(220) : Colors.white.withAlpha(245),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(100),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Block a number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          setState(() {
                            _blockedNumbers.add({
                              'number': controller.text,
                              'name': null,
                              'date': 'Today',
                            });
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${controller.text} blocked'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Block Number'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
