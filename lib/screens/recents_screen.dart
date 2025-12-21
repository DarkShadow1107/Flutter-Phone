import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:call_log/call_log.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'call_screen.dart';
import 'contact_detail_screen.dart';
import '../widgets/swipe_action_widget.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
  List<Map<String, dynamic>> _callLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCallLogs();
  }

  Future<void> _loadCallLogs() async {
    try {
      // Check permission first
      final status = await Permission.phone.status;
      if (!status.isGranted) {
        final result = await Permission.phone.request();
        if (!result.isGranted) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      final Iterable<CallLogEntry> entries = await CallLog.get();
      final List<Map<String, dynamic>> logs = [];

      for (var entry in entries.take(50)) { // Limit to 50 for performance
        final String name = entry.name ?? entry.number ?? 'Unknown';
        final String number = entry.number ?? '';
        final DateTime date = DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0);
        final String timeStr = _formatDate(date);
        
        String status = 'incoming';
        if (entry.callType == CallType.outgoing) status = 'outgoing';
        if (entry.callType == CallType.missed) status = 'missed';
        if (entry.callType == CallType.rejected) status = 'missed';

        logs.add({
          'name': name,
          'number': number,
          'time': timeStr,
          'status': status,
          'color': Colors.primaries[logs.length % Colors.primaries.length],
          'duration': entry.duration != null ? _formatDuration(entry.duration!) : null,
        });
      }

      if (mounted) {
        setState(() {
          _callLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading call logs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDay = DateTime(date.year, date.month, date.day);

    if (logDay == today) {
      return DateFormat.jm().format(date);
    } else if (logDay == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.MMMd().format(date);
    }
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0s';
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${remainingSeconds}s';
  }

  Future<void> _sendMessage(BuildContext context, String number) async {
    final Uri smsUri = Uri.parse('sms:$number');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_callLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 64, color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 16),
            Text(
              'No recent calls',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _callLogs.length,
      itemBuilder: (context, index) {
        final item = _callLogs[index];
        final isMissed = item['status'] == 'missed';
        final name = item['name'] as String;
        final number = item['number'] as String;
        final color = item['color'] as Color;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 150 + (index * 30)),
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
