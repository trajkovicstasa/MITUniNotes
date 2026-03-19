import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uninotes_admin/models/product_model.dart';

class ProductsProvider with ChangeNotifier {
  List<ProductModel> products = [];

  List<ProductModel> get getProducts {
    return products;
  }

  List<ProductModel> searchQuery({
    required String searchText,
    required List<ProductModel> passedList,
  }) {
    final searchList = passedList
        .where((element) => element.productTitle
            .toLowerCase()
            .contains(searchText.toLowerCase()))
        .toList();
    return searchList;
  }

  ProductModel? findByProductId(String productId) {
    if (products.where((element) => element.productId == productId).isEmpty) {
      return null;
    }
    return products.firstWhere((element) => element.productId == productId);
  }

  final productDb = FirebaseFirestore.instance.collection("products");

  Future<List<ProductModel>> fetchProducts() async {
    try {
      await productDb.get().then((productSnapshot) {
        products.clear();
        for (var element in productSnapshot.docs) {
          products.insert(0, ProductModel.fromFirestore(element));
        }
      });
      notifyListeners();
      return products;
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<ProductModel>> fetchProductsStream() {
    try {
      return productDb.snapshots().map((snapshot) {
        products.clear();
        for (var element in snapshot.docs) {
          products.insert(0, ProductModel.fromFirestore(element));
        }
        return products;
      });
    } catch (e) {
      rethrow;
    }
  }
}
