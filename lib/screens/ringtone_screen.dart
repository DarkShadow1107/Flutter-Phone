import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class RingtoneScreen extends StatefulWidget {
  const RingtoneScreen({super.key});

  @override
  State<RingtoneScreen> createState() => _RingtoneScreenState();
}

class _RingtoneScreenState extends State<RingtoneScreen> {
  String _selectedRingtone = 'Default (Pixel Sound)';
  final List<String> _systemRingtones = [
    'Default (Pixel Sound)',
    'Cosmic',
    'Chimes',
    'Digital Phone',
    'Classic Ring',
    'Flutter Tune',
  ];

    Future<void> _pickCustomRingtone() async {
    // Request permissions based on Android version
    bool granted = false;
    
    // Try Audio permission (Android 13+)
    var status = await Permission.audio.request();
    if (status.isGranted) {
      granted = true;
    } else {
      // Fallback for older Android (Storage)
      var storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        granted = true;
      }
    }

    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage/Audio permission denied'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
    );

    if (result != null) {
      if (!mounted) return;
      setState(() {
        _systemRingtones.add(result.files.single.name);
        _selectedRingtone = result.files.single.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ringtone imported successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Phone Ringtone'),
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
            onPressed: _pickCustomRingtone,
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
           Positioned(bottom: -50, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple.withAlpha(15), boxShadow: [BoxShadow(color: Colors.purple.withAlpha(20), blurRadius: 100, spreadRadius: 20)]))),
           
           // Blur Overlay
           Positioned.fill(
             child: BackdropFilter(
               filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
               child: Container(color: Colors.transparent),
             ),
           ),
          
          // Content
          SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _systemRingtones.length,
              itemBuilder: (context, index) {
                final ringtone = _systemRingtones[index];
                final isSelected = ringtone == _selectedRingtone;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary.withAlpha(30)
                              : (isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(180)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withAlpha(100)
                                : (isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(6)),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: RadioListTile<String>(
                          value: ringtone,
                          groupValue: _selectedRingtone,
                          onChanged: (value) {
                            setState(() => _selectedRingtone = value!);
                          },
                          title: Text(
                            ringtone,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          activeColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
}
