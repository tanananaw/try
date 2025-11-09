import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  bool _isExiting = false; // 👈 new state for the back animation

  @override
  void initState() {
    super.initState();

    // Show intro animation for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // 👇 Intercept the back button press
  Future<bool> _onWillPop() async {
    setState(() {
      _isExiting = true;
    });

    // Wait for 2 seconds before navigating back
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop(); // Go back to Home
    }

    return false; // Prevent default pop (we handle it manually)
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to see your notifications.'),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop, // 👈 attach the handler
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          automaticallyImplyLeading: !_isExiting, // hide back button during exit
        ),
        body: Stack(
          children: [
            // 👇 Main content (uses same fade animation from before)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _isLoading
                  ? Center(
                key: const ValueKey('loading'),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blueAccent),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "This is the notifications",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              )
                  : StreamBuilder<QuerySnapshot>(
                key: const ValueKey('content'),
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: user.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('You have no notifications.'));
                  }

                  final notifications = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index]
                          .data() as Map<String, dynamic>;
                      final docId = notifications[index].id;

                      final title =
                          notification['title'] ?? 'No title';
                      final body = notification['body'] ?? '';
                      final isRead = notification['isRead'] ?? false;

                      return ListTile(
                        leading: Icon(
                          isRead
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                          color:
                          isRead ? Colors.grey : Colors.blue,
                        ),
                        title: Text(title),
                        subtitle: Text('$body\nID: $docId'),
                        trailing: Text(
                          '${index + 1}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                        onTap: () {
                          notifications[index]
                              .reference
                              .update({'isRead': true});
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // 👇 Overlay when user presses "back"
            if (_isExiting)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 5,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Going to Home Screen, Please wait...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
