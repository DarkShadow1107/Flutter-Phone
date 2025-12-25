import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static const MethodChannel _channel = MethodChannel('com.example.flutter_phone/whatsapp');
  
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  /// Check if WhatsApp is installed on the device
  Future<bool> isWhatsAppInstalled() async {
    try {
      final Uri whatsappUri = Uri.parse('whatsapp://send?phone=0');
      return await canLaunchUrl(whatsappUri);
    } catch (e) {
      return false;
    }
  }

  /// Check if a phone number is likely on WhatsApp
  /// Note: This is a heuristic check - we verify WhatsApp is installed
  /// and the number format is valid for WhatsApp
  Future<bool> isNumberOnWhatsApp(String phoneNumber) async {
    if (!await isWhatsAppInstalled()) {
      return false;
    }
    
    // Clean the phone number
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // WhatsApp requires numbers with country code
    // If number starts with 0, it's likely a local number without country code
    // We can still try to open WhatsApp, but success isn't guaranteed
    if (cleanNumber.isEmpty) {
      return false;
    }
    
    // Check if the number format is valid for WhatsApp (has country code)
    // Numbers starting with + are international format
    // Numbers with 10+ digits might have country code
    return cleanNumber.startsWith('+') || cleanNumber.length >= 10;
  }

  /// Open WhatsApp chat with the given number
  Future<bool> openChat(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
    
    try {
      return await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      return false;
    }
  }

  /// Open WhatsApp voice call with the given number
  Future<bool> openVoiceCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri whatsappCallUri = Uri.parse('whatsapp://call?phone=$cleanNumber');
    final Uri fallbackUri = Uri.parse('https://wa.me/$cleanNumber');
    
    try {
      if (await canLaunchUrl(whatsappCallUri)) {
        return await launchUrl(whatsappCallUri);
      } else {
        return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      return false;
    }
  }

  /// Open WhatsApp video call with the given number
  Future<bool> openVideoCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri whatsappVideoUri = Uri.parse('whatsapp://videocall?phone=$cleanNumber');
    final Uri fallbackUri = Uri.parse('https://wa.me/$cleanNumber?video=true');
    
    try {
      if (await canLaunchUrl(whatsappVideoUri)) {
        return await launchUrl(whatsappVideoUri);
      } else {
        return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      return false;
    }
  }
}

final whatsAppService = WhatsAppService();
