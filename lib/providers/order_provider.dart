import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final List<OrdersModel> orders = [];
  List<OrdersModel> get getOrders => orders;

  Future<List<OrdersModel>> fetchOrder() async {
    final auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) {
      orders.clear();
      notifyListeners();
      return orders;
    }
    var uid = user.uid;
    try {
      await FirebaseFirestore.instance
          .collection("orders")
          .where('userId', isEqualTo: uid)
          .get()
          .then((orderSnapshot) {
        orders.clear();
        for (var element in orderSnapshot.docs) {
          final data = element.data();
          orders.insert(
            0,
            OrdersModel(
              orderId: (data['orderId'] ?? element.id).toString(),
              productId: (data['productId'] ?? '').toString(),
              userId: (data['userId'] ?? '').toString(),
              price: (data['price'] ?? '0').toString(),
              productTitle: (data['productTitle'] ?? '').toString(),
              quantity: (data['quantity'] ?? '0').toString(),
              imageUrl: (data['imageUrl'] ?? '').toString(),
              userName: (data['userName'] ?? '').toString(),
              orderDate: data['orderDate'] is Timestamp
                  ? data['orderDate'] as Timestamp
                  : Timestamp.now(),
            ),
          );
        }
        orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      });
      return orders;
    } catch (e) {
      rethrow;
    }
  }
}
