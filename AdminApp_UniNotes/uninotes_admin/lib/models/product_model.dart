import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductModel with ChangeNotifier {
  final String productId;
  final String productTitle;
  final String productPrice;
  final String productCategory;
  final String productDescription;
  final String productImage;
  final String productQuantity;
  final String pdfUrl;
  final String pdfFileName;
  final bool isFree;
  Timestamp? createdAt;

  ProductModel({
    required this.productId,
    required this.productTitle,
    required this.productPrice,
    required this.productCategory,
    required this.productDescription,
    required this.productImage,
    required this.productQuantity,
    this.pdfUrl = '',
    this.pdfFileName = '',
    this.isFree = false,
    this.createdAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      productId: data['productId'],
      productTitle: data['productTitle'],
      productPrice: data['productPrice'],
      productCategory: data['productCategory'],
      productDescription: data['productDescription'],
      productImage: data['productImage'],
      productQuantity: data['productQuantity'],
      pdfUrl: (data['pdfUrl'] ?? '').toString(),
      pdfFileName: (data['pdfFileName'] ?? '').toString(),
      isFree: data['isFree'] == true,
      createdAt: data['createdAt'],
    );
  }
}
