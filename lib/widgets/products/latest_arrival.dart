import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/models/product_model.dart';
import 'package:notes_hub/providers/cart_provider.dart';
import 'package:notes_hub/providers/viewed_recently_provider.dart';
import 'package:notes_hub/screens/inner_screen/product_details.dart';
import 'package:notes_hub/widgets/products/heart_btn.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:provider/provider.dart';

class LatestArrivalProductsWidget extends StatelessWidget {
  const LatestArrivalProductsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final productModel = Provider.of<ProductModel>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final viewedProdProvider = Provider.of<ViewedProdProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () async {
           viewedProdProvider.addOrRemoveFromViewedProd(
            productId: productModel.productId,
          );
          Navigator.pushNamed(context, ProductDetailsScreen.routName,
              arguments: productModel.productId);
        },
        child: SizedBox(
          width: size.width * 0.45,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: FancyShimmerImage(
                    imageUrl: productModel.productImage,
                    height: size.width * 0.24,
                    width: size.width * 0.32,
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Flexible(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      productModel.productTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    FittedBox(
                      child: Row(
                        children: [
                           HeartButtonWidget(
                            productId: productModel.productId,
                          ),
                          IconButton(
                           onPressed: () {
                              if (cartProvider.isProdinCart(
                                  productId: productModel.productId)) {
                                return;
                              }
                              cartProvider.addProductToCart(
                                productId: productModel.productId,
                              );
                            },
                            icon: Icon(
                              cartProvider.isProdinCart(
                                      productId: productModel.productId)
                                  ? Icons.check
                                  : Icons.add_shopping_cart_outlined,
                              size: 20,
                              color: AppColors.darkPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                     FittedBox(
                      child: SubtitleTextWidget(
                        label: "${productModel.productPrice} RSD",
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}