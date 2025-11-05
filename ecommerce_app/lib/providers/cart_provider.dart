import 'package:flutter/foundation.dart';

// Model for each item sa cart
class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });
}

// CartProvider = utak ng cart system
class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items); // prevent direct modification

  int get itemCount {
    int total = 0;
    for (var item in _items) {
      total += item.quantity;
    }
    return total;
  }

  double get totalPrice {
    double total = 0.0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  void addItem(String id, String name, double price, String imageUrl) {
    final index = _items.indexWhere((item) => item.id == id);

    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(
        id: id,
        name: name,
        price: price,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/150', // default image
      ));
    }

    notifyListeners(); // refresh lahat ng listening widgets
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void decrementItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
