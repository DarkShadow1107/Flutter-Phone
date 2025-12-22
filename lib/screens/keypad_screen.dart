import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'call_screen.dart';
import '../services/phone_utils.dart';

class KeypadScreen extends StatefulWidget {
  final Function(String) onCall;
  
  const KeypadScreen({super.key, required this.onCall});

  @override
  State<KeypadScreen> createState() => _KeypadScreenState();
}

class _KeypadScreenState extends State<KeypadScreen> with SingleTickerProviderStateMixin {
  String _phoneNumber = '';
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDigitPress(String digit) {
    if (_phoneNumber.length < 15) {
      setState(() {
        _phoneNumber += digit;
      });
    }
  }

  void _onBackspace() {
    if (_phoneNumber.isNotEmpty) {
      setState(() {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      });
    }
  }

  void _makeCall() async {
    if (_phoneNumber.isNotEmpty) {
      final cleanNumber = PhoneUtils.cleanPhoneNumber(_phoneNumber);
      
      // First try to place actual call via native
      await PhoneUtils.makeCall(cleanNumber);
      
      // Then show our call UI
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => CallScreen(
              name: _phoneNumber,
              number: cleanNumber,
              contactColor: Colors.blue,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_phoneNumber.isNotEmpty) {
      await PhoneUtils.sendSms(_phoneNumber);
    }
  }

  Future<void> _copyNumber() async {
    if (_phoneNumber.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _phoneNumber));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Number copied to clipboard'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _pasteNumber() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      // Basic sanitization: keep only digits, +, *, #
      final cleanNumber = data.text!.replaceAll(RegExp(r'[^0-9+*#]'), '');
      if (cleanNumber.isNotEmpty) {
        setState(() {
          // Limit to a reasonable length for a dialer
          _phoneNumber = cleanNumber.length > 15 
              ? cleanNumber.substring(0, 15) 
              : cleanNumber;
        });
      }
    }
  }

  void _showContextMenu(Offset globalPosition) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        if (_phoneNumber.isNotEmpty)
          const PopupMenuItem(
            value: 'copy',
            child: Row(
              children: [
                Icon(Icons.copy, size: 20),
                SizedBox(width: 12),
                Text('Copy'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'paste',
          child: Row(
            children: [
              Icon(Icons.paste, size: 20),
              SizedBox(width: 12),
              Text('Paste'),
            ],
          ),
        ),
      ],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ).then((value) {
      if (value == 'copy') _copyNumber();
      if (value == 'paste') _pasteNumber();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        Column(
          children: [
            // Phone Number Display
            Expanded(
              flex: 2,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onLongPressStart: (details) => _showContextMenu(details.globalPosition),
                    onSecondaryTapDown: (details) => _showContextMenu(details.globalPosition),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [Colors.white.withAlpha(12), Colors.white.withAlpha(6)]
                                : [Colors.white.withAlpha(200), Colors.white.withAlpha(150)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 30 : 10),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(scale: animation, child: child),
                                );
                              },
                              child: Text(
                                _phoneNumber.isEmpty ? 'Enter number' : _formatPhoneNumber(_phoneNumber),
                                key: ValueKey(_phoneNumber),
                                style: TextStyle(
                                  fontSize: _phoneNumber.isEmpty ? 18 : 32,
                                  fontWeight: _phoneNumber.isEmpty ? FontWeight.w400 : FontWeight.w300,
                                  letterSpacing: _phoneNumber.isEmpty ? 0 : 2,
                                  color: _phoneNumber.isEmpty 
                                      ? (isDark ? Colors.white38 : Colors.black38)
                                      : (isDark ? Colors.white : Colors.black),
                                ),
                              ),
                            ),
                            if (_phoneNumber.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildQuickAction(
                                      icon: Icons.person_add_outlined,
                                      label: 'Add contact',
                                      onTap: () {},
                                    ),
                                    const SizedBox(width: 24),
                                    _buildQuickAction(
                                      icon: Icons.message_outlined,
                                      label: 'Message',
                                      onTap: _sendMessage,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16), // Added spacing for better layout consistency

            // Keypad Grid
            Expanded(
              flex: 5,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1.1,
                    children: [
                      _buildKey('1', '', speedDial: 'Voicemail'),
                      _buildKey('2', 'ABC'),
                      _buildKey('3', 'DEF'),
                      _buildKey('4', 'GHI'),
                      _buildKey('5', 'JKL'),
                      _buildKey('6', 'MNO'),
                      _buildKey('7', 'PQRS'),
                      _buildKey('8', 'TUV'),
                      _buildKey('9', 'WXYZ'),
                      _buildKey('*', ''),
                      _buildKey('0', '+', isLongPressPlus: true),
                      _buildKey('#', ''),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom spacer
            const SizedBox(height: 130),
          ],
        ),

        // Control Row: Call Button and Backspace
        Positioned(
          left: 0,
          right: 0,
          bottom: 110, // Moved higher as requested
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40), // Matching Keypad Grid padding
            child: Row(
              children: [
                // Empty Left Slot (matching Column 1)
                const Expanded(
                  child: SizedBox(),
                ),
                
                // Middle Slot: Call Button (matching Column 2)
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _makeCall,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glassy Glow
                          Container(
                            width: 80, 
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _phoneNumber.isEmpty ? Colors.green.withAlpha(150) : Colors.green.withAlpha(200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withAlpha(80),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          // Icon
                          const Icon(Icons.call, color: Colors.white, size: 36),
                          // Ripple
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _makeCall,
                                highlightColor: Colors.white.withAlpha(50),
                                splashColor: Colors.white.withAlpha(100),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Right Slot: Backspace (matching Column 3)
                Expanded(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _phoneNumber.isNotEmpty ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: _onBackspace,
                        onLongPress: () {
                          setState(() => _phoneNumber = '');
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isDark 
                                  ? Colors.white.withAlpha(15) 
                                  : Colors.black.withAlpha(5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                                ),
                              ),
                              child: Icon(
                                Icons.backspace_rounded, 
                                size: 24,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatPhoneNumber(String number) {
    if (number.length <= 3) return number;
    if (number.length <= 6) return '${number.substring(0, 3)} ${number.substring(3)}';
    if (number.length <= 10) return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
    return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6, 10)} ${number.substring(10)}';
  }

  Widget _buildQuickAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String number, String letters, {String? speedDial, bool isLongPressPlus = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (number.codeUnitAt(0) * 10 % 200)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Stack(
        children: [
          // Glass Background
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Colors.white.withAlpha(15), Colors.white.withAlpha(8)]
                        : [Colors.white.withAlpha(220), Colors.white.withAlpha(180)],
                  ),
                  border: Border.all(
                    color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 20 : 8),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        number,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (letters.isNotEmpty)
                        Text(
                          letters,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Splash Ripple on top with circular clipper
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _onDigitPress(number),
                onLongPress: isLongPressPlus 
                    ? () => _onDigitPress('+') 
                    : speedDial != null 
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling $speedDial...'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        : null,
                splashColor: Theme.of(context).colorScheme.primary.withAlpha(50),
                highlightColor: Theme.of(context).colorScheme.primary.withAlpha(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
