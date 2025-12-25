import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:permission_handler/permission_handler.dart';
import 'call_screen.dart';
import 'contact_detail_screen.dart';
import 'edit_contact_screen.dart';
import '../widgets/swipe_action_widget.dart';
import '../services/phone_utils.dart';
import '../services/data_cache.dart';

class ContactsScreen extends StatefulWidget {
  final Function(String)? onCall;
  
  const ContactsScreen({super.key, this.onCall});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, dynamic>> contacts = [];
  bool _isLoading = true;
  bool _permissionDenied = false;
  bool _hasError = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    // Use cached data
    if (dataCache.contactsLoaded) {
      if (mounted) {
        setState(() {
          contacts = dataCache.contacts;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final status = await Permission.contacts.status;
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _permissionDenied = true;
          });
        }
        return;
      }

      final loadedContacts = await dataCache.loadContacts();
      
      if (mounted) {
        setState(() {
          contacts = loadedContacts;
          _isLoading = false;
          _permissionDenied = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  List<Map<String, dynamic>> get filteredContacts {
    var list = contacts;
    if (_searchQuery.isNotEmpty) {
      list = list.where((c) {
        final name = (c['name'] as String).toLowerCase();
        final number = c['number'] as String;
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || number.contains(query);
      }).toList();
    }
    list.sort((a, b) {
      if (a['favorite'] == true && b['favorite'] != true) return -1;
      if (b['favorite'] == true && a['favorite'] != true) return 1;
      return (a['name'] as String).compareTo(b['name'] as String);
    });
    return list;
  }

  Future<void> _sendMessage(String number) async {
    await PhoneUtils.sendSms(number);
  }

  void _addNewContact() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const EditContactScreen(isNew: true),
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

    if (result != null && result['name'] != null) {
      setState(() {
        contacts.add({
          'name': result['name'],
          'number': result['number'],
          'color': Colors.primaries[contacts.length % Colors.primaries.length],
          'favorite': false,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favorites = filteredContacts.where((c) => c['favorite'] == true).toList();
    final otherContacts = filteredContacts.where((c) => c['favorite'] != true).toList();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [Colors.white.withAlpha(20), Colors.white.withAlpha(10)]
                              : [Colors.white.withAlpha(240), Colors.white.withAlpha(200)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search contacts',
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                          prefixIcon: Icon(Icons.search, size: 22, color: isDark ? Colors.white54 : Colors.black45),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _addNewContact,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(isDark ? 30 : 20),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withAlpha(40),
                        ),
                      ),
                      child: Icon(Icons.person_add, color: Theme.of(context).colorScheme.primary, size: 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _permissionDenied
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contacts_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                          const SizedBox(height: 16),
                          Text(
                            'Contacts permission required',
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please grant access to see your contacts',
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await openAppSettings();
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Open Settings'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _permissionDenied = false;
                              });
                              _loadContacts();
                            },
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  : _hasError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red.withAlpha(120)),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading contacts',
                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                    _hasError = false;
                                  });
                                  _loadContacts();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : filteredContacts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty ? 'No contacts found' : 'No results for "$_searchQuery"',
                                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                                  ),
                                ],
                              ),
                            )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        if (favorites.isNotEmpty && _searchQuery.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 24, top: 8, bottom: 12),
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                                const SizedBox(width: 8),
                                Text('FAVORITES', style: TextStyle(color: Colors.amber.shade600, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                              ],
                            ),
                          ),
                          ...favorites.asMap().entries.map((entry) => _buildContactTile(context, entry.value, entry.key, isFavorite: true)),
                          const SizedBox(height: 16),
                        ],
                        if (otherContacts.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 24, top: 8, bottom: 12),
                            child: Text('ALL CONTACTS', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                          ),
                          ...otherContacts.asMap().entries.map((entry) => _buildContactTile(context, entry.value, entry.key + favorites.length)),
                        ],
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildContactTile(BuildContext context, Map<String, dynamic> contact, int index, {bool isFavorite = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = contact['name'] as String;
    final number = contact['number'] as String;
    final color = contact['color'] as Color;

    void makeCall() async {
      // Actually place the call
      final cleanNumber = PhoneUtils.cleanPhoneNumber(number);
      await PhoneUtils.makeCall(cleanNumber);
      
      if (!mounted) return;
      
      // Show call UI
      Navigator.push(context, PageRouteBuilder(
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
      ));
    }

    // No staggered animation for faster load
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SwipeActionWidget(
        onCall: makeCall,
        onMessage: () => _sendMessage(number),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 50 : 10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: Hero(
                    tag: 'avatar_$name',
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withAlpha(35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withAlpha(60)),
                      ),
                      child: Center(child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20))),
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      if (isFavorite) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.star, size: 16, color: Colors.amber.shade600)),
                    ],
                  ),
                  subtitle: Text(number, style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 13)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: makeCall,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.green.withAlpha(20), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withAlpha(40))),
                          child: const Icon(Icons.call, color: Colors.green, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _sendMessage(number),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blue.withAlpha(20), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withAlpha(40))),
                          child: const Icon(Icons.message, color: Colors.blue, size: 20),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(context, PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => ContactDetailScreen(name: name, number: number, avatarColor: color),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ));
                  },
                ),
              ),
            ),
    );
  }
}
