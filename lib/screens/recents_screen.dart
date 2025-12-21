import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'call_screen.dart';
import 'contact_detail_screen.dart';
import '../widgets/swipe_action_widget.dart';

class RecentsScreen extends StatelessWidget {
  const RecentsScreen({super.key});

  Future<void> _sendMessage(BuildContext context, String number) async {
    final Uri smsUri = Uri.parse('sms:$number');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final List<Map<String, dynamic>> recents = [
      {'name': 'John Doe', 'number': '123456789', 'time': '10:30 AM', 'status': 'incoming', 'color': Colors.blue, 'duration': '2:45'},
      {'name': 'Alice Smith', 'number': '987654321', 'time': 'Yesterday', 'status': 'outgoing', 'color': Colors.purple, 'duration': '5:12'},
      {'name': '+1 234 567 890', 'number': '+1 234 567 890', 'time': 'Yesterday', 'status': 'missed', 'color': Colors.orange, 'duration': null},
      {'name': 'Mom', 'number': '555123456', 'time': 'Dec 19', 'status': 'incoming', 'color': Colors.pink, 'duration': '15:32'},
      {'name': 'Pizza Hut', 'number': '444987654', 'time': 'Dec 18', 'status': 'outgoing', 'color': Colors.red, 'duration': '1:05'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: recents.length,
      itemBuilder: (context, index) {
        final item = recents[index];
        final isMissed = item['status'] == 'missed';
        final name = item['name'] as String;
        final number = item['number'] as String;
        final color = item['color'] as Color;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 200 + (index * 60)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 15 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SwipeActionWidget(
              onCall: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => CallScreen(
                      name: name,
                      number: number,
                      contactColor: color,
                    ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                        child: child,
                      );
                    },
                  ),
                );
              },
              onMessage: () => _sendMessage(context, number),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [Colors.black.withAlpha(200), Colors.black.withAlpha(150)]
                            : [Colors.white.withAlpha(245), Colors.white.withAlpha(230)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(10),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withAlpha(35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withAlpha(60)),
                        ),
                        child: Center(
                          child: Text(
                            name[0].toUpperCase(),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(fontWeight: FontWeight.w600, color: isMissed ? Colors.red : null),
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: (isMissed ? Colors.red : Colors.grey).withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              item['status'] == 'incoming' ? Icons.call_received : 
                              item['status'] == 'outgoing' ? Icons.call_made : Icons.call_missed,
                              size: 12,
                              color: isMissed ? Colors.red : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item['time']}',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                          ),
                          if (item['duration'] != null) ...[
                            Text(' • ', style: TextStyle(color: isDark ? Colors.white38 : Colors.black26)),
                            Text(
                              item['duration'],
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.info_outline, size: 22),
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => ContactDetailScreen(
                                    name: name,
                                    number: number,
                                    avatarColor: color,
                                  ),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => CallScreen(
                              name: name,
                              number: number,
                              contactColor: color,
                            ),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
