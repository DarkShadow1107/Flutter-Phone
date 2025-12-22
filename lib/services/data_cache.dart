import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

/// Singleton cache service for contacts and call logs
/// Prevents reloading data every time screens are opened
class DataCacheService {
  static final DataCacheService _instance = DataCacheService._internal();
  factory DataCacheService() => _instance;
  DataCacheService._internal();

  // Cached data
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _callLogs = [];
  Map<String, List<Map<String, dynamic>>> _groupedCallLogs = {};
  
  bool _contactsLoaded = false;
  bool _callLogsLoaded = false;
  bool _isLoadingContacts = false;
  bool _isLoadingCallLogs = false;

  // Getters
  List<Map<String, dynamic>> get contacts => _contacts;
  List<Map<String, dynamic>> get callLogs => _callLogs;
  Map<String, List<Map<String, dynamic>>> get groupedCallLogs => _groupedCallLogs;
  bool get contactsLoaded => _contactsLoaded;
  bool get callLogsLoaded => _callLogsLoaded;

  /// Load contacts if not already loaded
  Future<List<Map<String, dynamic>>> loadContacts({bool forceReload = false}) async {
    if (_contactsLoaded && !forceReload) {
      return _contacts;
    }
    
    if (_isLoadingContacts) {
      // Wait for existing load to complete
      while (_isLoadingContacts) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _contacts;
    }

    _isLoadingContacts = true;
    
    try {
      final status = await Permission.contacts.status;
      if (!status.isGranted) {
        _isLoadingContacts = false;
        return [];
      }

      final deviceContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: true,
      );
      
      final List<Map<String, dynamic>> loadedContacts = [];
      int count = 0;
      
      for (var contact in deviceContacts) {
        if (count >= 500) break;
        if (contact.phones.isNotEmpty) {
          final phone = contact.phones.first.number;
          loadedContacts.add({
            'id': contact.id,
            'name': contact.displayName.isNotEmpty ? contact.displayName : 'Unknown',
            'number': _cleanPhoneNumber(phone),
            'displayNumber': phone,
            'color': Colors.primaries[loadedContacts.length % Colors.primaries.length],
            'favorite': contact.isStarred,
            'photo': contact.thumbnail,
          });
          count++;
        }
      }
      
      _contacts = loadedContacts;
      _contactsLoaded = true;
      debugPrint('DataCache: Loaded ${_contacts.length} contacts');
    } catch (e) {
      debugPrint('DataCache: Error loading contacts: $e');
    }
    
    _isLoadingContacts = false;
    return _contacts;
  }

  /// Load call logs if not already loaded
  Future<List<Map<String, dynamic>>> loadCallLogs({bool forceReload = false}) async {
    if (_callLogsLoaded && !forceReload) {
      return _callLogs;
    }
    
    if (_isLoadingCallLogs) {
      while (_isLoadingCallLogs) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _callLogs;
    }

    _isLoadingCallLogs = true;
    
    try {
      final status = await Permission.phone.status;
      if (!status.isGranted) {
        _isLoadingCallLogs = false;
        return [];
      }

      final Iterable<CallLogEntry> entries = await CallLog.get();
      final List<Map<String, dynamic>> logs = [];

      for (var entry in entries.take(200)) {
        final String name = entry.name ?? entry.number ?? 'Unknown';
        final String number = entry.number ?? '';
        final DateTime date = DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0);
        
        String status = 'incoming';
        if (entry.callType == CallType.outgoing) status = 'outgoing';
        if (entry.callType == CallType.missed) status = 'missed';
        if (entry.callType == CallType.rejected) status = 'missed';

        logs.add({
          'name': name,
          'number': number,
          'date': date,
          'time': _formatDate(date),
          'status': status,
          'color': Colors.primaries[logs.length % Colors.primaries.length],
          'duration': entry.duration != null ? _formatDuration(entry.duration!) : null,
        });
      }
      
      _callLogs = logs;
      _groupedCallLogs = _groupCallLogs(logs);
      _callLogsLoaded = true;
      debugPrint('DataCache: Loaded ${_callLogs.length} call logs');
    } catch (e) {
      debugPrint('DataCache: Error loading call logs: $e');
    }
    
    _isLoadingCallLogs = false;
    return _callLogs;
  }

  /// Group call logs by date and contact
  Map<String, List<Map<String, dynamic>>> _groupCallLogs(List<Map<String, dynamic>> logs) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var log in logs) {
      final date = log['date'] as DateTime;
      final dateKey = _getDateKey(date);
      
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(log);
    }
    
    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return DateFormat('HH:mm').format(date);
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEE HH:mm').format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '${mins}m ${secs}s';
    }
    return '${secs}s';
  }

  String _cleanPhoneNumber(String rawNumber) {
    if (rawNumber.startsWith('+')) {
      return '+${rawNumber.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}';
    }
    return rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Refresh contacts
  Future<void> refreshContacts() async {
    await loadContacts(forceReload: true);
  }

  /// Refresh call logs
  Future<void> refreshCallLogs() async {
    await loadCallLogs(forceReload: true);
  }

  /// Clear all cached data
  void clearCache() {
    _contacts = [];
    _callLogs = [];
    _groupedCallLogs = {};
    _contactsLoaded = false;
    _callLogsLoaded = false;
  }
}

// Global instance
final dataCache = DataCacheService();
