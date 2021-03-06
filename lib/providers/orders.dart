import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  String _authToken;
  String _userId;
  // IF USE INSTRUCTOR STYLE, NEED TO USE FINAL STRING ...

  // Orders(this.authToken, this._orders);
  // NEED TO USE CONSTRUCTOR IF USE INSTRUCTOR STYLE NOT UPDATE() METHOD BELOW

  set setAuthToken(String token) {
    _authToken = token;
  }

  set setUserId(String userId) {
    _userId = userId;
  }

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetOrders() async {
    final url =
        'https://flutter-update-e1c0e-default-rtdb.firebaseio.com/orders/$_userId.json?auth=$_authToken';
    final response = await http.get(url);

    final extractedData = json.decode(response.body) as Map<String, dynamic>;

    print('Orders: $extractedData');

    if (extractedData == null) {
      _orders = [];
      notifyListeners();
      return;
    }

    final List<OrderItem> loadedOrders = [];

    extractedData.forEach((orderId, orderData) {
      loadedOrders.add(OrderItem(
        id: orderId,
        amount: orderData['amount'],
        dateTime: DateTime.parse(orderData['dateTime']),
        products: (orderData['products'] as List<dynamic>)
            .map(
              (item) => CartItem(
                id: item['id'],
                title: item['title'],
                quantity: item['quantity'],
                price: item['price'],
              ),
            )
            .toList(),
      ));
    });
    // to show the newest order at the top of list orders
    _orders = loadedOrders.reversed.toList();
    notifyListeners();
  }

  void addOrder(List<CartItem> cartProducts, double total) async {
    final url =
        'https://flutter-update-e1c0e-default-rtdb.firebaseio.com/orders/$_userId.json?auth=$_authToken';
    final timeStamp = DateTime.now();
    final response = await http.post(
      url,
      body: json.encode({
        'amount': total,
        'dateTime': timeStamp.toIso8601String(),
        'products': cartProducts
            .map(
              (cp) => {
                'id': cp.id,
                'title': cp.title,
                'quantity': cp.quantity,
                'price': cp.price,
              },
            )
            .toList(),
      }),
    );
    _orders.insert(
      0,
      OrderItem(
        id: json.decode(response.body)['name'],
        amount: total,
        dateTime: timeStamp,
        products: cartProducts,
      ),
    );
    notifyListeners();
  }
}
