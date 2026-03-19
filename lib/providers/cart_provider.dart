import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:notes_hub/models/cart_model.dart';
import 'package:notes_hub/providers/products_provider.dart';
import 'package:notes_hub/services/my_app_functions.dart';
import 'package:uuid/uuid.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartModel> _cartItems = {};
  Map<String, CartModel> get getCartitems {
    return _cartItems;
  }

  final userstDb = FirebaseFirestore.instance.collection("users");
  final _auth = FirebaseAuth.instance;
// Firebase
  Future<void> addToCartFirebase({
    required String productId,
    required int qty,
    required BuildContext context,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: "Please login first",
        fct: () {},
      );
      return;
    }
    final uid = user.uid;
    final cartId = const Uuid().v4();
    try {
      final userDoc = await userstDb.doc(uid).get();
      final data = userDoc.data();
      final userCart = data?['userCart'] as List<dynamic>? ?? [];
      final alreadyInCart = userCart.any((item) {
        return item is Map<String, dynamic> && item['productId'] == productId;
      });

      if (alreadyInCart) {
        await fetchCart();
        Fluttertoast.showToast(msg: "Item is already in cart");
        return;
      }

      await userstDb.doc(uid).update({
        'userCart': FieldValue.arrayUnion([
          {
            'cartId': cartId,
            'productId': productId,
            'quantity': qty,
          }
        ])
      });
      await fetchCart();
      Fluttertoast.showToast(msg: "Item has been added");
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeCartItemFromFirestore({
    required String cartId,
    required String productId,
    required int qty,
  }) async {
    final User? user = _auth.currentUser;
    try {
      await userstDb.doc(user!.uid).update({
        'userCart': FieldValue.arrayRemove([
          {
            'cartId': cartId,
            'productId': productId,
            'quantity': qty,
          }
        ])
      });
      _cartItems.remove(productId);
      Fluttertoast.showToast(msg: "Item has been removed");
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCartFromFirebase() async {
    final User? user = _auth.currentUser;
    try {
      await userstDb.doc(user!.uid).update({
        'userCart': [],
      });
      _cartItems.clear();
      Fluttertoast.showToast(msg: "Cart has been cleared");
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchCart() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      _cartItems.clear();
      notifyListeners();
      return;
    }
    try {
      _cartItems.clear();
      final userDoc = await userstDb.doc(user.uid).get();
      final data = userDoc.data();
      if (data == null || !data.containsKey('userCart')) {
        notifyListeners();
        return;
      }
      final leng = userDoc.get("userCart").length;
      for (int index = 0; index < leng; index++) {
        _cartItems.putIfAbsent(
          userDoc.get("userCart")[index]['productId'],
          () => CartModel(
              cartId: userDoc.get("userCart")[index]['cartId'],
              productId: userDoc.get("userCart")[index]['productId'],
              quantity: userDoc.get("userCart")[index]['quantity']),
        );
      }
    } catch (e) {
      rethrow;
    }
    notifyListeners();
  }

//Local

  void addProductToCart({required String productId}) {
    _cartItems.putIfAbsent(
      productId,
      () => CartModel(
          cartId: const Uuid().v4(), productId: productId, quantity: 1),
    );
    notifyListeners();
  }

  bool isProdinCart({required String productId}) {
    return _cartItems.containsKey(productId);
  }

  static double parsePriceValue(String rawPrice) {
    final normalized = rawPrice
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0.0;
  }

  double getTotal({required ProductsProvider productsProvider}) {
    double total = 0.0;

    _cartItems.forEach((key, value) {
      final getCurrProduct = productsProvider.findByProductId(value.productId);
      if (getCurrProduct == null) {
        total += 0;
      } else {
        total += parsePriceValue(getCurrProduct.productPrice) * value.quantity;
      }
    });
    return total;
  }

  int getQty() {
    int total = 0;
    _cartItems.forEach((key, value) {
      total += value.quantity;
    });
    return total;
  }

  void updateQty({required String productId, required int qty}) {
    _cartItems.update(
      productId,
      (cartItem) => CartModel(
          cartId: cartItem.cartId, productId: productId, quantity: qty),
    );
    notifyListeners();
  }

  void clearLocalCart() {
    _cartItems.clear();
    notifyListeners();
  }

  void removeOneItem({required String productId}) {
    _cartItems.remove(productId);
    notifyListeners();
  }
}
