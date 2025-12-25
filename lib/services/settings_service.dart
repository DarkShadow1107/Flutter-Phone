import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting app settings like ringtone, images, etc.
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _ringtoneKey = 'custom_ringtone_uri';
  static const String _ringtoneNameKey = 'custom_ringtone_name';
  static const String _vibrationKey = 'vibration_enabled';
  static const String _notificationStyleKey = 'notification_style';
  static const String _themeKey = 'theme_mode';

  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    debugPrint('SettingsService: Initialized');
  }

  // Ringtone settings
  Future<void> setRingtoneUri(String uri) async {
    await _ensureInitialized();
    await _prefs?.setString(_ringtoneKey, uri);
    debugPrint('SettingsService: Saved ringtone URI: $uri');
  }

  String? getRingtoneUri() {
    return _prefs?.getString(_ringtoneKey);
  }

  Future<void> setRingtoneName(String name) async {
    await _ensureInitialized();
    await _prefs?.setString(_ringtoneNameKey, name);
  }

  String? getRingtoneName() {
    return _prefs?.getString(_ringtoneNameKey);
  }

  Future<void> clearRingtone() async {
    await _ensureInitialized();
    await _prefs?.remove(_ringtoneKey);
    await _prefs?.remove(_ringtoneNameKey);
  }

  // Vibration settings
  Future<void> setVibrationEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs?.setBool(_vibrationKey, enabled);
  }

  bool getVibrationEnabled() {
    return _prefs?.getBool(_vibrationKey) ?? true;
  }

  // Notification style (fullscreen vs heads-up)
  Future<void> setNotificationStyle(String style) async {
    await _ensureInitialized();
    await _prefs?.setString(_notificationStyleKey, style);
  }

  String getNotificationStyle() {
    return _prefs?.getString(_notificationStyleKey) ?? 'auto';
  }

  // Theme mode
  Future<void> setThemeMode(String mode) async {
    await _ensureInitialized();
    await _prefs?.setString(_themeKey, mode);
  }

  String getThemeMode() {
    return _prefs?.getString(_themeKey) ?? 'system';
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}

// Global instance
final settingsService = SettingsService();
