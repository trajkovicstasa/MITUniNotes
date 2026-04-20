import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductModel with ChangeNotifier {
  final String productId,
      productTitle,
      productPrice,
      productCategory,
      productDescription,
      productImage,
      productQuantity,
      pdfUrl,
      pdfFileName,
      status,
      rejectionReason,
      authorId,
      authorName;
  final bool isFree;
  Timestamp? createdAt;
  ProductModel(
      {required this.productId,
      required this.productTitle,
      required this.productPrice,
      required this.productCategory,
      required this.productDescription,
      required this.productImage,
      required this.productQuantity,
      this.pdfUrl = '',
      this.pdfFileName = '',
      this.isFree = false,
      this.status = 'approved',
      this.rejectionReason = '',
      this.authorId = '',
      this.authorName = '',
      this.createdAt});

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    // data.containsKey("")
    return ProductModel(
      productId: data["productId"], //doc.get(field),
      productTitle: data['productTitle'],
      productPrice: data['productPrice'],
      productCategory: data['productCategory'],
      productDescription: data['productDescription'],
      productImage: data['productImage'],
      productQuantity: data['productQuantity'],
      pdfUrl: (data['pdfUrl'] ?? '').toString(),
      pdfFileName: (data['pdfFileName'] ?? '').toString(),
      isFree: data['isFree'] == true,
      status: (data['status'] ?? 'approved').toString(),
      rejectionReason: (data['rejectionReason'] ?? '').toString(),
      authorId: (data['authorId'] ?? '').toString(),
      authorName: (data['authorName'] ?? '').toString(),
      createdAt: data['createdAt'],
    );
  }
}
