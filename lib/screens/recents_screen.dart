import 'package:flutter/material.dart';
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

    final groupedLogs = dataCache.groupedByContactAndDate;
    
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
          final contactGroups = groupedLogs[dateKey]!;
          final contactKeys = contactGroups.keys.toList();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              ...contactKeys.map((contactKey) {
                final logs = contactGroups[contactKey]!;
                return _buildContactGroup(context, contactKey, logs, isDark);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContactGroup(BuildContext context, String contactName, List<Map<String, dynamic>> logs, bool isDark) {
    if (logs.isEmpty) return const SizedBox.shrink();
    
    final latestLog = logs.first;
    final color = latestLog['color'] as Color;
    final number = latestLog['number'] as String;
    final isGrouped = logs.length > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwipeActionWidget(
        onCall: () => _makeCall(contactName, number, color),
        onMessage: () => PhoneUtils.sendSms(number),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                  : [Colors.white, const Color(0xFFF0F0F0)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 50 : 10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isGrouped 
              ? ExpansionTile(
                    shape: const RoundedRectangleBorder(side: BorderSide.none),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: _buildAvatar(contactName, color),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            contactName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: latestLog['status'] == 'missed' ? Colors.red.shade400 : null,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withAlpha(10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${logs.length}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      latestLog['time'],
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    children: logs.map((log) => _buildSubCallItem(context, log, isDark)).toList(),
                  )
                : ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: _buildAvatar(contactName, color),
                    title: Text(
                      contactName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: latestLog['status'] == 'missed' ? Colors.red.shade400 : null,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        _getStatusIcon(latestLog['status']),
                        const SizedBox(width: 4),
                        Text(
                          latestLog['time'],
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary.withAlpha(180),
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => ContactDetailScreen(
                              name: contactName,
                              number: number,
                              avatarColor: color,
                            ),
                            transitionDuration: const Duration(milliseconds: 100),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
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
    );
  }

  Widget _buildAvatar(String name, Color color) {
    return Container(
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
    );
  }

  Widget _buildSubCallItem(BuildContext context, Map<String, dynamic> log, bool isDark) {
    final isMissed = log['status'] == 'missed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 8),
      child: Row(
        children: [
          _getStatusIcon(log['status']),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['time'],
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                if (log['duration'] != null)
                  Text(
                    log['duration'],
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
          if (isMissed)
            Text(
              'Missed',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'missed':
        return const Icon(Icons.call_missed, size: 14, color: Colors.red);
      case 'outgoing':
        return const Icon(Icons.call_made, size: 14, color: Colors.green);
      case 'incoming':
        return const Icon(Icons.call_received, size: 14, color: Colors.blue);
      default:
        return const Icon(Icons.call, size: 14);
    }
  }
}
