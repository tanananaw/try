import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = true;
  bool _isExiting = false; // 👈 controls the "going home" animation

  @override
  void initState() {
    super.initState();

    // Show popup for 2 seconds, then fade into the cart
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // 👇 Intercept the back button to show exit animation
  Future<bool> _onWillPop() async {
    setState(() {
      _isExiting = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop(); // Go back to home
    }

    return false; // prevent default pop (we handle manually)
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return WillPopScope(
      onWillPop: _onWillPop, // 👈 attach our handler here
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Cart'),
          automaticallyImplyLeading: !_isExiting, // hide back button during exit
        ),

        body: Stack(
          children: [
            // 🔹 Main cart content + fade-in intro animation
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
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "This is your items in your cart",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
                  : Column(
                key: const ValueKey('cart'),
                children: [
                  Expanded(
                    child: cart.items.isEmpty
                        ? const Center(
                      child: Text('Your cart is empty.'),
                    )
                        : ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final cartItem = cart.items[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(cartItem.name[0]),
                          ),
                          title: Text(cartItem.name),
                          subtitle:
                          Text('Qty: ${cartItem.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  '₱${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}'),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  cart.removeItem(cartItem.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                '₱${cart.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'VAT (12%):',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                '₱${cart.vat.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const Divider(height: 20, thickness: 1),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₱${cart.totalPriceWithVat.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: cart.items.isEmpty
                          ? null
                          : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              totalAmount: cart.totalPriceWithVat,
                            ),
                          ),
                        );
                      },
                      child: const Text('Proceed to Payment'),
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Exit animation overlay
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
