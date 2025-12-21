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
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.25,
          DismissDirection.endToStart: 0.25,
        },
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onCall();
          } else if (direction == DismissDirection.endToStart) {
            onMessage();
          }
          return false;
        },
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade500],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withAlpha(100),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call, color: Colors.white, size: 26),
              SizedBox(width: 10),
              Text('Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade500, Colors.blue.shade700],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withAlpha(100),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(width: 10),
              Icon(Icons.message, color: Colors.white, size: 26),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}
