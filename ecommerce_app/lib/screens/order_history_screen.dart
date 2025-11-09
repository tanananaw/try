import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/widgets/order_card.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = true; // for initial animation
  bool _isExiting = false; // for back-to-home animation

  @override
  void initState() {
    super.initState();

    // Initial loading animation for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Handle back press to show "Going to home screen" animation
  Future<bool> _onWillPop() async {
    setState(() {
      _isExiting = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop();
    }

    return false; // prevent default pop
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          automaticallyImplyLeading: !_isExiting,
        ),
        body: Stack(
          children: [
            // Main content with fade + slide animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, animation) {
                final offsetAnimation =
                Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                    .animate(animation);
                return SlideTransition(
                  position: offsetAnimation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _isLoading
                  ? Center(
                key: const ValueKey('loading'),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "This is your orders.",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
                  : user == null
                  ? const Center(
                key: ValueKey('no-user'),
                child: Text('Please log in to see your orders.'),
              )
                  : StreamBuilder<QuerySnapshot>(
                key: const ValueKey('orders'),
                stream: FirebaseFirestore.instance
                    .collection('orders')
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

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                          'You have not placed any orders yet.'),
                    );
                  }

                  final orderDocs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: orderDocs.length,
                    itemBuilder: (context, index) {
                      final orderData = orderDocs[index].data()
                      as Map<String, dynamic>;

                      return OrderCard(orderData: orderData);
                    },
                  );
                },
              ),
            ),

            // Back-to-home animation overlay
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
                        "Going to home screen, please wait...",
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
