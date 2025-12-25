import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/settings_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  void _loadSavedSettings() {
    final savedName = settingsService.getRingtoneName();
    if (savedName != null) {
      setState(() {
        if (!_systemRingtones.contains(savedName)) {
          _systemRingtones.add(savedName);
        }
        _selectedRingtone = savedName;
      });
    }
  }

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
      final path = result.files.single.path;
      final name = result.files.single.name;
      
      if (path != null && mounted) {
        setState(() {
          if (!_systemRingtones.contains(name)) {
            _systemRingtones.add(name);
          }
          _selectedRingtone = name;
        });
        
        // Persist setting
        await settingsService.setRingtoneUri(path);
        await settingsService.setRingtoneName(name);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ringtone imported and saved')),
        );
      }
    }
  }

  Future<void> _deleteRingtone(String name) async {
    setState(() {
      _systemRingtones.remove(name);
      if (_selectedRingtone == name) {
        _selectedRingtone = 'Default (Pixel Sound)';
        settingsService.clearRingtone();
      }
    });
    
    // If it was a custom ringtone, we also want to forget the path
    // For now we only support one custom ringtone in settingsService, 
    // so clearing it is correct if that's the one we're deleting.
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ringtone "$name" removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Phone Ringtone'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, size: 20),
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
          
          // Orbs - Simplified for performance
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withAlpha(15)))),
          Positioned(bottom: -50, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple.withAlpha(10)))),
          
          // Content
          SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _systemRingtones.length,
              itemBuilder: (context, index) {
                final ringtone = _systemRingtones[index];
                final isSelected = ringtone == _selectedRingtone;
                final isDefault = index < 6; // First 6 are internal defaults
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? primaryColor.withAlpha(isSelected ? 40 : 10)
                          : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor.withAlpha(150)
                            : (isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(6)),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isSelected ? 40 : 10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: RadioListTile<String>(
                      value: ringtone,
                      groupValue: _selectedRingtone,
                      onChanged: (String? value) async {
                        if (value != null) {
                          setState(() => _selectedRingtone = value);
                          if (isDefault) {
                            await settingsService.clearRingtone();
                            await settingsService.setRingtoneName(value);
                          }
                        }
                      },
                      title: Text(
                        ringtone,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      secondary: !isDefault ? IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => _deleteRingtone(ringtone),
                        tooltip: 'Delete custom ringtone',
                      ) : null,
                      activeColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
