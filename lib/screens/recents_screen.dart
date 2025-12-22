import 'package:flutter/material.dart';
import 'dart:ui';
import 'call_screen.dart';
import 'contact_detail_screen.dart';
import '../widgets/swipe_action_widget.dart';
import '../services/data_cache.dart';
import '../services/phone_utils.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCallLogs();
  }

  Future<void> _loadCallLogs() async {
    // Use cached data
    if (dataCache.callLogsLoaded) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    await dataCache.loadCallLogs();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refreshCallLogs() async {
    setState(() => _isLoading = true);
    await dataCache.refreshCallLogs();
    if (mounted) setState(() => _isLoading = false);
  }

  void _makeCall(String name, String number, Color color) async {
    final cleanNumber = PhoneUtils.cleanPhoneNumber(number);
    await PhoneUtils.makeCall(cleanNumber);
    
    if (!mounted) return;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CallScreen(
          name: name,
          number: cleanNumber,
          contactColor: color,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedLogs = dataCache.groupedCallLogs;
    
    if (groupedLogs.isEmpty) {
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshCallLogs,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final dateKeys = groupedLogs.keys.toList();

    return RefreshIndicator(
      onRefresh: _refreshCallLogs,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: dateKeys.length,
        itemBuilder: (context, dateIndex) {
          final dateKey = dateKeys[dateIndex];
          final logs = groupedLogs[dateKey]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Call logs for this date
              ...logs.map((item) => _buildCallItem(context, item, isDark)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCallItem(BuildContext context, Map<String, dynamic> item, bool isDark) {
    final isMissed = item['status'] == 'missed';
    final name = item['name'] as String;
    final number = item['number'] as String;
    final color = item['color'] as Color;
    final time = item['time'] as String;
    final duration = item['duration'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwipeActionWidget(
        onCall: () => _makeCall(name, number, color),
        onMessage: () => PhoneUtils.sendSms(number),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [Colors.black.withAlpha(180), Colors.black.withAlpha(140)]
                      : [Colors.white.withAlpha(240), Colors.white.withAlpha(220)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(8),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withAlpha(180),
                        color,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isMissed ? Colors.red.shade400 : null,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    Icon(
                      item['status'] == 'outgoing'
                          ? Icons.call_made
                          : item['status'] == 'missed'
                              ? Icons.call_missed
                              : Icons.call_received,
                      size: 14,
                      color: isMissed ? Colors.red.shade400 : (isDark ? Colors.white54 : Colors.black45),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    if (duration != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        duration,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.call,
                    color: Colors.green.shade400,
                    size: 22,
                  ),
                  onPressed: () => _makeCall(name, number, color),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => ContactDetailScreen(
                        name: name,
                        number: number,
                        avatarColor: color,
                      ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 100),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
