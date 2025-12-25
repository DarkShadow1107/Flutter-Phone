import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'call_end_screen.dart';
import '../services/call_service.dart';

enum CallState { dialing, ringing, connected, ended }

class CallScreen extends StatefulWidget {
  final String name;
  final String number;
  final Color? contactColor;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.name,
    required this.number,
    this.contactColor,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isOnHold = false;
  bool _isRecording = false;
  bool _showKeypad = false;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _entranceController;
  late AnimationController _colorController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _entranceAnimation;
  String _dtmfInput = '';
  int _callSeconds = 0;
  CallState _callState = CallState.dialing;

  Color get _baseColor => widget.contactColor ?? Colors.blue;

  @override
  void initState() {
    super.initState();
    
    // Set initial state based on incoming/outgoing
    _callState = widget.isIncoming ? CallState.ringing : CallState.dialing;
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _colorController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    // Listen to native call state changes
    _callStateSubscription = callService.onCallStateChanged.listen((state) {
      debugPrint('CallScreen: Native call state changed to $state');
      
      if (state == NativeCallState.disconnected) {
        // Remote party hung up - close this screen
        debugPrint('CallScreen: Call disconnected by remote, closing');
        if (mounted) {
          _endCall();
        }
      } else if (state == NativeCallState.active && _callState != CallState.connected) {
        // Call became active (answered)
        if (mounted) {
          setState(() => _callState = CallState.connected);
        }
      }
    });

    // Simulate call state transitions for outgoing calls
    if (!widget.isIncoming) {
      _simulateCallProgress();
    }

    // Call timer - only runs when connected
    _startCallTimer();
  }

  StreamSubscription? _callStateSubscription;

  void _simulateCallProgress() async {
    // Dialing phase
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _callState = CallState.ringing);
    
    // Ringing phase (simulate answer after a few seconds for demo)
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _callState = CallState.connected);
  }

  void _startCallTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _callState == CallState.connected) {
        setState(() => _callSeconds++);
        return true;
      }
      return mounted;
    });
  }

  void _answerCall() async {
    // Answer via native call service
    if (widget.isIncoming) {
      await callService.answerCall();
    }
    setState(() => _callState = CallState.connected);
  }

  @override
  void dispose() {
    _callStateSubscription?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _entranceController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _toggleKeypad() {
    setState(() {
      _showKeypad = !_showKeypad;
    });
  }

  void _addDTMF(String digit) {
    setState(() {
      _dtmfInput += digit;
    });
    // Send DTMF tone via native
    callService.sendDtmf(digit);
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getCallStatusText() {
    if (_isOnHold) return '⏸ On Hold';
    switch (_callState) {
      case CallState.dialing:
        return '📞 Calling...';
      case CallState.ringing:
        return '🔔 Ringing...';
      case CallState.connected:
        return _formatDuration(_callSeconds);
      case CallState.ended:
        return 'Call Ended';
    }
  }

  void _endCall() async {
    final duration = Duration(seconds: _callSeconds);
    final navigator = Navigator.of(context);
    final name = widget.name;
    final number = widget.number;
    
    // End via native call service
    await callService.endCall();
    
    if (!mounted) return;
    
    navigator.pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CallEndScreen(
          name: name,
          number: number,
          callDuration: duration,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _colorController,
        builder: (context, child) {
          // Dynamic gradient based on contact color
          final hue = HSLColor.fromColor(_baseColor).hue;
          final animatedHue = (hue + (_colorController.value * 30)) % 360;
          final color1 = HSLColor.fromAHSL(1.0, animatedHue, 0.7, 0.25).toColor();
          final color2 = HSLColor.fromAHSL(1.0, (animatedHue + 20) % 360, 0.8, 0.15).toColor();
          
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color1,
                  color2,
                  const Color(0xFF0A0A0A),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Dynamic particle/wave background
              ...List.generate(4, (index) {
                return AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: CustomPaint(
                        painter: DynamicWavePainter(
                          animationValue: _waveController.value,
                          waveIndex: index,
                          baseColor: _baseColor,
                        ),
                      ),
                    );
                  },
                );
              }),

              // Floating particles
              ...List.generate(8, (index) {
                return AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    final progress = (_waveController.value + index * 0.125) % 1.0;
                    final x = (math.sin(progress * math.pi * 2 + index) * 0.3 + 0.5) * MediaQuery.of(context).size.width;
                    final y = progress * MediaQuery.of(context).size.height;
                    final opacity = math.sin(progress * math.pi) * 0.3;
                    
                    return Positioned(
                      left: x,
                      top: y,
                      child: Container(
                        width: 4 + index * 0.5,
                        height: 4 + index * 0.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _baseColor.withAlpha((opacity * 255).toInt()),
                        ),
                      ),
                    );
                  },
                );
              }),
              
              // Main content
              FadeTransition(
                opacity: _entranceAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(_entranceAnimation),
                  child: Column(
                    children: [
                      SizedBox(height: _showKeypad ? 20 : 40),
                      // Pulsing avatar with glow
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _showKeypad ? 80 : 110,
                              height: _showKeypad ? 80 : 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _baseColor.withAlpha(30),
                                border: Border.all(color: _baseColor.withAlpha(80), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _baseColor.withAlpha(60),
                                    blurRadius: 40,
                                    spreadRadius: 15,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  widget.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Call status/timer
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          key: ValueKey(_isOnHold ? 'hold' : '${_callState}_$_callSeconds'),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isOnHold 
                                ? Colors.amber.withAlpha(30) 
                                : _callState == CallState.connected 
                                    ? Colors.white.withAlpha(15)
                                    : Colors.green.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getCallStatusText(),
                            style: TextStyle(
                              color: _isOnHold 
                                  ? Colors.amber 
                                  : _callState == CallState.connected 
                                      ? Colors.white.withAlpha(200)
                                      : Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.number,
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 16,
                        ),
                      ),
                      if (_dtmfInput.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _dtmfInput,
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontSize: 22,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      
                      // Keypad or Controls
                      if (_callState == CallState.connected || _showKeypad)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _showKeypad
                              ? _buildInCallKeypad()
                              : _buildCallControls(),
                        ),
                      
                      SizedBox(height: _showKeypad ? 10 : (_callState == CallState.connected ? 40 : 0)),
                      
                      // Incoming call buttons OR End Call Button
                      if (widget.isIncoming && _callState == CallState.ringing)
                        _buildIncomingCallButtons()
                      else
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(scale: value, child: child);
                          },
                          child: GestureDetector(
                            onTap: _endCall,
                            child: Container(
                              width: _showKeypad ? 64 : 76,
                              height: _showKeypad ? 64 : 76,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withAlpha(120),
                                    blurRadius: 30,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(Icons.call_end, color: Colors.white, size: _showKeypad ? 28 : 34),
                            ),
                          ),
                        ),
                      SizedBox(height: _showKeypad ? 20 : 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Padding(
      key: const ValueKey('controls'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCallAction(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: 'Mute',
                      isActive: _isMuted,
                      onTap: () => setState(() => _isMuted = !_isMuted),
                    ),
                    _buildCallAction(
                      icon: Icons.grid_view_rounded,
                      label: 'Keypad',
                      onTap: _toggleKeypad,
                    ),
                    _buildCallAction(
                      icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                      label: 'Speaker',
                      isActive: _isSpeaker,
                      onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCallAction(
                      icon: Icons.add_call,
                      label: 'Add call',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Adding call...'), behavior: SnackBarBehavior.floating),
                        );
                      },
                    ),
                    _buildCallAction(
                      icon: _isOnHold ? Icons.play_arrow : Icons.pause,
                      label: _isOnHold ? 'Resume' : 'Hold',
                      isActive: _isOnHold,
                      onTap: () => setState(() => _isOnHold = !_isOnHold),
                    ),
                    _buildCallAction(
                      icon: _isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
                      label: _isRecording ? 'Stop' : 'Record',
                      isActive: _isRecording,
                      activeColor: Colors.red,
                      onTap: () {
                        setState(() => _isRecording = !_isRecording);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isRecording ? 'Recording started' : 'Recording stopped'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInCallKeypad() {
    return Padding(
      key: const ValueKey('keypad'),
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 6,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            physics: const NeverScrollableScrollPhysics(),
            children: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#']
                .map((d) => _buildDTMFButton(d))
                .toList(),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _toggleKeypad,
            child: const Text('Hide Keypad', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDTMFButton(String digit) {
    return GestureDetector(
      onTap: () => _addDTMF(digit),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Center(
              child: Text(
                digit,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingCallButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Reject button
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: GestureDetector(
            onTap: _endCall,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withAlpha(120),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.call_end, color: Colors.white, size: 34),
            ),
          ),
        ),
        // Answer button
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: GestureDetector(
            onTap: _answerCall,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withAlpha((80 + _pulseController.value * 60).toInt()),
                        blurRadius: 30 + _pulseController.value * 20,
                        spreadRadius: 8 + _pulseController.value * 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.call, color: Colors.white, size: 34),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallAction({
    required IconData icon,
    required String label,
    bool isActive = false,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = isActive ? (activeColor ?? Colors.white) : Colors.white;
    
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive 
                  ? (activeColor ?? Colors.white) 
                  : Colors.white.withAlpha(12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : color,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

class DynamicWavePainter extends CustomPainter {
  final double animationValue;
  final int waveIndex;
  final Color baseColor;

  DynamicWavePainter({
    required this.animationValue,
    required this.waveIndex,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor.withAlpha(20 - (waveIndex * 4))
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 20.0 + (waveIndex * 15);
    final offset = animationValue * 2 * math.pi + (waveIndex * 0.8);
    final yBase = size.height * (0.6 + waveIndex * 0.1);

    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2) {
      final frequency = 1.5 + waveIndex * 0.3;
      final y = yBase + 
                math.sin((x / size.width * frequency * math.pi) + offset) * waveHeight +
                math.cos((x / size.width * frequency * 0.5 * math.pi) + offset * 1.5) * waveHeight * 0.5;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DynamicWavePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
