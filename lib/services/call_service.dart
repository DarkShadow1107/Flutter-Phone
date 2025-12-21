import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum NativeCallState {
  idle,
  dialing,
  ringing,
  active,
  disconnected,
  connecting,
  holding,
}

class IncomingCallInfo {
  final String number;
  final String name;

  IncomingCallInfo({required this.number, required this.name});
}

class CallService {
  static const MethodChannel _callChannel = MethodChannel('com.example.flutter_phone/calls');
  static const EventChannel _callEvents = EventChannel('com.example.flutter_phone/call_events');
  
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final StreamController<IncomingCallInfo> _incomingCallController = 
      StreamController<IncomingCallInfo>.broadcast();
  final StreamController<NativeCallState> _callStateController = 
      StreamController<NativeCallState>.broadcast();

  Stream<IncomingCallInfo> get onIncomingCall => _incomingCallController.stream;
  Stream<NativeCallState> get onCallStateChanged => _callStateController.stream;

  NativeCallState _currentState = NativeCallState.idle;
  NativeCallState get currentState => _currentState;

  StreamSubscription? _eventSubscription;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Listen for method channel calls FROM native
    _callChannel.setMethodCallHandler((call) async {
      if (call.method == 'incomingCall') {
        final args = call.arguments as Map<dynamic, dynamic>;
        final info = IncomingCallInfo(
          number: args['number'] as String? ?? 'Unknown',
          name: args['name'] as String? ?? '',
        );
        _incomingCallController.add(info);
        debugPrint('CallService: Incoming call from ${info.number}');
      }
      return null;
    });

    // Listen for event channel stream
    _eventSubscription = _callEvents.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final eventType = event['event'] as String?;
          final state = event['state'] as String?;
          
          if (eventType == 'incoming') {
            final info = IncomingCallInfo(
              number: event['number'] as String? ?? 'Unknown',
              name: event['name'] as String? ?? '',
            );
            _incomingCallController.add(info);
          }
          
          if (state != null) {
            _currentState = _parseState(state);
            _callStateController.add(_currentState);
            debugPrint('CallService: State changed to $_currentState');
          }
        }
      },
      onError: (error) {
        debugPrint('CallService: Event stream error: $error');
      },
    );

    debugPrint('CallService: Initialized');
  }

  NativeCallState _parseState(String state) {
    switch (state) {
      case 'dialing':
        return NativeCallState.dialing;
      case 'ringing':
        return NativeCallState.ringing;
      case 'active':
        return NativeCallState.active;
      case 'disconnected':
        return NativeCallState.disconnected;
      case 'connecting':
        return NativeCallState.connecting;
      case 'holding':
        return NativeCallState.holding;
      default:
        return NativeCallState.idle;
    }
  }

  Future<bool> answerCall() async {
    try {
      final result = await _callChannel.invokeMethod<bool>('answerCall');
      return result ?? false;
    } catch (e) {
      debugPrint('CallService: Error answering call: $e');
      return false;
    }
  }

  Future<bool> rejectCall() async {
    try {
      final result = await _callChannel.invokeMethod<bool>('rejectCall');
      return result ?? false;
    } catch (e) {
      debugPrint('CallService: Error rejecting call: $e');
      return false;
    }
  }

  Future<bool> endCall() async {
    try {
      final result = await _callChannel.invokeMethod<bool>('endCall');
      return result ?? false;
    } catch (e) {
      debugPrint('CallService: Error ending call: $e');
      return false;
    }
  }

  Future<bool> makeCall(String number) async {
    try {
      final result = await _callChannel.invokeMethod<bool>('makeCall', {'number': number});
      return result ?? false;
    } catch (e) {
      debugPrint('CallService: Error making call: $e');
      return false;
    }
  }

  Future<bool> sendDtmf(String digit) async {
    try {
      final result = await _callChannel.invokeMethod<bool>('sendDtmf', {'digit': digit});
      return result ?? false;
    } catch (e) {
      debugPrint('CallService: Error sending DTMF: $e');
      return false;
    }
  }

  Future<bool> hasActiveCall() async {
    try {
      final result = await _callChannel.invokeMethod<bool>('hasActiveCall');
      return result ?? false;
    } catch (e) {
      debugPrint('CallService: Error checking active call: $e');
      return false;
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _incomingCallController.close();
    _callStateController.close();
  }
}

// Global instance
final callService = CallService();
