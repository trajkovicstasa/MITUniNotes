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
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return ProductModel(
      productId: (data["productId"] ?? doc.id).toString(),
      productTitle: (data['productTitle'] ?? '').toString(),
      productPrice: (data['productPrice'] ?? '0').toString(),
      productCategory: (data['productCategory'] ?? '').toString(),
      productDescription: (data['productDescription'] ?? '').toString(),
      productImage: (data['productImage'] ?? '').toString(),
      productQuantity: (data['productQuantity'] ?? '0').toString(),
      pdfUrl: (data['pdfUrl'] ?? '').toString(),
      pdfFileName: (data['pdfFileName'] ?? '').toString(),
      isFree: data['isFree'] == true,
      status: (data['status'] ?? 'approved').toString(),
      rejectionReason: (data['rejectionReason'] ?? '').toString(),
      authorId: (data['authorId'] ?? '').toString(),
      authorName: (data['authorName'] ?? '').toString(),
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : null,
    );
  }
}
