import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import 'call_screen.dart';
import 'edit_contact_screen.dart';
import '../services/whatsapp_service.dart';

class ContactDetailScreen extends StatefulWidget {
  final String name;
  final String number;
  final Color avatarColor;

  const ContactDetailScreen({
    super.key,
    required this.name,
    required this.number,
    required this.avatarColor,
  });

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  late String _name;
  late String _number;
  bool _hasWhatsApp = false;
  bool _isCheckingWhatsApp = true;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _number = widget.number;
    _checkWhatsAppAvailability();
  }

  Future<void> _checkWhatsAppAvailability() async {
    final hasWhatsApp = await whatsAppService.isNumberOnWhatsApp(_number);
    if (mounted) {
      setState(() {
        _hasWhatsApp = hasWhatsApp;
        _isCheckingWhatsApp = false;
      });
    }
  }

  Future<void> _openWhatsAppCall() async {
    final cleanNumber = _number.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri whatsappAppUri = Uri.parse('whatsapp://call?phone=$cleanNumber');
    final Uri whatsappWebUri = Uri.parse('https://wa.me/$cleanNumber');

    try {
      if (await canLaunchUrl(whatsappAppUri)) {
        await launchUrl(whatsappAppUri);
      } else {
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Could not launch WhatsApp'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _openWhatsAppVideo() async {
    final cleanNumber = _number.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri whatsappVideoUri = Uri.parse('whatsapp://videocall?phone=$cleanNumber');
    final Uri whatsappWebUri = Uri.parse('https://wa.me/$cleanNumber?video=true');
    
    try {
      if (await canLaunchUrl(whatsappVideoUri)) {
        await launchUrl(whatsappVideoUri);
      } else {
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Could not launch WhatsApp Video'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _sendSMS() async {
    final Uri smsUri = Uri.parse('sms:$_number');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Could not launch SMS app'), behavior: SnackBarBehavior.floating),
         );
       }
    }
  }

  void _shareContact() async {
    await SharePlus.instance.share(
      ShareParams(
        text: '$_name\nPhone: $_number',
        subject: 'Contact: $_name',
      ),
    );
  }

  void _editContact() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditContactScreen(
          initialName: _name,
          initialNumber: _number,
          isNew: false,
        ),
      ),
    );

    if (result != null) {
      if (result['deleted'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact deleted'), behavior: SnackBarBehavior.floating),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _name = result['name'] ?? _name;
          _number = result['number'] ?? _number;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact saved'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  void _showMoreOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(40),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withAlpha(180)
                  : Colors.white.withAlpha(200),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _buildOptionTile(Icons.share_outlined, 'Share contact', () {
                  Navigator.pop(context);
                  _shareContact();
                }),
                _buildOptionTile(Icons.star_outline, 'Add to favorites', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to favorites'), behavior: SnackBarBehavior.floating),
                  );
                }),
                _buildOptionTile(Icons.copy, 'Copy number', () {
                  Navigator.pop(context);
                }),
                const Divider(),
                _buildOptionTile(Icons.block, 'Block number', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Number blocked'), behavior: SnackBarBehavior.floating),
                  );
                }, isDestructive: true),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : null)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: ClipRRect(
             borderRadius: BorderRadius.circular(12),
             child: BackdropFilter(
               filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
               child: Container(
                 padding: const EdgeInsets.all(8),
                 color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(5),
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
                   color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(5),
                   child: const Icon(Icons.edit, size: 20),
                 ),
              ),
            ),
            onPressed: _editContact
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                 child: Container(
                   padding: const EdgeInsets.all(8),
                   color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(5),
                   child: const Icon(Icons.more_vert, size: 20),
                 ),
              ),
            ),
            onPressed: _showMoreOptions
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
           Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.avatarColor.withAlpha(20), boxShadow: [BoxShadow(color: widget.avatarColor.withAlpha(30), blurRadius: 100, spreadRadius: 20)]))),
           Positioned(bottom: -50, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withAlpha(15), boxShadow: [BoxShadow(color: Colors.blue.withAlpha(20), blurRadius: 100, spreadRadius: 20)]))),
           
           // Blur Overlay
           Positioned.fill(
             child: BackdropFilter(
               filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
               child: Container(color: Colors.transparent),
             ),
           ),

          // Content
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100), // Spacing for extended app bar
                // Avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: widget.avatarColor.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.avatarColor.withAlpha(50), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.avatarColor.withAlpha(40),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _name[0].toUpperCase(),
                      style: TextStyle(fontSize: 48, color: widget.avatarColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _name,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _number,
                  style: TextStyle(fontSize: 18, color: isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(height: 48),

                // Main Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(150),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: Icons.call,
                              label: 'Call',
                              color: Colors.green,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CallScreen(
                                      name: _name,
                                      number: _number,
                                      contactColor: widget.avatarColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.message,
                              label: 'Message',
                              color: Colors.blue,
                              onTap: _sendSMS,
                            ),
                            if (_hasWhatsApp) ...[
                              _buildActionButton(
                                icon: Icons.videocam,
                                label: 'Video',
                                color: Colors.teal,
                                onTap: _openWhatsAppVideo,
                              ),
                              _buildActionButton(
                                 icon: Icons.call,
                                 label: 'WA Call',
                                 color: Colors.green.shade700,
                                 onTap: _openWhatsAppCall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Info Sections
                _buildInfoSection('Mobile', _number, Icons.phone_android),
                _buildInfoSection('Email', 'email@example.com', Icons.email_outlined),
                if (_hasWhatsApp)
                  _buildInfoSection('WhatsApp', 'Chat with $_name', Icons.chat_bubble_outline, onTap: () async {
                    final Uri url = Uri.parse('https://wa.me/${_number.replaceAll(RegExp(r'[^0-9]'), '')}');
                    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                  }),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(50)),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(30),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String label, String value, IconData icon, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
             child: Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: isDark ? Colors.white.withAlpha(8) : Colors.white.withAlpha(150),
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(
                   color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                 ),
               ),
               child: Row(
                 children: [
                   Icon(icon, color: Theme.of(context).colorScheme.primary.withAlpha(180), size: 24),
                   const SizedBox(width: 20),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         label,
                         style: TextStyle(
                           fontSize: 12,
                           color: isDark ? Colors.white54 : Colors.black45,
                         ),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         value,
                         style: const TextStyle(
                           fontSize: 16,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ],
                   ),
                 ],
               ),
             ),
          ),
        ),
      ),
    );
  }
}
