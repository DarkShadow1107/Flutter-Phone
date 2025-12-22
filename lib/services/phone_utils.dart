import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'call_service.dart';

/// Utility class for phone-related operations
class PhoneUtils {
  
  /// Cleans a phone number by removing all non-numeric characters except +
  /// Example: "(555) 123-4567" -> "5551234567"
  /// Example: "+40 123 456 789" -> "+40123456789"
  static String cleanPhoneNumber(String rawNumber) {
    // Keep + at start for international numbers, remove everything else that's not a digit
    if (rawNumber.startsWith('+')) {
      return '+${rawNumber.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}';
    }
    return rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Opens the system dialer with the given number (doesn't place call)
  static Future<bool> openDialer(String phoneNumber) async {
    final cleanNumber = cleanPhoneNumber(phoneNumber);
    final Uri dialUri = Uri(scheme: 'tel', path: cleanNumber);
    
    debugPrint('PhoneUtils: Opening dialer for $cleanNumber');
    
    try {
      if (await canLaunchUrl(dialUri)) {
        await launchUrl(dialUri);
        return true;
      } else {
        debugPrint('PhoneUtils: Cannot launch dialer');
        return false;
      }
    } catch (e) {
      debugPrint('PhoneUtils: Error opening dialer: $e');
      return false;
    }
  }

  /// Places a call directly using native TelecomManager (when app is default dialer)
  /// Falls back to system dialer if not default
  static Future<bool> makeCall(String phoneNumber) async {
    final cleanNumber = cleanPhoneNumber(phoneNumber);
    
    debugPrint('PhoneUtils: Making call to $cleanNumber');
    
    try {
      // Try native call service first (works when we're default dialer)
      final result = await callService.makeCall(cleanNumber);
      if (result) {
        debugPrint('PhoneUtils: Call initiated via native service');
        return true;
      }
    } catch (e) {
      debugPrint('PhoneUtils: Native call failed: $e');
    }
    
    // Fallback to ACTION_CALL intent
    try {
      final Uri callUri = Uri(scheme: 'tel', path: cleanNumber);
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('PhoneUtils: ACTION_CALL failed: $e');
    }
    
    // Last resort: open dialer
    return openDialer(cleanNumber);
  }

  /// Sends an SMS to the given number
  static Future<bool> sendSms(String phoneNumber, {String? body}) async {
    final cleanNumber = cleanPhoneNumber(phoneNumber);
    
    Uri smsUri;
    if (body != null && body.isNotEmpty) {
      smsUri = Uri(scheme: 'sms', path: cleanNumber, queryParameters: {'body': body});
    } else {
      smsUri = Uri(scheme: 'sms', path: cleanNumber);
    }
    
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
    } catch (e) {
      debugPrint('PhoneUtils: Error sending SMS: $e');
    }
    return false;
  }

  /// Formats a phone number for display (adds spaces for readability)
  static String formatForDisplay(String phoneNumber) {
    final clean = cleanPhoneNumber(phoneNumber);
    
    // Romanian format: +40 XXX XXX XXX
    if (clean.startsWith('+40') && clean.length == 12) {
      return '${clean.substring(0, 3)} ${clean.substring(3, 6)} ${clean.substring(6, 9)} ${clean.substring(9)}';
    }
    
    // US format: (XXX) XXX-XXXX
    if (clean.length == 10 && !clean.startsWith('+')) {
      return '(${clean.substring(0, 3)}) ${clean.substring(3, 6)}-${clean.substring(6)}';
    }
    
    // Generic international
    if (clean.startsWith('+') && clean.length > 10) {
      return '${clean.substring(0, 3)} ${clean.substring(3, 6)} ${clean.substring(6, 9)} ${clean.substring(9)}';
    }
    
    return phoneNumber; // Return original if no format matches
  }
}
