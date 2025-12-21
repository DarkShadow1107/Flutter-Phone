import 'package:flutter/material.dart';

class SwipeActionWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final double borderRadius;

  const SwipeActionWidget({
    super.key,
    required this.child,
    required this.onCall,
    required this.onMessage,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onCall();
          } else if (direction == DismissDirection.endToStart) {
            onMessage();
          }
          return false;
        },
        background: Container(
          color: Colors.green.shade600,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Row(
            children: [
              Icon(Icons.call, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text('Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        secondaryBackground: Container(
          color: Colors.blue.shade600,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(width: 12),
              Icon(Icons.message, color: Colors.white, size: 28),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}
